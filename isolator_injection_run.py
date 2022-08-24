"""Simulation driver for the Y2 Isolator case."""

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
import sys
import yaml
import numpy as np
import pyopencl as cl
import numpy.linalg as la  # noqa
import pyopencl.array as cla  # noqa
from functools import partial
from pytools.obj_array import make_obj_array

from meshmode.mesh import BTAG_ALL, BTAG_NONE  # noqa
from grudge.eager import EagerDGDiscretization
from grudge.shortcuts import make_visualizer
from grudge.dof_desc import DTAG_BOUNDARY
#from grudge.op import nodal_max, nodal_min
from logpyle import IntervalTimer, set_dt
from mirgecom.logging_quantities import (
    initialize_logmgr,
    logmgr_add_cl_device_info,
    logmgr_set_time,
    logmgr_add_device_name,
    logmgr_add_device_memory_usage,
)

from mirgecom.navierstokes import ns_operator
from mirgecom.artificial_viscosity import \
    av_laplacian_operator, smoothness_indicator
from mirgecom.simutil import (
    check_step,
    write_visfile,
    check_naninf_local,
    check_range_local,
    get_sim_timestep,
    force_evaluation
)
from mirgecom.restart import write_restart_file
from mirgecom.io import make_init_message
from mirgecom.mpi import mpi_entry_point
from mirgecom.integrators import (rk4_step, lsrk54_step, lsrk144_step,
                                  euler_step)
from mirgecom.inviscid import (inviscid_facial_flux_rusanov,
                               inviscid_facial_flux_hll)
from grudge.shortcuts import compiled_lsrk45_step

from mirgecom.steppers import advance_state
from mirgecom.boundary import (
    PrescribedFluidBoundary,
    IsothermalWallBoundary,
    DummyBoundary,
    SymmetryBoundary
)
from mirgecom.eos import IdealSingleGas, PyrometheusMixture
from mirgecom.transport import (SimpleTransport,
                                PowerLawTransport,
                                ArtificialViscosityTransport,
                                ArtificialViscosityTransportDiv)
from mirgecom.gas_model import GasModel, make_fluid_state
from mirgecom.fluid import make_conserved
from mirgecom.limiter import bound_preserving_limiter
from mirgecom.gas_model import make_operator_fluid_states
from mirgecom.navierstokes import grad_cv_operator
from dataclasses import replace


class SingleLevelFilter(logging.Filter):
    """Filter I/O."""
    def __init__(self, passlevel, reject):
        """Initialize the I/O filter."""
        self.passlevel = passlevel
        self.reject = reject

    def filter(self, record):
        """Filter it."""
        if self.reject:
            return (record.levelno != self.passlevel)
        else:
            return (record.levelno == self.passlevel)


class MyRuntimeError(RuntimeError):
    """Simple exception to kill the simulation."""

    pass


class SparkSource:
    r"""Deposit energy from an ignition source."

    Internal energy is deposited as a gaussian of the form:

    .. math::

        e &= e + e_{a}\exp^{(1-r^{2})}\\

    .. automethod:: __init__
    .. automethod:: __call__
    """

    def __init__(self, *, dim, center=None, width=1.0,
                 amplitude=0., amplitude_func=None):
        r"""Initialize the spark parameters.

        Parameters
        ----------
        center: numpy.ndarray
            center of source
        amplitude: float
            source strength modifier
        amplitude_fun: function
            variation of amplitude with time
        """
        if center is None:
            center = np.zeros(shape=(dim,))
        self._center = center
        self._dim = dim
        self._amplitude = amplitude
        self._width = width
        self._amplitude_func = amplitude_func

    def __call__(self, x_vec, cv, time, **kwargs):
        """
        Create the energy deposition at time *t* and location *x_vec*.

        the source at time *t* is created by evaluting the gaussian
        with time-dependent amplitude at *t*.

        Parameters
        ----------
        cv: :class:`mirgecom.fluid.ConservedVars`
            Fluid conserved quantities
        time: float
            Current time at which the solution is desired
        x_vec: numpy.ndarray
            Nodal coordinates
        """
        t = time
        if self._amplitude_func is not None:
            amplitude = self._amplitude*self._amplitude_func(t)
        else:
            amplitude = self._amplitude

        #print(f"{time=} {amplitude=}")

        loc = self._center

        # coordinates relative to lump center
        rel_center = make_obj_array(
            [x_vec[i] - loc[i] for i in range(self._dim)]
        )
        actx = x_vec[0].array_context
        r = actx.np.sqrt(np.dot(rel_center, rel_center))
        expterm = amplitude * actx.np.exp(-(r**2)/(2*self._width*self._width))

        mass = 0*cv.mass
        momentum = 0*cv.momentum
        species_mass = 0*cv.species_mass

        energy = cv.energy + cv.mass*expterm

        return make_conserved(dim=self._dim, mass=mass, energy=energy,
                              momentum=momentum, species_mass=species_mass)


class InitSponge:
    r"""Initialize sponge.

    .. automethod:: __init__
    .. automethod:: __call__
    """

    def __init__(self, *, x0, thickness, amplitude):
        r"""Initialize the sponge parameters.

        Parameters
        ----------
        x0: float
            sponge starting x location
        thickness: float
            sponge extent
        amplitude: float
            sponge strength modifier
        """
        self._x0 = x0
        self._thickness = thickness
        self._amplitude = amplitude

    def __call__(self, x_vec, *, time=0.0):
        """Create the sponge intensity at locations *x_vec*.

        Parameters
        ----------
        x_vec: numpy.ndarray
            Coordinates at which solution is desired
        time: float
            Time at which solution is desired. The strength is (optionally)
            dependent on time
        """
        xpos = x_vec[0]
        actx = xpos.array_context
        zeros = 0*xpos
        x0 = zeros + self._x0

        return self._amplitude * actx.np.where(
            actx.np.greater(xpos, x0),
            (zeros + ((xpos - self._x0)/self._thickness) *
            ((xpos - self._x0)/self._thickness)),
            zeros + 0.0
        )


@mpi_entry_point
def main(ctx_factory=cl.create_some_context,
         restart_filename=None, target_filename=None,
         use_profiling=False, use_logmgr=True, user_input_file=None,
         use_overintegration=False, actx_class=False, casename=None,
         lazy=False):

    """Drive the isolator case."""
    if actx_class is None:
        raise RuntimeError("Array context class missing.")

    # control log messages
    logger = logging.getLogger(__name__)
    logger.propagate = False

    if (logger.hasHandlers()):
        logger.handlers.clear()

    # send info level messages to stdout
    h1 = logging.StreamHandler(sys.stdout)
    f1 = SingleLevelFilter(logging.INFO, False)
    h1.addFilter(f1)
    logger.addHandler(h1)

    # send everything else to stderr
    h2 = logging.StreamHandler(sys.stderr)
    f2 = SingleLevelFilter(logging.INFO, True)
    h2.addFilter(f2)
    logger.addHandler(h2)

    cl_ctx = ctx_factory()

    from mpi4py import MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    nparts = comm.Get_size()

    from mirgecom.simutil import global_reduce as _global_reduce
    global_reduce = partial(_global_reduce, comm=comm)

    if casename is None:
        casename = "mirgecom"

    # logging and profiling
    log_path = "log_data/"
    logname = log_path + casename + ".sqlite"

    if rank == 0:
        import os
        log_dir = os.path.dirname(logname)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir)
    comm.Barrier()

    logmgr = initialize_logmgr(use_logmgr,
        filename=logname, mode="wo", mpi_comm=comm)

    if use_profiling:
        queue = cl.CommandQueue(cl_ctx,
            properties=cl.command_queue_properties.PROFILING_ENABLE)
    else:
        queue = cl.CommandQueue(cl_ctx)

    # main array context for the simulation
    from mirgecom.simutil import get_reasonable_memory_pool
    alloc = get_reasonable_memory_pool(cl_ctx, queue)

    if lazy:
        actx = actx_class(comm, queue, mpi_base_tag=12000, allocator=alloc)
    else:
        actx = actx_class(comm, queue, allocator=alloc, force_device_scalars=True)

    # default i/o junk frequencies
    nviz = 500
    nhealth = 1
    nrestart = 5000
    nstatus = 1
    nlimit = 0

    # default timestepping control
    integrator = "rk4"
    current_dt = 1e-8
    t_final = 1e-7
    current_t = 0
    current_step = 0
    current_cfl = 1.0
    constant_cfl = False
    force_eval = True

    # default health status bounds
    health_pres_min = 1.0e-1
    health_pres_max = 2.0e6
    health_temp_min = 1.0
    health_temp_max = 5000
    health_mass_frac_min = -10
    health_mass_frac_max = 10

    # discretization and model control
    order = 1
    alpha_sc = 0.3
    s0_sc = -5.0
    kappa_sc = 0.5
    dim = 2
    inv_num_flux = "rusanov"

    # material properties
    mu = 1.0e-5
    spec_diff = 1e-4
    mu_override = False  # optionally read in from input
    nspecies = 0
    pyro_temp_iter = 3  # for pyrometheus, number of newton iterations
    pyro_temp_tol = 1.e-4  # for pyrometheus, toleranace for temperature residual
    transport_type = 0

    # rhs control
    use_ignition = False
    use_sponge = True
    use_combustion = True

    # artificial viscosity control
    #    0 - none
    #    1 - laplacian diffusion
    #    2 - physical viscosity based, rho indicator
    #    3 - physical viscosity based, div(velocity) indicator
    use_av = 0

    sponge_sigma = 1.0
    vel_sigma_inj = 5000

    # initialize the ignition spark
    spark_center = np.zeros(shape=(dim,))
    spark_center[0] = 0.677
    spark_center[1] = -0.021
    if dim == 3:
        spark_center[2] = 0.035/2.
    spark_diameter = 0.0025

    spark_strength = 30000000./current_dt
    #spark_strength = 5e-3

    spark_init_time = 999999999.

    spark_duration = 1.e-8

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
            nlimit = int(input_data["nlimit"])
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
            alpha_sc = float(input_data["alpha_sc"])
        except KeyError:
            pass
        try:
            kappa_sc = float(input_data["kappa_sc"])
        except KeyError:
            pass
        try:
            s0_sc = float(input_data["s0_sc"])
        except KeyError:
            pass
        try:
            mu_input = float(input_data["mu"])
            mu_override = True
        except KeyError:
            pass
        try:
            spec_diff = float(input_data["spec_diff"])
        except KeyError:
            pass
        try:
            nspecies = int(input_data["nspecies"])
        except KeyError:
            pass
        try:
            transport_type = int(input_data["transport"])
        except KeyError:
            pass
        try:
            pyro_temp_iter = int(input_data["pyro_temp_iter"])
        except KeyError:
            pass
        try:
            pyro_temp_tol = float(input_data["pyro_temp_tol"])
        except KeyError:
            pass
        try:
            order = int(input_data["order"])
        except KeyError:
            pass
        try:
            dim = int(input_data["dimen"])
        except KeyError:
            pass
        try:
            integrator = input_data["integrator"]
        except KeyError:
            pass
        try:
            inv_num_flux = input_data["inviscid_numerical_flux"]
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
        try:
            health_temp_min = float(input_data["health_temp_min"])
        except KeyError:
            pass
        try:
            health_temp_max = float(input_data["health_temp_max"])
        except KeyError:
            pass
        try:
            health_mass_frac_min = float(input_data["health_mass_frac_min"])
        except KeyError:
            pass
        try:
            health_mass_frac_max = float(input_data["health_mass_frac_max"])
        except KeyError:
            pass
        try:
            use_ignition = bool(input_data["use_ignition"])
        except KeyError:
            pass
        try:
            spark_init_time = float(input_data["ignition_init_time"])
        except KeyError:
            pass
        try:
            use_sponge = bool(input_data["use_sponge"])
        except KeyError:
            pass
        try:
            sponge_sigma = float(input_data["sponge_sigma"])
        except KeyError:
            pass
        try:
            use_av = int(input_data["use_av"])
        except KeyError:
            pass
        try:
            use_combustion = bool(input_data["use_combustion"])
        except KeyError:
            pass
        try:
            vel_sigma_inj = float(input_data["vel_sigma_inj"])
        except KeyError:
            pass

    # param sanity check
    allowed_integrators = ["rk4", "euler", "lsrk54", "lsrk144", "compiled_lsrk54"]
    if integrator not in allowed_integrators:
        error_message = "Invalid time integrator: {}".format(integrator)
        raise RuntimeError(error_message)

    allowed_inv_num_flux = ["rusanov", "hll"]
    if inv_num_flux not in allowed_inv_num_flux:
        error_message = "Invalid inviscid flux function: {}".format(inv_num_flux)
        raise RuntimeError(error_message)

    if integrator == "compiled_lsrk54":
        print("Setting force_eval = False for pre-compiled time integration")
        force_eval = False

    s0_sc = np.log10(1.0e-4 / np.power(order, 4))

    # use_av=3 specific parameters
    # flow stagnation temperature
    static_temp = 2076.43
    # steepness of the smoothed function
    theta_sc = 100
    # cutoff, smoothness below this value is ignored
    beta_sc = 0.01
    gamma_sc = 1.5

    if rank == 0:
        if use_av == 0:
            print("Artificial viscosity disabled")
        elif use_av == 1:
            print("Artificial viscosity using laplacian diffusion")
            print(f"Shock capturing parameters: alpha {alpha_sc}, "
                  f"s0 {s0_sc}, kappa {kappa_sc}")
        elif use_av == 2:
            print("Artificial viscosity using modified physical viscosity")
            print(f"Shock capturing parameters: alpha {alpha_sc}, "
                  f"s0 {s0_sc}, Pr 0.75")
        elif use_av == 3:
            print("Artificial viscosity using modified physical viscosity")
            print("Using velocity divergence indicator")
            print(f"Shock capturing parameters: alpha {alpha_sc}, "
                  f"gamma_sc {gamma_sc}"
                  f"theta_sc {theta_sc}, beta_sc {beta_sc}, Pr 0.75, "
                  f"stagnation temperature {static_temp}")

    if rank == 0:
        print("\n#### Simluation control data: ####")
        print(f"\tnviz = {nviz}")
        print(f"\tnrestart = {nrestart}")
        print(f"\tnhealth = {nhealth}")
        print(f"\tnstatus = {nstatus}")
        print(f"\tcurrent_dt = {current_dt}")
        print(f"\tt_final = {t_final}")
        print(f"\torder = {order}")
        print(f"\tdimen = {dim}")
        print(f"\tTime integration {integrator}")
        print("#### Simluation control data: ####\n")

    if rank == 0 and use_ignition:
        print("\n#### Ignition control parameters ####")
        print(f"spark center ({spark_center[0]},{spark_center[1]})")
        print(f"spark FWHM {spark_diameter}")
        print(f"spark strength {spark_strength}")
        print(f"ignition time {spark_init_time}")
        print(f"ignition duration {spark_duration}")
        print("#### Ignition control parameters ####\n")

    def _compiled_stepper_wrapper(state, t, dt, rhs):
        return compiled_lsrk45_step(actx, state, t, dt, rhs)

    timestepper = rk4_step
    if integrator == "euler":
        timestepper = euler_step
    if integrator == "lsrk54":
        timestepper = lsrk54_step
    if integrator == "lsrk144":
        timestepper = lsrk144_step
    if integrator == "compiled_lsrk54":
        timestepper = _compiled_stepper_wrapper

    if inv_num_flux == "rusanov":
        inviscid_numerical_flux_func = inviscid_facial_flux_rusanov
    if inv_num_flux == "hll":
        inviscid_numerical_flux_func = inviscid_facial_flux_hll

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
    # viscosity @ 400C, Pa-s
    mu_o2 = 3.76e-5
    mu_n2 = 3.19e-5
    mu_mix = mu_o2*mf_o2 + mu_n2*(1-mu_o2)  # 3.3456e-5
    mw = mw_o2*mf_o2 + mw_n2*(1.0 - mf_o2)
    r = 8314.59/mw
    cp = r*gamma/(gamma - 1)
    Pr = 0.75

    if mu_override:
        mu = mu_input
    else:
        mu = mu_mix

    kappa = cp*mu/Pr
    init_temperature = 300.0

    # don't allow limiting on flows without species
    if nspecies == 0:
        nlimit = 0

    limit_species = False
    if nlimit > 0:
        species_limit_sigma = 1./nlimit/current_dt
        limit_species = True
    else:
        species_limit_sigma = 0.

    # Turn off combustion unless EOS supports it
    if nspecies < 3:
        use_combustion = False

    if rank == 0:
        print("\n#### Simluation material properties: ####")
        print(f"\tPrandtl Number  = {Pr}")
        print(f"\tnspecies = {nspecies}")
        if nspecies == 0:
            print("\tno passive scalars, uniform ideal gas eos")
        elif nspecies == 2:
            print("\tpassive scalars to track air/fuel mixture, ideal gas eos")
        else:
            print("\tfull multi-species initialization with pyrometheus eos")
        if nlimit > 0:
            print(f"\tSpecies mass fractions limited to [0:1] over {nlimit} steps")

        transport_alpha = 0.6
        transport_beta = 4.093e-7
        transport_sigma = 2.0
        transport_n = 0.666

        if transport_type == 0:
            print("\t Simple transport model:")
            print("\t\t constant viscosity, species diffusivity")
            print(f"\tmu = {mu}")
            print(f"\tkappa = {kappa}")
            print(f"\tspecies diffusivity = {spec_diff}")
        elif transport_type == 1:
            print("\t Power law transport model:")
            print("\t\t temperature dependent viscosity, species diffusivity")
            print(f"\ttransport_alpha = {transport_alpha}")
            print(f"\ttransport_beta = {transport_beta}")
            print(f"\ttransport_sigma = {transport_sigma}")
            print(f"\ttransport_n = {transport_n}")
            print(f"\tspecies diffusivity = {spec_diff}")
        elif transport_type == 2:
            print("\t Pyrometheus transport model:")
            print("\t\t temperature/mass fraction dependence")
        else:
            error_message = "Unknown transport_type {}".format(transport_type)
            raise RuntimeError(error_message)

    spec_diffusivity = spec_diff * np.ones(nspecies)
    if transport_type == 0:
        physical_transport_model = SimpleTransport(
            viscosity=mu, thermal_conductivity=kappa,
            species_diffusivity=spec_diffusivity)
    if transport_type == 1:
        physical_transport_model = PowerLawTransport(
            alpha=transport_alpha, beta=transport_beta,
            sigma=transport_sigma, n=transport_n,
            species_diffusivity=spec_diffusivity)

    if use_av == 0 or use_av == 1:
        transport_model = physical_transport_model
    elif use_av == 2:
        transport_model = ArtificialViscosityTransport(
            physical_transport=physical_transport_model,
            av_mu=alpha_sc, av_prandtl=0.75)
    elif use_av == 3:
        transport_model = ArtificialViscosityTransportDiv(
            physical_transport=physical_transport_model,
            av_mu=alpha_sc, av_prandtl=0.75)

    chem_source_tol = 1.e-10
    # make the eos
    if nspecies < 3:
        eos = IdealSingleGas(gamma=gamma, gas_const=r)
        species_names = ["air", "fuel"]
    else:
        from mirgecom.thermochemistry import get_pyrometheus_wrapper_class
        from uiuc import Thermochemistry
        pyro_mech = get_pyrometheus_wrapper_class(
            pyro_class=Thermochemistry, temperature_niter=pyro_temp_iter,
            zero_level=chem_source_tol)(actx.np)
        eos = PyrometheusMixture(pyro_mech, temperature_guess=init_temperature)
        species_names = pyro_mech.species_names

    gas_model = GasModel(eos=eos, transport=transport_model)

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
        # will use this later
        #restart_nspecies = int(restart_data["nspecies"])

        assert restart_data["num_parts"] == nparts
        assert restart_data["nspecies"] == nspecies
    else:
        error_message = "Driver only supports restart. Start with -r <filename>"
        raise RuntimeError(error_message)

    if target_filename:  # read the grid from restart data
        target_filename = f"{target_filename}-{rank:04d}.pkl"

        from mirgecom.restart import read_restart_data
        target_data = read_restart_data(actx, target_filename)
        target_order = int(target_data["order"])
        # will use this later

        assert restart_data["num_parts"] == nparts
        assert restart_data["nspecies"] == nspecies
        assert restart_data["global_nelements"] == target_data["global_nelements"]
    else:
        logger.warning("No target file specied, using restart as target")

    if rank == 0:
        logging.info("Making discretization")

    from grudge.dof_desc import DISCR_TAG_BASE, DISCR_TAG_QUAD
    from meshmode.discretization.poly_element import \
          default_simplex_group_factory, QuadratureSimplexGroupFactory

    discr = EagerDGDiscretization(
        actx, local_mesh,
        discr_tag_to_group_factory={
            DISCR_TAG_BASE: default_simplex_group_factory(
                base_dim=local_mesh.dim, order=order),
            DISCR_TAG_QUAD: QuadratureSimplexGroupFactory(2*order + 1)
        },
        mpi_communicator=comm
    )

    if use_overintegration:
        quadrature_tag = DISCR_TAG_QUAD
    else:
        quadrature_tag = None

    if rank == 0:
        logging.info("Done making discretization")

    vis_timer = None

    if logmgr:
        logmgr_add_cl_device_info(logmgr, queue)
        logmgr_add_device_name(logmgr, queue)
        logmgr_add_device_memory_usage(logmgr, queue)

        logmgr.add_watches([
            ("step.max", "step = {value}, "),
            ("t_sim.max", "sim time: {value:1.6e} s, "),
            ("t_step.max", "step walltime: {value:6g} s")
            #("t_log.max", "log walltime: {value:6g} s")
        ])

        try:
            logmgr.add_watches(["memory_usage_python.max"])
            #logmgr.add_watches(["memory_usage_python.max",
            #                    "memory: {value:6g} MByte"])
        except KeyError:
            pass

        try:
            logmgr.add_watches(["memory_usage_gpu.max"])
        except KeyError:
            pass

        if use_profiling:
            logmgr.add_watches(["pyopencl_array_time.max"])

        vis_timer = IntervalTimer("t_vis", "Time spent visualizing")
        logmgr.add_quantity(vis_timer)

    if rank == 0:
        logging.info("Before restart/init")

    def get_fluid_state(cv, temperature_seed, smoothness=None):
        return make_fluid_state(cv=cv, gas_model=gas_model,
                                temperature_seed=temperature_seed,
                                smoothness=smoothness)

    create_fluid_state = actx.compile(get_fluid_state)

    def get_temperature_update(cv, temperature):
        y = cv.species_mass_fractions
        e = gas_model.eos.internal_energy(cv)/cv.mass
        return actx.np.abs(
            pyro_mech.get_temperature_update_energy(e, temperature, y))

    get_temperature_update_compiled = actx.compile(get_temperature_update)

    from grudge.dt_utils import characteristic_lengthscales
    length_scales = characteristic_lengthscales(actx, discr)

    # compiled wrapper for grad_cv_operator
    def _grad_cv_operator(fluid_state, time):
        return grad_cv_operator(discr=discr, gas_model=gas_model,
                                boundaries=boundaries,
                                state=fluid_state,
                                time=time,
                                quadrature_tag=quadrature_tag)

    grad_cv_operator_compiled = actx.compile(_grad_cv_operator) # noqa

    def compute_smoothness(cv, dv, grad_cv):

        from mirgecom.fluid import velocity_gradient
        #div_v = actx.np.abs(np.trace(velocity_gradient(cv, grad_cv)))
        div_v = np.trace(velocity_gradient(cv, grad_cv))

        gamma = gas_model.eos.gamma(cv=cv, temperature=dv.temperature)
        r = gas_model.eos.gas_const(cv)
        c_star = actx.np.sqrt(gamma*r*(2/(gamma+1)*static_temp))
        indicator = -gamma_sc*length_scales*div_v/c_star

        smoothness = actx.np.log(
            1 + actx.np.exp(theta_sc*(indicator - beta_sc)))/theta_sc
        return smoothness*gamma_sc*length_scales

    compute_smoothness_compiled = actx.compile(compute_smoothness) # noqa

    if restart_filename:
        if rank == 0:
            logging.info("Restarting soln.")
        restart_cv = restart_data["cv"]
        temperature_seed = restart_data["temperature_seed"]
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
            restart_cv = connection(restart_data["cv"])
            temperature_seed = connection(restart_data["temperature_seed"])

        if logmgr:
            logmgr_set_time(logmgr, current_step, current_t)
    else:
        error_message = "Driver only supports restart. Start with -r <filename>"
        raise RuntimeError(error_message)

    if target_filename:
        if rank == 0:
            logging.info("Reading target soln.")
        target_cv = target_data["cv"]
        if target_order != order:
            target_discr = EagerDGDiscretization(
                actx,
                local_mesh,
                order=target_order,
                mpi_communicator=comm)
            from meshmode.discretization.connection import make_same_mesh_connection
            connection = make_same_mesh_connection(
                actx,
                discr.discr_from_dd("vol"),
                target_discr.discr_from_dd("vol")
            )
            target_cv = connection(target_data["cv"])

        if logmgr:
            logmgr_set_time(logmgr, current_step, current_t)
    else:
        target_cv = restart_cv

    no_smoothness = 0.*restart_cv.mass
    smoothness = no_smoothness
    target_smoothness = smoothness
    if use_av == 1 or use_av == 2:
        smoothness = smoothness_indicator(discr, restart_cv.mass,
                                          kappa=kappa_sc, s0=s0_sc)
        target_smoothness = smoothness_indicator(discr, target_cv.mass,
                                                 kappa=kappa_sc, s0=s0_sc)

    current_state = make_fluid_state(restart_cv, gas_model, temperature_seed,
                                     smoothness=smoothness)
    target_state = make_fluid_state(target_cv, gas_model, temperature_seed,
                                    smoothness=target_smoothness)

    if use_av == 2:
        # use dummy boundaries to setup the smoothness state for the target
        target_boundaries = {
            DTAG_BOUNDARY("flow"): DummyBoundary(),
            DTAG_BOUNDARY("wall"): IsothermalWallBoundary()
        }

        # use the divergence to compute the smoothness field
        target_grad_cv = grad_cv_operator(
            discr, gas_model, target_boundaries, target_state,
            time=0., quadrature_tag=quadrature_tag)
        target_smoothness = compute_smoothness(
            cv=target_cv, dv=target_state.dv, grad_cv=target_grad_cv)

        # avoid recomputation of temperature
        new_dv = replace(target_state.dv, smoothness=target_smoothness)
        target_state = replace(target_state, dv=new_dv)
        new_tv = gas_model.transport.transport_vars(
            cv=target_cv, dv=new_dv, eos=gas_model.eos)
        target_state = replace(target_state, tv=new_tv)

    temperature_seed = current_state.temperature

    force_evaluation(actx, current_state)
    force_evaluation(actx, target_state)

    # if you divide by 2.355, 50% of the spark is within this diameter
    spark_diameter /= 2.355
    # if you divide by 6, 99% of the energy is deposited in this time
    spark_duration /= 6.0697

    # gaussian application in time
    def spark_time_func(t):
        expterm = actx.np.exp((-(t - spark_init_time)**2) /
                              (2*spark_duration*spark_duration))
        return expterm

    #spark_strength = 0.0
    ignition_source = SparkSource(dim=dim, center=spark_center,
                                  amplitude=spark_strength,
                                  amplitude_func=spark_time_func,
                                  width=spark_diameter)

    # initialize the sponge field
    sponge_thickness = 0.09
    sponge_amp = sponge_sigma/current_dt/1000
    sponge_x0 = 0.9

    sponge_init = InitSponge(x0=sponge_x0, thickness=sponge_thickness,
                             amplitude=sponge_amp)
    x_vec = actx.thaw(discr.nodes())

    def _sponge_sigma(x_vec):
        return sponge_init(x_vec=x_vec)

    get_sponge_sigma = actx.compile(_sponge_sigma)
    sponge_sigma = get_sponge_sigma(x_vec)

    def _sponge_source(cv):
        """Create sponge source."""
        return sponge_sigma*(current_state.cv - cv)

    from mirgecom.gas_model import project_fluid_state
    from grudge.dof_desc import DOFDesc, as_dofdesc
    dd_base_vol = DOFDesc("vol")

    def get_target_state_on_boundary(btag):
        return project_fluid_state(
            discr, dd_base_vol,
            as_dofdesc(btag).with_discr_tag(quadrature_tag),
            target_state, gas_model
        )

    flow_ref_state = \
        get_target_state_on_boundary(DTAG_BOUNDARY("flow"))

    flow_ref_state = force_evaluation(actx, flow_ref_state)

    def _target_flow_state_func(**kwargs):
        return flow_ref_state

    flow_boundary = PrescribedFluidBoundary(
        boundary_state_func=_target_flow_state_func)

    wall = IsothermalWallBoundary()
    slip_wall = SymmetryBoundary()

    boundaries = {
        DTAG_BOUNDARY("flow"): flow_boundary,
        DTAG_BOUNDARY("wall"): wall
    }
    # allow for a slip boundary inside the injector
    if vel_sigma_inj == 0:
        boundaries = {
            DTAG_BOUNDARY("flow"): flow_boundary,
            DTAG_BOUNDARY("wall_without_injector"): wall,
            DTAG_BOUNDARY("injector_wall"): slip_wall
        }

    #from mirgecom.simutil import boundary_report
    #boundary_report(discr, boundaries, f"{casename}_boundaries_np{nparts}.yaml")

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

    # some utility functions
    def vol_min_loc(x):
        from grudge.op import nodal_min_loc
        return actx.to_numpy(nodal_min_loc(discr, "vol", x))[()]

    def vol_max_loc(x):
        from grudge.op import nodal_max_loc
        return actx.to_numpy(nodal_max_loc(discr, "vol", x))[()]

    def vol_min(x):
        from grudge.op import nodal_min
        return actx.to_numpy(nodal_min(discr, "vol", x))[()]

    def vol_max(x):
        from grudge.op import nodal_max
        return actx.to_numpy(nodal_max(discr, "vol", x))[()]

    def global_range_check(array, min_val, max_val):
        return global_reduce(
            check_range_local(discr, "vol", array, min_val, max_val), op="lor")

    def my_write_status(cv, dv, dt, cfl):
        status_msg = f"-------- dt = {dt:1.3e}, cfl = {cfl:1.4f}"
        p_min = vol_min(dv.pressure)
        p_max = vol_max(dv.pressure)
        t_min = vol_min(dv.temperature)
        t_max = vol_max(dv.temperature)

        from pytools.obj_array import obj_array_vectorize
        y_min = obj_array_vectorize(lambda x: vol_min(x),
                                      cv.species_mass_fractions)
        y_max = obj_array_vectorize(lambda x: vol_max(x),
                                      cv.species_mass_fractions)

        dv_status_msg = (
            f"\n-------- P (min, max) (Pa) = ({p_min:1.9e}, {p_max:1.9e})")
        dv_status_msg += (
            f"\n-------- T (min, max) (K)  = ({t_min:7g}, {t_max:7g})")

        if nspecies > 2:
            # check the temperature convergence
            # a single call to get_temperature_update is like taking an additional
            # Newton iteration and gives us a residual
            temp_resid = get_temperature_update_compiled(
                cv, dv.temperature)/dv.temperature
            temp_err_min = vol_min(temp_resid)
            temp_err_max = vol_max(temp_resid)
            dv_status_msg += (
                f"\n-------- T_resid (min, max) = "
                f"({temp_err_min:1.5e}, {temp_err_max:1.5e})")

        for i in range(nspecies):
            dv_status_msg += (
                f"\n-------- y_{species_names[i]} (min, max) = "
                f"({y_min[i]:1.3e}, {y_max[i]:1.3e})")
        status_msg += dv_status_msg
        status_msg += "\n"

        if rank == 0:
            logger.info(status_msg)

    def get_production_rates(cv, temperature):
        return eos.get_production_rates(cv, temperature)

    compute_production_rates = actx.compile(get_production_rates)

    def my_write_viz(step, t, fluid_state, ts_field, alpha_field):

        cv = fluid_state.cv
        dv = fluid_state.dv
        mu = fluid_state.viscosity

        smoothness = dv.smoothness
        indicator = no_smoothness
        if use_av == 1:
            smoothness = smoothness_indicator(discr, cv.mass, s0=s0_sc,
                                              kappa=kappa_sc)

        grad_cv = grad_cv_operator(discr, gas_model, boundaries,
                                   fluid_state, time=current_t,
                                   quadrature_tag=quadrature_tag)
        from mirgecom.fluid import velocity_gradient
        grad_v = velocity_gradient(cv, grad_cv)
        div_v = np.trace(velocity_gradient(cv, grad_cv))

        if use_av == 3:

            gamma = gas_model.eos.gamma(cv=cv, temperature=dv.temperature)
            r = gas_model.eos.gas_const(cv)
            c_star = actx.np.sqrt(gamma*r*(2/(gamma+1)*static_temp))
            #indicator = -alpha_sc*length_scales*actx.np.abs(div_v)/c_star
            indicator = -alpha_sc*length_scales*div_v/c_star

            # make a smoothness indicator
            smoothness = compute_smoothness(cv, dv, grad_cv)

        mach = (actx.np.sqrt(np.dot(cv.velocity, cv.velocity)) /
                            dv.speed_of_sound)

        viz_fields = [("cv", cv),
                      ("dv", dv),
                      ("mach", mach),
                      ("rank", rank),
                      ("velocity", cv.velocity),
                      ("grad_v_x", grad_v[0]),
                      ("grad_v_y", grad_v[1]),
                      ("div_v", div_v),
                      ("sponge_sigma", sponge_sigma),
                      ("alpha", alpha_field),
                      ("indicator", indicator),
                      ("smoothness", smoothness),
                      ("mu", mu),
                      ("dt" if constant_cfl else "cfl", ts_field)]
        # species mass fractions
        viz_fields.extend(
            ("Y_"+species_names[i], cv.species_mass_fractions[i])
            for i in range(nspecies))

        if nspecies > 2:
            temp_resid = get_temperature_update_compiled(
                cv, dv.temperature)/dv.temperature
            production_rates = compute_production_rates(fluid_state.cv,
                                                        fluid_state.temperature)
            viz_ext = [("temp_resid", temp_resid),
                       ("production_rates", production_rates)]
            viz_fields.extend(viz_ext)

        # additional viz quantities, add in some non-dimensional numbers
        if 1:
            cell_Re = cv.mass*cv.speed*length_scales/fluid_state.viscosity
            cp = gas_model.eos.heat_capacity_cp(cv, fluid_state.temperature)
            alpha_heat = fluid_state.thermal_conductivity/cp/fluid_state.viscosity
            cell_Pe_heat = length_scales*cv.speed/alpha_heat
            from mirgecom.viscous import get_local_max_species_diffusivity
            d_alpha_max = \
                get_local_max_species_diffusivity(fluid_state.array_context,
                                                  fluid_state.species_diffusivity)
            cell_Pe_mass = length_scales*cv.speed/d_alpha_max
            viz_ext = [("Re", cell_Re),
                       ("Pe_mass", cell_Pe_mass),
                       ("Pe_heat", cell_Pe_heat)]
            viz_fields.extend(viz_ext)

        write_visfile(discr=discr, io_fields=viz_fields, visualizer=visualizer,
                      vizname=vizname, comm=comm, step=step, t=t, overwrite=True)

    def my_write_restart(step, t, cv, temperature_seed):
        restart_fname = restart_pattern.format(cname=casename, step=step, rank=rank)
        if restart_fname != restart_filename:
            restart_data = {
                "local_mesh": local_mesh,
                "cv": cv,
                "temperature_seed": temperature_seed,
                "nspecies": nspecies,
                "t": t,
                "step": step,
                "order": order,
                "global_nelements": global_nelements,
                "num_parts": nparts
            }
            write_restart_file(actx, restart_data, restart_fname, comm)

    def my_health_check(fluid_state):
        health_error = False
        cv = fluid_state.cv
        dv = fluid_state.dv

        if check_naninf_local(discr, "vol", dv.pressure):
            health_error = True
            logger.info(f"{rank=}: NANs/Infs in pressure data.")

        if global_range_check(dv.pressure, health_pres_min, health_pres_max):
            health_error = True
            p_min = vol_min(dv.pressure)
            p_max = vol_max(dv.pressure)
            logger.info(f"Pressure range violation: "
                        f"Simulation Range ({p_min=}, {p_max=}) "
                        f"Specified Limits ({health_pres_min=}, {health_pres_max=})")

        if global_range_check(dv.temperature, health_temp_min, health_temp_max):
            health_error = True
            t_min = vol_min(dv.temperature)
            t_max = vol_max(dv.temperature)
            logger.info(f"Temperature range violation: "
                        f"Simulation Range ({t_min=}, {t_max=}) "
                        f"Specified Limits ({health_temp_min=}, {health_temp_max=})")

        for i in range(nspecies):
            if global_range_check(cv.species_mass_fractions[i],
                                  health_mass_frac_min, health_mass_frac_max):
                health_error = True
                y_min = vol_min(cv.species_mass_fractions[i])
                y_max = vol_max(cv.species_mass_fractions[i])
                logger.info(f"Species mass fraction range violation. "
                            f"{species_names[i]}: ({y_min=}, {y_max=})")

        if nspecies > 2:
            # check the temperature convergence
            # a single call to get_temperature_update is like taking an additional
            # Newton iteration and gives us a residual
            temp_resid = get_temperature_update_compiled(
                cv, dv.temperature)/dv.temperature
            temp_err = vol_max(temp_resid)
            if temp_err > pyro_temp_tol:
                health_error = True
                logger.info(f"Temperature is not converged "
                            f"{temp_err=} > {pyro_temp_tol}.")

        return health_error

    def my_get_viscous_timestep(discr, state, alpha):
        """Routine returns the the node-local maximum stable viscous timestep.

        Parameters
        ----------
        discr: grudge.eager.EagerDGDiscretization
            the discretization to use
        state: :class:`~mirgecom.gas_model.FluidState`
            Full fluid state including conserved and thermal state
        alpha: :class:`~meshmode.DOFArray`
            Arfifical viscosity

        Returns
        -------
        :class:`~meshmode.dof_array.DOFArray`
            The maximum stable timestep at each node.
        """

        nu = 0
        d_alpha_max = 0

        if state.is_viscous:
            nu = state.viscosity/state.mass_density
            # this appears to break lazy for whatever reason
            from mirgecom.viscous import get_local_max_species_diffusivity
            d_alpha_max = \
                get_local_max_species_diffusivity(
                    state.array_context,
                    state.species_diffusivity
                )

        return (
            length_scales / (state.wavespeed
            + ((nu + d_alpha_max + alpha) / length_scales))
        )

    def my_get_viscous_cfl(discr, dt, state, alpha):
        """Calculate and return node-local CFL based on current state and timestep.

        Parameters
        ----------
        discr: :class:`grudge.eager.EagerDGDiscretization`
            the discretization to use
        dt: float or :class:`~meshmode.dof_array.DOFArray`
            A constant scalar dt or node-local dt
        state: :class:`~mirgecom.gas_model.FluidState`
            Full fluid state including conserved and thermal state
        alpha: :class:`~meshmode.DOFArray`
            Arfifical viscosity

        Returns
        -------
        :class:`~meshmode.dof_array.DOFArray`
            The CFL at each node.
        """
        return dt / my_get_viscous_timestep(discr, state=state, alpha=alpha)

    def my_get_timestep(t, dt, state, alpha):
        t_remaining = max(0, t_final - t)
        if constant_cfl:
            ts_field = current_cfl * my_get_viscous_timestep(discr, state=state,
                                                             alpha=alpha)
            from grudge.op import nodal_min
            dt = actx.to_numpy(nodal_min(discr, "vol", ts_field))
            cfl = current_cfl
        else:
            ts_field = my_get_viscous_cfl(discr, dt=dt, state=state, alpha=alpha)
            from grudge.op import nodal_max
            cfl = actx.to_numpy(nodal_max(discr, "vol", ts_field))

        return ts_field, cfl, min(t_remaining, dt)

    def my_get_alpha(state, alpha):
        """Scale alpha by the element characteristic length and velocity"""
        return alpha*state.speed*length_scales

    def get_sc_scale():
        return alpha_sc * length_scales

    get_sc_scale_compiled = actx.compile(get_sc_scale)

    sc_scale = get_sc_scale_compiled()

    def limit_species_source(cv, pressure, temperature, species_enthalpies):
        spec_lim = make_obj_array([
            bound_preserving_limiter(discr, cv.species_mass_fractions[i],
                                     mmin=0.0, mmax=1.0, modify_average=True)
            for i in range(nspecies)
        ])

        # limit the sum to 1.0
        #spec_lim = spec_lim/actx.np.sum(spec_lim)
        aux = cv.mass*0.0
        for i in range(nspecies):
            aux = aux + spec_lim[i]
        spec_lim = spec_lim/aux

        kin_energy = 0.5*np.dot(cv.velocity, cv.velocity)

        mass_lim = eos.get_density(pressure=pressure, temperature=temperature,
                                   species_mass_fractions=spec_lim)

        energy_lim = mass_lim*(
            gas_model.eos.get_internal_energy(temperature,
                                              species_mass_fractions=spec_lim)
            + kin_energy
        )

        mom_lim = mass_lim*cv.velocity

        cv_limited = make_conserved(dim=dim, mass=mass_lim, energy=energy_lim,
                                    momentum=mom_lim,
                                    species_mass=mass_lim*spec_lim)

        spec_lim_source = species_limit_sigma*(spec_lim - cv.species_mass_fractions)
        energy_lim_source = 0.*cv.mass
        for i in range(nspecies):
            energy_lim_source = (energy_lim_source +
                spec_lim_source[i]*cv.mass*species_enthalpies[i])

        cv_limited_source = make_conserved(
            dim=dim, mass=cv.mass, energy=energy_lim_source, momentum=cv.momentum,
            species_mass=cv.mass*spec_lim_source)

        return make_obj_array([cv_limited, cv_limited_source])

    limit_species_source_compiled = actx.compile(limit_species_source)

    def my_pre_step(step, t, dt, state):

        try:
            if logmgr:
                logmgr.tick_before()

            do_viz = check_step(step=step, interval=nviz)
            do_restart = check_step(step=step, interval=nrestart)
            do_health = check_step(step=step, interval=nhealth)
            do_status = check_step(step=step, interval=nstatus)

            if any([do_viz, do_restart, do_health, do_status]):
                cv, tseed = state

                limit_species_rhs = 0.*cv
                if limit_species:
                    fluid_state = create_fluid_state(cv=cv,
                                                     temperature_seed=tseed,
                                                     smoothness=no_smoothness)
                    cv, limit_species_rhs = limit_species_source_compiled(
                        cv=cv, pressure=fluid_state.pressure,
                        temperature=fluid_state.temperature,
                        species_enthalpies=fluid_state.species_enthalpies)

                if use_av == 0 or use_av == 1:
                    fluid_state = create_fluid_state(cv=cv,
                                                     smoothness=no_smoothness,
                                                     temperature_seed=tseed)
                elif use_av == 2:
                    smoothness = smoothness_indicator(discr, cv.mass,
                                                      kappa=kappa_sc, s0=s0_sc)
                    force_evaluation(actx, smoothness)
                    fluid_state = create_fluid_state(cv=cv,
                                                     smoothness=smoothness,
                                                     temperature_seed=tseed)
                elif use_av == 3:
                    fluid_state = create_fluid_state(cv=cv,
                                                     smoothness=no_smoothness,
                                                     temperature_seed=tseed)

                    # recompute the dv to have the correct smoothness
                    # this is forcing a recompile, only do it at dump time
                    # not sure why the compiled version of grad_cv doesn't work
                    if do_viz:
                        # use the divergence to compute the smoothness field
                        force_evaluation(actx, t)
                        grad_cv = grad_cv_operator(
                            discr, gas_model, boundaries, fluid_state,
                            time=t, quadrature_tag=quadrature_tag)
                        # grad_cv = grad_cv_operator_compiled(fluid_state,
                        #                                     time=t)
                        smoothness = compute_smoothness(cv=cv,
                                                        dv=fluid_state.dv,
                                                        grad_cv=grad_cv)

                        fluid_state = create_fluid_state(cv=cv,
                                                         smoothness=smoothness,
                                                         temperature_seed=tseed)
                        """
                        # avoid recomputation of temperature
                        force_evaluation(actx, smoothness)
                        new_dv = replace(fluid_state.dv, smoothness=smoothness)
                        fluid_state = replace(fluid_state, dv=new_dv)
                        new_tv = gas_model.transport.transport_vars(
                            cv=cv, dv=new_dv, eos=gas_model.eos)
                        fluid_state = replace(fluid_state, tv=new_tv)
                        """

                # if the time integrator didn't force_eval, do so now
                if not force_eval:
                    fluid_state = force_evaluation(actx, fluid_state)
                dv = fluid_state.dv

                alpha_field = my_get_alpha(fluid_state, alpha_sc)
                ts_field, cfl, dt = my_get_timestep(t, dt, fluid_state, alpha_field)

            if do_health:
                health_errors = global_reduce(my_health_check(fluid_state), op="lor")
                if health_errors:
                    if rank == 0:
                        logger.warning("Fluid solution failed health check.")
                    raise MyRuntimeError("Failed simulation health check.")

            if do_status:
                my_write_status(dt=dt, cfl=cfl, dv=dv, cv=cv)

            if do_restart:
                my_write_restart(step=step, t=t, cv=cv, temperature_seed=tseed)

            if do_viz:
                my_write_viz(step=step, t=t, fluid_state=fluid_state,
                             ts_field=ts_field, alpha_field=alpha_field)

        except MyRuntimeError:
            if rank == 0:
                logger.error("Errors detected; attempting graceful exit.")
            my_write_viz(step=step, t=t, fluid_state=fluid_state, ts_field=ts_field,
                         alpha_field=alpha_field)
            my_write_restart(step=step, t=t, cv=cv, temperature_seed=tseed)
            raise

        return state, dt

    def my_post_step(step, t, dt, state):
        if logmgr:
            set_dt(logmgr, dt)
            logmgr.tick_after()
        return state, dt

    def my_rhs(t, state):
        cv, tseed = state

        limit_species_rhs = 0*cv
        if limit_species:
            fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                           temperature_seed=tseed,
                                           smoothness=no_smoothness)
            cv, limit_species_rhs = limit_species_source(
                cv=cv, pressure=fluid_state.pressure,
                temperature=fluid_state.temperature,
                species_enthalpies=fluid_state.species_enthalpies)

        if use_av == 0 or use_av == 1:
            fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                           temperature_seed=tseed,
                                           smoothness=no_smoothness)
            """
            # This should be equivalent and faster, but increases the comp time
            if not limit_species:
                fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                               temperature_seed=tseed,
                                               smoothness=no_smoothness)
            else:
                fluid_state = replace(fluid_state, cv=cv)
            """

        elif use_av == 2:
            smoothness = smoothness_indicator(
                discr=discr, u=cv.mass, kappa=kappa_sc, s0=s0_sc)
            fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                           temperature_seed=tseed,
                                           smoothness=smoothness)
        elif use_av == 3:
            fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                           temperature_seed=tseed,
                                           smoothness=no_smoothness)

            # use the divergence to compute the smoothness field
            grad_fluid_cv = grad_cv_operator(
                discr, gas_model, boundaries, fluid_state,
                time=t, quadrature_tag=quadrature_tag)
            smoothness = compute_smoothness(cv=cv, dv=fluid_state.dv,
                                            grad_cv=grad_fluid_cv)

            fluid_state = make_fluid_state(cv=cv, gas_model=gas_model,
                                           temperature_seed=tseed,
                                           smoothness=smoothness)
            """
            # This should be equivalent and faster?
            # But the compilation is super slow
            new_dv = replace(fluid_state.dv, smoothness=smoothness)
            fluid_state = replace(fluid_state, dv=new_dv)
            new_tv = gas_model.transport.transport_vars(
                cv=cv, dv=new_dv, eos=gas_model.eos)
            fluid_state = replace(fluid_state, tv=new_tv)
            """

        # Temperature seed RHS (keep tseed updated)
        tseed_rhs = fluid_state.temperature - tseed

        # Steps common to NS and AV (and wall model needs grad(temperature))
        operator_fluid_states = make_operator_fluid_states(
            discr, fluid_state, gas_model, boundaries, quadrature_tag)

        if use_av != 3:
            grad_fluid_cv = grad_cv_operator(
                discr, gas_model, boundaries, fluid_state,
                quadrature_tag=quadrature_tag,
                operator_states_quad=operator_fluid_states)

        # Fluid CV RHS contributions
        ns_rhs = \
            ns_operator(discr, state=fluid_state, time=t, boundaries=boundaries,
                gas_model=gas_model, quadrature_tag=quadrature_tag,
                inviscid_numerical_flux_func=inviscid_numerical_flux_func,
                operator_states_quad=operator_fluid_states,
                grad_cv=grad_fluid_cv)

        chem_rhs = 0*cv
        if use_combustion:  # conditionals evaluated only once at compile time
            chem_rhs =  \
                eos.get_species_source_terms(cv, temperature=fluid_state.temperature)

        av_rhs = 0*cv
        if use_av == 1:
            alpha_field = sc_scale * fluid_state.speed
            av_rhs = \
                av_laplacian_operator(discr, fluid_state=fluid_state,
                    boundaries=boundaries, gas_model=gas_model,
                    time=t, alpha=alpha_field, s0=s0_sc,
                    kappa=kappa_sc, quadrature_tag=quadrature_tag,
                    operator_states_quad=operator_fluid_states)

        sponge_rhs = 0*cv
        if use_sponge:
            sponge_rhs = _sponge_source(cv=cv)

        ignition_rhs = 0*cv
        if use_ignition:
            ignition_rhs = ignition_source(x_vec=x_vec, cv=cv, time=t)

        cv_rhs = (ns_rhs + chem_rhs + av_rhs + sponge_rhs + ignition_rhs +
                  limit_species_rhs)
        return make_obj_array([cv_rhs, tseed_rhs])

    current_dt = get_sim_timestep(discr, current_state, current_t, current_dt,
                                  current_cfl, t_final, constant_cfl)

    current_step, current_t, stepper_state = \
        advance_state(rhs=my_rhs, timestepper=timestepper,
                      pre_step_callback=my_pre_step,
                      post_step_callback=my_post_step,
                      istep=current_step, dt=current_dt,
                      t=current_t, t_final=t_final,
                      force_eval=force_eval,
                      state=make_obj_array([current_state.cv, temperature_seed]))

    current_cv, tseed = stepper_state

    # Dump the final data
    if rank == 0:
        logger.info("Checkpointing final state ...")

    limit_species_rhs = 0*current_state.cv
    if limit_species:
        fluid_state = create_fluid_state(cv=current_state.cv,
                                         temperature_seed=tseed,
                                         smoothness=no_smoothness)
        cv, limit_species_rhs = limit_species_source(
            cv=current_state.cv, pressure=fluid_state.pressure,
            temperature=fluid_state.temperature,
            species_enthalpies=fluid_state.species_enthalpies)

    if use_av == 0 or use_av == 1:
        current_state = create_fluid_state(cv=current_cv,
                                           smoothness=no_smoothness,
                                           temperature_seed=tseed)
    elif use_av == 2:
        smoothness = smoothness_indicator(discr, current_cv.mass,
                                          kappa=kappa_sc, s0=s0_sc)
        current_state = create_fluid_state(cv=current_cv,
                                           temperature_seed=tseed,
                                           smoothness=smoothness)
    elif use_av == 3:
        current_state = create_fluid_state(cv=current_cv,
                                           temperature_seed=tseed,
                                           smoothness=no_smoothness)

        # use the divergence to compute the smoothness field
        current_grad_cv = grad_cv_operator(
            discr, gas_model, boundaries, current_state, time=current_t,
            quadrature_tag=quadrature_tag)
        # smoothness = compute_smoothness_compiled(current_cv, grad_cv)
        smoothness = compute_smoothness(cv=current_cv, dv=current_state.dv,
                                        grad_cv=current_grad_cv)

        current_state = create_fluid_state(cv=current_cv,
                                           temperature_seed=tseed,
                                           smoothness=smoothness)

        """
        new_dv = replace(current_state.dv, smoothness=smoothness)
        current_state = replace(current_state, dv=new_dv)
        """

    final_dv = current_state.dv
    alpha_field = my_get_alpha(current_state, alpha_sc)
    ts_field, cfl, dt = my_get_timestep(t=current_t, dt=current_dt,
                                        state=current_state, alpha=alpha_field)
    my_write_status(dt=dt, cfl=cfl, cv=current_state.cv, dv=final_dv)

    my_write_viz(step=current_step, t=current_t, fluid_state=current_state,
                 ts_field=ts_field, alpha_field=alpha_field)
    my_write_restart(step=current_step, t=current_t, cv=current_state.cv,
                     temperature_seed=tseed)

    if logmgr:
        logmgr.close()
    elif use_profiling:
        print(actx.tabulate_profiling_data())

    finish_tol = 1e-16
    assert np.abs(current_t - t_final) < finish_tol


if __name__ == "__main__":

    logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
        level=logging.INFO)

    import argparse
    parser = argparse.ArgumentParser(
        description="MIRGE-Com Isentropic Nozzle Driver")
    parser.add_argument("-r", "--restart_file", type=ascii, dest="restart_file",
                        nargs="?", action="store", help="simulation restart file")
    parser.add_argument("-t", "--target_file", type=ascii, dest="target_file",
                        nargs="?", action="store", help="simulation target file")
    parser.add_argument("-i", "--input_file", type=ascii, dest="input_file",
                        nargs="?", action="store", help="simulation config file")
    parser.add_argument("-c", "--casename", type=ascii, dest="casename", nargs="?",
                        action="store", help="simulation case name")
    parser.add_argument("--profile", action="store_true", default=False,
                        help="enable kernel profiling [OFF]")
    parser.add_argument("--log", action="store_true", default=False,
                        help="enable logging profiling [ON]")
    parser.add_argument("--lazy", action="store_true", default=False,
                        help="enable lazy evaluation [OFF]")
    parser.add_argument("--overintegration", action="store_true",
        help="use overintegration in the RHS computations")

    args = parser.parse_args()

    # for writing output
    casename = "isolator"
    if args.casename:
        print(f"Custom casename {args.casename}")
        casename = args.casename.replace("'", "")
    else:
        print(f"Default casename {casename}")

    lazy = args.lazy
    if args.profile:
        if lazy:
            raise ValueError("Can't use lazy and profiling together.")

    from grudge.array_context import get_reasonable_array_context_class
    actx_class = get_reasonable_array_context_class(lazy=lazy, distributed=True)

    restart_filename = None
    if args.restart_file:
        restart_filename = (args.restart_file).replace("'", "")
        print(f"Restarting from file: {restart_filename}")

    target_filename = None
    if args.target_file:
        target_filename = (args.target_file).replace("'", "")
        print(f"Target file specified: {target_filename}")

    input_file = None
    if args.input_file:
        input_file = args.input_file.replace("'", "")
        print(f"Ignoring user input from file: {input_file}")
    else:
        print("No user input file, using default values")

    print(f"Running {sys.argv[0]}\n")
    main(restart_filename=restart_filename, target_filename=target_filename,
         user_input_file=input_file,
         use_profiling=args.profile, use_logmgr=args.log,
         use_overintegration=args.overintegration, lazy=lazy,
         actx_class=actx_class, casename=casename)

# vim: foldmethod=marker
