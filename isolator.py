"""mirgecom driver for the Y0 demonstration.

Note: this example requires a *scaled* version of the Y0
grid. A working grid example is located here:
github.com:/illinois-ceesd/data@y0scaled
"""

__copyright__ = """
Copyright (C) 2020 University of Illinois Board of Trustees
"""

__license__ = """
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""
import logging
import yaml
import numpy as np
import pyopencl as cl
import numpy.linalg as la  # noqa
import pyopencl.array as cla  # noqa
import math


from meshmode.array_context import (
    PyOpenCLArrayContext,
    SingleGridWorkBalancingPytatoArrayContext as PytatoPyOpenCLArrayContext
    #PytatoPyOpenCLArrayContext
)
from mirgecom.profiling import PyOpenCLProfilingArrayContext
#from meshmode.dof_array import thaw
from arraycontext import thaw
from meshmode.mesh import BTAG_ALL, BTAG_NONE  # noqa
from grudge.eager import EagerDGDiscretization
from grudge.shortcuts import make_visualizer
from grudge.dof_desc import DTAG_BOUNDARY
from grudge.op import nodal_max, nodal_min
from logpyle import IntervalTimer, set_dt
from mirgecom.euler import extract_vars_for_logging, units_for_logging
from mirgecom.logging_quantities import (
    initialize_logmgr,
    logmgr_add_many_discretization_quantities,
    logmgr_add_cl_device_info,
    logmgr_set_time,
    LogUserQuantity,
    logmgr_add_device_memory_usage,
    set_sim_state
)

from mirgecom.navierstokes import ns_operator
from mirgecom.artificial_viscosity import av_operator, smoothness_indicator
from mirgecom.simutil import (
    get_sim_timestep,
    check_step,
    generate_and_distribute_mesh,
    write_visfile,
    check_naninf_local,
    check_range_local,
    get_sim_timestep
)
from mirgecom.restart import write_restart_file
from mirgecom.io import make_init_message
from mirgecom.mpi import mpi_entry_point
import pyopencl.tools as cl_tools
from mirgecom.integrators import (rk4_step, lsrk54_step, lsrk144_step,
                                  euler_step)

from mirgecom.fluid import make_conserved
from mirgecom.steppers import advance_state
from mirgecom.boundary import (
    PrescribedInviscidBoundary,
    IsothermalNoSlipBoundary,
    DummyBoundary
)
from mirgecom.initializers import (Uniform, PlanarDiscontinuity)
from mirgecom.eos import IdealSingleGas
from mirgecom.transport import SimpleTransport

logger = logging.getLogger(__name__)


class MyRuntimeError(RuntimeError):
    """Simple exception to kill the simulation."""

    pass


def get_mesh():
    """Get the mesh."""
    from meshmode.mesh.io import read_gmsh
    mesh_filename = "data/isolator.msh"
    mesh = read_gmsh(mesh_filename, force_ambient_dim=2)
    return mesh


def mass_source(discr, q, r, eos, t, rate):
    """Compute the mass source term."""
    from pytools.obj_array import flat_obj_array
    from mirgecom.initializers import _make_pulse

    dim = discr.dim
    zeros = 0 * r[0]
    r0 = np.zeros(dim)
    r0[0] = 0.68
    r0[1] = -0.02
    rho_addition = _make_pulse(rate, r0, 0.001, r)
    gamma = 1.289
    r_gas = 8314.59 / 44.009
    temp_inflow = 297.169
    e = temp_inflow * r_gas / (gamma - 1.0)
    rhoe_addition = rho_addition * e
    return flat_obj_array(rho_addition, rhoe_addition, zeros, zeros)


def sponge(cv, cv_ref, sigma):
    return (sigma*(cv_ref - cv))

def getIsentropicPressure(mach, P0, gamma):
    pressure = (1. + (gamma - 1.)*0.5*math.pow(mach, 2))
    pressure = P0*math.pow(pressure, (-gamma / (gamma - 1.)))
    return pressure

def getIsentropicTemperature(mach, T0, gamma):
    temperature = (1. + (gamma - 1.)*0.5*math.pow(mach, 2))
    temperature = T0*math.pow(temperature, -1.0)
    return temperature

def getMachFromAreaRatio(area_ratio, gamma, mach_guess=0.01):
    error = 1.0e-8
    nextError = 1.0e8
    g = gamma
    M0 = mach_guess
    while nextError > error:
        R = (((2/(g + 1) + ((g - 1)/(g + 1)*M0*M0))**(((g + 1)/(2*g - 2))))/M0
            - area_ratio)
        dRdM = (2*((2/(g + 1) + ((g - 1)/(g + 1)*M0*M0))**(((g + 1)/(2*g - 2))))
               / (2*g - 2)*(g - 1)/(2/(g + 1) + ((g - 1)/(g + 1)*M0*M0)) -
               ((2/(g + 1) + ((g - 1)/(g + 1)*M0*M0))**(((g + 1)/(2*g - 2))))
               * M0**(-2))
        M1 = M0 - R/dRdM
        nextError = abs(R)
        M0 = M1

    return M1

class IsentropicInflow:
    def __init__(self, *, dim=1, direc=0, T0=298, P0=1e5, mach=0.01, p_fun=None):

        self._P0 = P0
        self._T0 = T0
        self._dim = dim
        self._direc = direc
        self._mach = mach
        #if p_fun is not None:
            #self._p_fun = p_fun
        self._p_fun = p_fun

    def __call__(self, x_vec, *, time=0, eos, **kwargs):

        if self._p_fun is not None:
            P0 = self._p_fun(time)
        else:
            P0 = self._P0
        T0 = self._T0

        gamma = eos.gamma()
        gas_const = eos.gas_const()
        pressure = getIsentropicPressure(
            mach=self._mach,
            P0=P0,
            gamma=gamma
        )
        temperature = getIsentropicTemperature(
            mach=self._mach,
            T0=T0,
            gamma=gamma
        )
        rho = pressure/temperature/gas_const

        velocity = np.zeros(self._dim, dtype=object)
        actx = x_vec[0].array_context
        velocity[self._direc] = self._mach*actx.np.sqrt(gamma*pressure/rho)

        mass = 0.0*x_vec[0] + rho
        mom = velocity*mass
        energy = (pressure/(gamma - 1.0)) + actx.np.dot(mom, mom)/(2.0*mass)
        return make_conserved(
            dim=self._dim,
            mass=mass,
            momentum=mom,
            energy=energy
        )

@mpi_entry_point
def main(ctx_factory=cl.create_some_context, restart_filename=None, use_profiling=False,
         use_logmgr=False, user_input_file=None, actx_class=PyOpenCLArrayContext,
         casename=None):
    """Drive the Y0 example."""
    cl_ctx = ctx_factory()

    from mpi4py import MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    nparts = comm.Get_size()

    if casename is None:
        casename = "mirgecom"

    # logging and profiling
    logmgr = initialize_logmgr(use_logmgr,
        filename=f"{casename}.sqlite", mode="wo", mpi_comm=comm)

    if use_profiling:
        queue = cl.CommandQueue(cl_ctx,
            properties=cl.command_queue_properties.PROFILING_ENABLE)
    else:
        queue = cl.CommandQueue(cl_ctx)

    actx = actx_class(
        queue,
        allocator=cl_tools.MemoryPool(cl_tools.ImmediateAllocator(queue)))

    # default i/o junk frequencies
    nviz = 500
    nhealth = 1
    nrestart = 5000
    nstatus = 25

    # default timestepping control
    integrator = "rk4"
    current_dt = 1e-8
    t_final = 1e-7
    current_t = 0
    current_step = 0
    current_cfl = 1.0
    constant_cfl = False

    # default health status bounds
    health_pres_min = 1.0e-1
    health_pres_max = 2.0e6

    # discretization and model control
    order = 1
    #alpha_sc = 0.5
    #s0_sc = -5.0
    kappa_sc = 1.e-5


    if user_input_file:
        input_data = None
        if rank == 0:
            with open(user_input_file) as f:
                input_data = yaml.load(f, Loader=yaml.FullLoader)
        input_data = comm.bcast(input_data, root=0)
        try:
            nviz = int(input_data["nviz"])
        except KeyError:
            pass
        try:
            nrestart = int(input_data["nrestart"])
        except KeyError:
            pass
        try:
            nhealth = int(input_data["nhealth"])
        except KeyError:
            pass
        try:
            nstatus = int(input_data["nstatus"])
        except KeyError:
            pass
        try:
            current_dt = float(input_data["current_dt"])
        except KeyError:
            pass
        try:
            t_final = float(input_data["t_final"])
        except KeyError:
            pass
        try:
            order = int(input_data["order"])
        except KeyError:
            pass
        try:
            integrator = input_data["integrator"]
        except KeyError:
            pass
        try:
            health_pres_min = float(input_data["health_pres_min"])
        except KeyError:
            pass
        try:
            health_pres_max = float(input_data["health_pres_max"])
        except KeyError:
            pass

    # param sanity check
    allowed_integrators = ["rk4", "euler", "lsrk54", "lsrk144"]
    if integrator not in allowed_integrators:
        error_message = "Invalid time integrator: {}".format(integrator)
        raise RuntimeError(error_message)

    s0_sc = np.log10(1.0e-4 / np.power(order, 4))
    # This uses proportionality constant of 3.0e-1 and taking 0p5x as the base grid h
    alpha_sc = (3.0e-1*(1.0)/order)
    if rank == 0:
        print(f"\tShock capturing parameters: alpha {alpha_sc}, "
              f"s0 {s0_sc}, kappa {kappa_sc}")

    if rank == 0:
        print("#### Simluation control data: ####")
        print(f"\tnviz = {nviz}")
        print(f"\tnrestart = {nrestart}")
        print(f"\tnhealth = {nhealth}")
        print(f"\tnstatus = {nstatus}")
        print(f"\tcurrent_dt = {current_dt}")
        print(f"\tt_final = {t_final}")
        print(f"\torder = {order}")
        print(f"\tTime integration {integrator}")
        print("#### Simluation control data: ####")

    timestepper = rk4_step
    if integrator == "euler":
        timestepper = euler_step
    if integrator == "lsrk54":
        timestepper = lsrk54_step
    if integrator == "lsrk144":
        timestepper = lsrk144_step

    # {{{ Initialize simple transport model
    mu = 1.0e-5
    kappa = 1.225*mu/0.75
    transport_model = SimpleTransport(viscosity=mu, thermal_conductivity=kappa)
    # }}}
    # working gas: O2/N2 #
    #   O2 mass fraction 0.273
    #   gamma = 1.4
    #   cp = 37.135 J/mol-K,
    #   rho= 1.977 kg/m^3 @298K
    gamma = 1.4
    mw_o2 = 15.999*2
    mw_n2 = 14.0067*2
    mf_o2 = 0.273
    mw = mw_o2*mf_o2 + mw_n2*(1.0 - mf_o2)
    r = 8314.59/mw

    # background
    #rho_bkrnd = 1.0e-1  # 1.77619667e-1
    pres_bkrnd = 5000
    temp_bkrnd = 298
    rho_bkrnd = pres_bkrnd/r/temp_bkrnd

    # nozzle inflow #
    #
    # stagnation tempertuare 2076.43 K
    # stagnation pressure 2.745e5 Pa
    #
    # isentropic expansion based on the area ratios between the inlet (r=54e-3m) and
    # the throat (r=3.167e-3)
    #
    dim = 2
    vel_inflow = np.zeros(shape=(dim,))
    vel_outflow = np.zeros(shape=(dim,))
    vel_bkrnd = np.zeros(shape=(dim,))
    total_pres_inflow = 2.745e5
    total_temp_inflow = 2076.43

    throat_height = 3.167e-3
    inlet_height = 54.0e-3
    outlet_height = 28.56e-3
    inlet_area_ratio = inlet_height/throat_height
    outlet_area_ratio = inlet_height/throat_height


    inlet_mach = getMachFromAreaRatio(area_ratio=inlet_area_ratio,
                                      gamma=gamma,
                                      mach_guess=0.01)
    pres_inflow = getIsentropicPressure(mach=inlet_mach,
                                        P0=total_pres_inflow,
                                        gamma=gamma)
    temp_inflow = getIsentropicTemperature(mach=inlet_mach,
                                           T0=total_temp_inflow,
                                           gamma=gamma)
    rho_inflow = pres_inflow/temp_inflow/r
    vel_inflow[0] = inlet_mach*math.sqrt(gamma*pres_inflow/rho_inflow)

    if rank == 0:
        print(f"inlet Mach number {inlet_mach}")
        print(f"inlet temperature {temp_inflow}")
        print(f"inlet pressure {pres_inflow}")
        #print(f"final inlet pressure {pres_inflow_final}")

    outlet_mach = getMachFromAreaRatio(area_ratio=outlet_area_ratio,
                                      gamma=gamma,
                                      mach_guess=1.1)
    pres_outflow = getIsentropicPressure(mach=outlet_mach,
                                        P0=total_pres_inflow,
                                        gamma=gamma)
    temp_outflow = getIsentropicTemperature(mach=outlet_mach,
                                           T0=total_temp_inflow,
                                           gamma=gamma)
    rho_outflow = pres_inflow/temp_inflow/r
    vel_outflow[0] = inlet_mach*math.sqrt(gamma*pres_outflow/rho_outflow)

    if rank == 0:
        print(f"outlet Mach number {outlet_mach}")
        print(f"outlet temperature {temp_outflow}")
        print(f"outlet pressure {pres_outflow}")
        print(f"outlet velocity {vel_outflow[0]}")

    eos = IdealSingleGas(
        gamma=gamma, gas_const=r, transport_model=transport_model
    )
    #bulk_init = Discontinuity(dim=dim, x0=0.235, sigma=0.004, rhol=rho_inflow,
                              #rhor=rho_bkrnd, pl=pres_inflow, pr=pres_bkrnd,
                              #ul=vel_inflow[0], ur=300.0)

    bulk_init = PlanarDiscontinuity(dim=dim, disc_location=0.235, sigma=0.004,
        temperature_left=temp_inflow, temperature_right=temp_bkrnd,
        pressure_left=pres_inflow, pressure_right=pres_bkrnd,
        velocity_left=vel_inflow, velocity_right=vel_bkrnd)

    inflow_init = IsentropicInflow(
        dim=dim,
        T0=total_temp_inflow,
        P0=total_pres_inflow,
        mach=inlet_mach
    )
    outflow_init = Uniform(
        dim=dim,
        rho=rho_outflow,
        p=pres_outflow,
        velocity=vel_outflow
    )

    inflow = PrescribedInviscidBoundary(fluid_solution_func=inflow_init)
    outflow = PrescribedInviscidBoundary(fluid_solution_func=outflow_init)
    wall = IsothermalNoSlipBoundary()

    boundaries = {
        DTAG_BOUNDARY("inflow"): inflow,
        DTAG_BOUNDARY("outflow"): outflow,
        DTAG_BOUNDARY("wall"): wall
    }

    viz_path = "viz_data/"
    vizname = viz_path + casename
    restart_path = "restart_data/"
    restart_pattern = (
        restart_path + "{cname}-{step:06d}-{rank:04d}.pkl"
    )
    if restart_filename:  # read the grid from restart data
        restart_filename = f"{restart_filename}-{rank:04d}.pkl"

        from mirgecom.restart import read_restart_data
        restart_data = read_restart_data(actx, restart_filename)
        current_step = restart_data["step"]
        current_t = restart_data["t"]
        local_mesh = restart_data["local_mesh"]
        local_nelements = local_mesh.nelements
        global_nelements = restart_data["global_nelements"]
        restart_order = int(restart_data["order"])

        assert restart_data["nparts"] == nparts
    else:  # generate the grid from scratch
        local_mesh, global_nelements = generate_and_distribute_mesh(comm, get_mesh)
        local_nelements = local_mesh.nelements

    if rank == 0:
        logging.info("Making discretization")

    discr = EagerDGDiscretization(
        actx, local_mesh, order=order, mpi_communicator=comm
    )
    if rank == 0:
        logging.info("Done Making discretization")


    #from pytools.obj_array import make_obj_array

    #wtf is this doing? zero out the cavity?
    #mom_init = make_obj_array([zeros + 513 * 0.15, zeros])
    #state_init = make_conserved(dim, mass=0.15+zeros, energy=315000.0+zeros,
                                #momentum=mom_init)

    #sponge_sigma = (
        #1.0e-2 / current_dt * 0.5 * (1.0 + actx.np.tanh((nodes[0] - 0.95) / 0.02))
    #)
    #ref_state = bulk_init(x_vec=nodes, eos=eos, time=0.0)

    # initialize the sponge field
    #MJA comment out temporarily
    print("getting nodes?")
    #nodes = thaw(actx, discr.nodes())
    nodes = thaw(discr.nodes(), actx)
    print("done getting nodes?")
    #zeros = discr.zeros(actx)
    #def gen_sponge():
        #thickness = 0.15
        #amplitude = 1.0/current_dt/25.0
        #x0 = 0.05
#
        #return amplitude * actx.np.where(
            #actx.np.greater(nodes[0], x0),
            #zeros + ((nodes[0] - x0) / thickness) * ((nodes[0] - x0) / thickness),
            #zeros + 0.0,
        #)
#
    ##zeros = 0*nodes[0]
    #sponge_sigma = gen_sponge()
    #ref_state = outflow_init(x_vec=nodes, eos=eos, time=0.0)

    vis_timer = None
    log_cfl = LogUserQuantity(name="cfl", value=current_cfl)

    if logmgr:
        logmgr_add_cl_device_info(logmgr, queue)
        logmgr_add_many_discretization_quantities(logmgr, discr, dim,
                             extract_vars_for_logging, units_for_logging)

        logmgr.add_quantity(log_cfl, interval=nstatus)

        logmgr.add_watches([
            ("step.max", "step = {value}, "),
            ("t_sim.max", "sim time: {value:1.6e} s, "),
            ("cfl.max", "cfl = {value:1.4f}\n"),
            ("min_pressure", "------- P (min, max) (Pa) = ({value:1.9e}, "),
            ("max_pressure", "{value:1.9e})\n"),
            ("min_temperature", "------- T (min, max) (K)  = ({value:7g}, "),
            ("max_temperature", "{value:7g})\n"),
            ("t_step.max", "------- step walltime: {value:6g} s, "),
            ("t_log.max", "log walltime: {value:6g} s")
        ])

        try:
            logmgr.add_watches(["memory_usage.max"])
        except KeyError:
            pass

        if use_profiling:
            logmgr.add_watches(["pyopencl_array_time.max"])

        vis_timer = IntervalTimer("t_vis", "Time spent visualizing")
        logmgr.add_quantity(vis_timer)

    if rank == 0:
        logging.info("Before restart/init")

    if restart_filename:
        if rank == 0:
            logging.info("Restarting soln.")
        current_state = restart_data["state"]
        if restart_order != order:
            restart_discr = EagerDGDiscretization(
                actx,
                local_mesh,
                order=restart_order,
                mpi_communicator=comm)
            from meshmode.discretization.connection import make_same_mesh_connection
            connection = make_same_mesh_connection(
                actx,
                discr.discr_from_dd("vol"),
                restart_discr.discr_from_dd("vol")
            )
            restart_state = restart_data["state"]
            current_state = connection(restart_state)
        if logmgr:
            from mirgecom.logging_quantities import logmgr_set_time
            logmgr_set_time(logmgr, current_step, current_t)
    else:
        # Set the current state from time 0
        if rank == 0:
            logging.info("Initializing soln.")
        current_state = bulk_init(x_vec=nodes, eos=eos, time=0)

    visualizer = make_visualizer(discr)

    #    initname = initializer.__class__.__name__
    eosname = eos.__class__.__name__
    init_message = make_init_message(dim=dim, order=order, nelements=local_nelements,
                                     global_nelements=global_nelements,
                                     dt=current_dt, t_final=t_final, nstatus=nstatus,
                                     nviz=nviz, cfl=current_cfl,
                                     constant_cfl=constant_cfl, initname=casename,
                                     eosname=eosname, casename=casename)
    if rank == 0:
        logger.info(init_message)

    def my_write_viz(step, t, state, dv=None, tagged_cells=None, ts_field=None):
        if dv is None:
            dv = eos.dependent_vars(state)
        if tagged_cells is None:
            tagged_cells = smoothness_indicator(discr, state.mass, s0=s0_sc,
                                                kappa=kappa_sc)
        viz_fields = [("cv", state),
                      ("dv", dv),
                      #("sponge_sigma", gen_sponge()),
                      ("tagged_cells", tagged_cells),
                      ("dt" if constant_cfl else "cfl", ts_field)]
        write_visfile(discr, viz_fields, visualizer, vizname=vizname,
                      step=step, t=t, overwrite=True)

    def my_write_restart(step, t, state):
        restart_fname = restart_pattern.format(cname=casename, step=step, rank=rank)
        if restart_fname != restart_filename:
            restart_data = {
                "local_mesh": local_mesh,
                "state": state,
                "t": t,
                "step": step,
                "order": order,
                "global_nelements": global_nelements,
                "num_parts": nparts
            }
            write_restart_file(actx, restart_data, restart_fname, comm)

    def my_health_check(dv):
        health_error = False
        if check_naninf_local(discr, "vol", dv.pressure):
            health_error = True
            logger.info(f"{rank=}: NANs/Infs in pressure data.")

        from mirgecom.simutil import allsync
        if allsync(check_range_local(discr, "vol", dv.pressure,
                                     health_pres_min, health_pres_max),
                                     comm, op=MPI.LOR):
            health_error = True
            p_min = nodal_min(discr, "vol", dv.pressure)
            p_max = nodal_max(discr, "vol", dv.pressure)
            logger.info(f"Pressure range violation ({p_min=}, {p_max=})")

        return health_error

    def my_get_timestep(t, dt, state):
        t_remaining = max(0, t_final - t)
        if constant_cfl:
            from mirgecom.viscous import get_viscous_timestep
            ts_field = current_cfl * get_viscous_timestep(discr, eos=eos, cv=state)
            from grudge.op import nodal_min
            dt = nodal_min(discr, "vol", ts_field)
            cfl = current_cfl
        else:
            from mirgecom.viscous import get_viscous_cfl
            ts_field = get_viscous_cfl(discr, eos=eos, dt=dt, cv=state)
            from grudge.op import nodal_max
            cfl = nodal_max(discr, "vol", ts_field)

        return ts_field, cfl, min(t_remaining, dt)

    def my_pre_step(step, t, dt, state):
        try:
            dv = None

            if logmgr:
                logmgr.tick_before()

            ts_field, cfl, dt = my_get_timestep(t, dt, state)
            log_cfl.set_quantity(cfl)

            do_viz = check_step(step=step, interval=nviz)
            do_restart = check_step(step=step, interval=nrestart)
            do_health = check_step(step=step, interval=nhealth)

            if do_health:
                dv = eos.dependent_vars(state)
                from mirgecom.simutil import allsync
                health_errors = allsync(my_health_check(dv), comm,
                                        op=MPI.LOR)
                if health_errors:
                    if rank == 0:
                        logger.info("Fluid solution failed health check.")
                    raise MyRuntimeError("Failed simulation health check.")

            if do_restart:
                my_write_restart(step=step, t=t, state=state)

            if do_viz:
                if dv is None:
                    dv = eos.dependent_vars(state)
                my_write_viz(step=step, t=t, state=state, dv=dv)

        except MyRuntimeError:
            if rank == 0:
                logger.info("Errors detected; attempting graceful exit.")
            my_write_viz(step=step, t=t, state=state)
            my_write_restart(step=step, t=t, state=state)
            raise

        dt = get_sim_timestep(discr, state, t, dt, current_cfl, eos, t_final,
                              constant_cfl)

        return state, dt

    def my_post_step(step, t, dt, state):
        # Logmgr needs to know about EOS, dt, dim?
        # imo this is a design/scope flaw
        if logmgr:
            set_dt(logmgr, dt)
            set_sim_state(logmgr, dim, state, eos)
            logmgr.tick_after()
        return state, dt

    def my_rhs(t, state):
        return (
            ns_operator(discr, cv=state, t=t, boundaries=boundaries, eos=eos)
            + make_conserved(
                dim, q=av_operator(discr, q=state.join(), boundaries=boundaries,
                                   boundary_kwargs={"time": t, "eos": eos},
                                   alpha=alpha_sc, s0=s0_sc, kappa=kappa_sc)
            ) #+ sponge(cv=state, cv_ref=ref_state, sigma=sponge_sigma)
        )

    current_dt = get_sim_timestep(discr, current_state, current_t, current_dt,
                                  current_cfl, eos, t_final, constant_cfl)

    current_step, current_t, current_state = \
        advance_state(rhs=my_rhs, timestepper=timestepper,
                      pre_step_callback=my_pre_step,
                      post_step_callback=my_post_step, dt=current_dt,
                      state=current_state, t=current_t, t_final=t_final)

    # Dump the final data
    if rank == 0:
        logger.info("Checkpointing final state ...")
    final_dv = eos.dependent_vars(current_state)
    my_write_viz(step=current_step, t=current_t, state=current_state, dv=final_dv)
    my_write_restart(step=current_step, t=current_t, state=current_state)

    if logmgr:
        logmgr.close()
    elif use_profiling:
        print(actx.tabulate_profiling_data())

    finish_tol = 1e-16
    assert np.abs(current_t - t_final) < finish_tol


if __name__ == "__main__":
    import sys

    logging.basicConfig(format="%(message)s", level=logging.INFO)

    import argparse
    parser = argparse.ArgumentParser(
        description="MIRGE-Com Isentropic Nozzle Driver")
    parser.add_argument("-r", "--restart_file", type=ascii, dest="restart_file",
                        nargs="?", action="store", help="simulation restart file")
    parser.add_argument("-i", "--input_file", type=ascii, dest="input_file",
                        nargs="?", action="store", help="simulation config file")
    parser.add_argument("-c", "--casename", type=ascii, dest="casename", nargs="?",
                        action="store", help="simulation case name")
    parser.add_argument("--profile", action="store_true", default=False,
                        help="enable kernel profiling [OFF]")
    parser.add_argument("--log", action="store_true", default=True,
                        help="enable logging profiling [ON]")
    parser.add_argument("--lazy", action="store_true", default=False,
                        help="enable lazy evaluation [OFF]")

    args = parser.parse_args()

    # for writing output
    casename = "isolator"
    if args.casename:
        print(f"Custom casename {args.casename}")
        casename = args.casename.replace("'", "")
    else:
        print(f"Default casename {casename}")

    if args.profile:
        if args.lazy:
            raise ValueError("Can't use lazy and profiling together.")
        actx_class = PyOpenCLProfilingArrayContext
    else:
        actx_class = PytatoPyOpenCLArrayContext if args.lazy \
            else PyOpenCLArrayContext

    restart_filename = None
    if args.restart_file:
        restart_filename = (args.restart_file).replace("'", "")
        print(f"Restarting from file: {restart_filename}")

    input_file = None
    if args.input_file:
        input_file = args.input_file.replace("'", "")
        print(f"Ignoring user input from file: {input_file}")
    else:
        print("No user input file, using default values")

    print(f"Running {sys.argv[0]}\n")
    main(restart_filename=restart_filename, user_input_file=input_file,
         use_profiling=args.profile, use_logmgr=args.log,
         actx_class=actx_class)

# vim: foldmethod=marker
