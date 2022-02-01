#! /bin/bash --login
#BSUB -nnodes 16
#BSUB -G uiuc
#BSUB -W 720
#BSUB -J Y2_iso_2d_halfX
#BSUB -q pbatch
#BSUB -o runOutput.txt
#BSUB -e runOutput.txt

module load gcc/7.3.1
module load spectrum-mpi
conda deactivate
conda activate mirgeDriver.Y2isolator-parallel
export PYOPENCL_CTX="port:tesla"
#export PYOPENCL_CTX="0:2"
jsrun_cmd="jsrun -g 1 -a 1 -n 64"
export XDG_CACHE_HOME="/tmp/$USER/xdg-scratch"
export POCL_CACHE_DIR_ROOT="/tmp/$USER/pocl-cache"
$jsrun_cmd js_task_info
$jsrun_cmd bash -c 'POCL_CACHE_DIR=$POCL_CACHE_DIR_ROOT/$$ python -O -u -m mpi4py ./isolator.py -i run_params.yaml --log --lazy > mirge-1.out'
