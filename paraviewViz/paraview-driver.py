# To run with MPI, use mpiexec -n 4 pvbatch --mpi --symmetric paraview-driver.py [arguments]

# Import Paraview functions 
from mpi4py import MPI
import sys
import math
from contour import *
from slice import *

# Command-line arguments
# fix these to be order independent ...
dir = sys.argv[1]
prefix = sys.argv[2]
startIterGlobal = int(sys.argv[3])
if (len(sys.argv) == 4):
  skipIter = 1
  stopIterGlobal = startIterGlobal
elif (len(sys.argv) == 6):
  skipIter = int(sys.argv[4])
  stopIterGlobal = int(sys.argv[5])
else:
  print('There are two possible argument lists:')
  print('3 arguments: (1) dir, (2) prefix, (3) iter')
  print('5 arguments: (1) dir, (2) prefix, (3) startIter, (4) skipIter, (5) stopIter.')
  print('Aborting.')
  exit()

# Divide work evenly, splitting remainder
#comm = MPI.COMM_WORLD
#nProcs = comm.Get_size()
#rank = comm.Get_rank()
#nIterGlobal = int( (stopIterGlobal - startIterGlobal)/skipIter + 1 )
#nIter = math.floor(nIterGlobal/nProcs)
#remainder = nIterGlobal % nProcs
#if (rank < remainder):
  #startIter = (nIter+1) * rank
  #stopIter = startIter + nIter
#else:
  #startIter = nIter*rank + remainder
  #stopIter = startIter + (nIter-1)

## Scale by skipIter, shift by startIterGlobal
#nIter = stopIter - startIter + 1
#startIter = startIter*skipIter + startIterGlobal
#stopIter = stopIter*skipIter + startIterGlobal

# If not running with MPI
startIter = startIterGlobal
stopIter = stopIterGlobal

# Announce
#if (rank == 0):
  #print('PARAVIEW DRIVER: Splitting global iter = [{:09d} : {:d} : {:09d}]'.
    #format(startIterGlobal,skipIter,stopIterGlobal))
#comm.barrier()
#for p in range(0,nProcs):
  #if (rank == p):
    #print('  rank={}: nIter = {}, iter = [{:09d} : {:d} : {:09d}]'.
      #format(rank,nIter,startIter,skipIter,stopIter))
  #comm.barrier()

# Loop
#print('PARAVIEW DRIVER: Making images for iter = [{:09d} : {:d} : {:09d}]'.
  #format(startIterGlobal,skipIter,stopIterGlobal))
if (startIter == stopIter):
  iter = [startIter]
else:
  iter = range(startIter,stopIter,skipIter)

for n in iter:

  if (prefix == 'y2-full'): # sample mirgecom run
    # camera location (x, y, zoom)
    camera = [0.6, 0.01, 0.060]
    pixels = [1400,200]
    simpleSlice(dir, n, 'cv_mass', 0.01, 0.1, camera, invert=1, logScale=1,
      colorScheme='cool to warm', prefix=prefix, pixels=pixels, cbTitle='Density [kg/m^3]')

    simpleSlice(dir, n, 'dv_pressure', 1000.0, 10000, camera, invert=1,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Pressure [Pa]')

    simpleSlice(dir, n, 'dv_temperature', 200.0, 1000, camera, invert=0,
      colorScheme='Black-Body Radiation', prefix=prefix, pixels=pixels, cbTitle='Temperature [K]')

    simpleSlice(dir, n, 'mach', 0.0, 3.5, camera, invert=0,
      colorScheme='Inferno (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Mach Number')

    simpleSlice(dir, n, 'mu', 0.0001, 0.1, camera, invert=0,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='viscosity (m^2/s)')
  elif (prefix == 'y2-cavity'): # Upstream arc-heater, full geometry
    # camera location (x, y, zoom)
    # camera location (bigger moves right, bigger moves up , smaller to zoom in)
    camera = [0.685, -0.005, 0.026]
    pixels = [1300,700]

    simpleSlice(dir, n, 'cv_mass', 0.02, 0.1, camera, invert=1, logScale=1,
      colorScheme='erdc_rainbow_dark', prefix=prefix, pixels=pixels, cbTitle='Density [kg/m^3]')

    simpleSlice(dir, n, 'dv_pressure', 1500.0, 10000, camera, invert=1,
      colorScheme='GREEN-WHITE_LINEAR', prefix=prefix, pixels=pixels, cbTitle='Pressure [Pa]')

    simpleSlice(dir, n, 'dv_temperature', 200.0, 1000, camera, invert=0,
      colorScheme='Black-Body Radiation', prefix=prefix, pixels=pixels, cbTitle='Temperature [K]')

    simpleSlice(dir, n, 'mach', 0.0, 3.5, camera, invert=0,
      colorScheme='Rainbow Desaturated', prefix=prefix, pixels=pixels, cbTitle='Mach Number')

    simpleSlice(dir, n, 'alpha', 0.0001, 0.1, camera, invert=0,
      colorScheme='Blue Orange (divergent)', prefix=prefix, pixels=pixels, cbTitle='artifical viscosity (m^2/s)')

    simpleSlice(dir, n, 'tagged_cells', 0.0, 1.0, camera, invert=0,
      colorScheme='erdc_marine2gold_BW', prefix=prefix, pixels=pixels, cbTitle='Tagged Elements')
  elif (prefix == 'y2-cavity-scalar'): # Upstream arc-heater, full geometry
    # camera location (x, y, zoom)
    # camera location (bigger moves right, bigger moves up , smaller to zoom in)
    camera = [0.685, -0.005, 0.026]
    pixels = [1300,700]

    simpleSlice(dir, n, 'cv_mass', 0.02, 0.1, camera, invert=1, logScale=1,
      colorScheme='cool to warm', prefix=prefix, pixels=pixels, cbTitle='Density [kg/m^3]')

    simpleSlice(dir, n, 'dv_pressure', 1500.0, 10000, camera, invert=1,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Pressure [Pa]')

    simpleSlice(dir, n, 'dv_temperature', 200.0, 1000, camera, invert=0,
      colorScheme='Black-Body Radiation', prefix=prefix, pixels=pixels, cbTitle='Temperature [K]')

    simpleSlice(dir, n, 'mach', 0.0, 3.5, camera, invert=0,
      colorScheme='Inferno (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Mach Number')

    simpleSlice(dir, n, 'mu', 0.0001, 0.1, camera, invert=0,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='viscosity (m^2/s)')

    simpleSlice(dir, n, 'Y_air', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Air Mass Fraction')

    simpleSlice(dir, n, 'Y_fuel', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')
  elif (prefix == 'y2-cavity-multi'): # Upstream arc-heater, full geometry
    # camera location (x, y, zoom)
    # camera location (bigger moves right, bigger moves up , smaller to zoom in)
    camera = [0.685, -0.005, 0.026]
    pixels = [1300,700]

    simpleSlice(dir, n, 'cv_mass', 0.02, 0.1, camera, invert=1, logScale=1,
      colorScheme='cool to warm', prefix=prefix, pixels=pixels, cbTitle='Density [kg/m^3]')

    simpleSlice(dir, n, 'dv_pressure', 1500.0, 10000, camera, invert=1,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Pressure [Pa]')

    simpleSlice(dir, n, 'dv_temperature', 200.0, 2500, camera, invert=0,
      colorScheme='Black-Body Radiation', prefix=prefix, pixels=pixels, cbTitle='Temperature [K]')

    simpleSlice(dir, n, 'mach', 0.0, 3.5, camera, invert=0,
      colorScheme='Inferno (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Mach Number')

    simpleSlice(dir, n, 'mu', 0.0001, 0.1, camera, invert=0,
      colorScheme='Viridis (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='viscosity (m^2/s)')

    simpleSlice(dir, n, 'Y_O2', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Air Mass Fraction')

    simpleSlice(dir, n, 'Y_C2H4', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')

    simpleSlice(dir, n, 'Y_CO', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')

    simpleSlice(dir, n, 'Y_H2O', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')

    simpleSlice(dir, n, 'Y_CO2', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')

    simpleSlice(dir, n, 'Y_H2', 0.0, 1.0, camera, invert=0,
      colorScheme='Plasma (matplotlib)', prefix=prefix, pixels=pixels, cbTitle='Fuel Mass Fraction')

  else:
    print('Unrecognized prefix: {}'.format(prefix))

# Announce
print('PARAVIEW DRIVER: Done.\n')
