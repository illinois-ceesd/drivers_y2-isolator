#!/bin/bash
mpirun -n 1 python -u -O -m mpi4py isolator.py -i run_params.yaml -r restart_data/mirgecom-000010
