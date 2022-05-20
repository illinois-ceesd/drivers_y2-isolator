#!/bin/bash

EMIRGE_HOME=$1
origin=$(pwd)
# EXAMPLES_HOME=$2
# examples_dir=${1-$origin}
BATCH_SCRIPT_NAME="serial-3d-mixture-lassen-batch.sh"
running_dir="${origin}/../smoke_test_injection_3d"

rm -rf ${BATCH_SCRIPT_NAME}
cat <<EOF > ${BATCH_SCRIPT_NAME}
#!/bin/bash

#BSUB -nnodes 1
#BSUB -G uiuc
#BSUB -W 60
#BSUB -q pdebug

printf "Running with EMIRGE_HOME=${EMIRGE_HOME}\n"

source "${EMIRGE_HOME}/config/activate_env.sh"
export PYOPENCL_CTX="port:tesla"
export XDG_CACHE_HOME="/tmp/$USER/xdg-scratch"
rm -rf \$XDG_CACHE_HOME
rm -f ${origin}/isolator-testing-done
which python
conda env list
env
env | grep LSB_MCPU_HOSTS

serial_spawner_cmd="jsrun -g 1 -a 1 -n 1"
parallel_spawner_cmd="jsrun -g 1 -a 1 -n 2"

set -o nounset

rm -f *.vtu *.pvtu

declare -i numfail=0
declare -i numsuccess=0

cd ${running_dir}

echo "*** Running isolator in $running_dir ..."
echo "Init phase...\n"
\$serial_spawner_cmd python -O -u -m mpi4py ./isolator_injection_init.py -i run_params.yaml --lazy
echo "Run phase...\n"
\$serial_spawner_cmd python -O -u -m mpi4py ./isolator_injection_run.py -i run_params.yaml -r restart_data/isolator_init-000000 --log --lazy
test_result = \$?

rm -rf ${origin}/serial-isolator-3d-mixture-result
printf "\${test_result}\n" > ${origin}/serial-isolator-3d-mixture-result

touch ${origin}/isolator-testing-done
exit \$numfail

EOF

rm -f isolator-testing-done
chmod +x ${BATCH_SCRIPT_NAME}
# ---- Submit the batch script and wait for the job to finish
bsub ${BATCH_SCRIPT_NAME}
# ---- Wait 10 minutes right off the bat
sleep 600
iwait=0
while [ ! -f ./isolator-testing-done ]; do 
    iwait=$((iwait+1))
    if [ "$iwait" -gt 89 ]; then # give up after almost 1 hours
        printf "Timed out waiting on batch job.\n"
        exit 1 # skip the rest of the script
    fi
    sleep 30
done

sleep 30  # give the batch system time to spew its junk into the log
rm -rf serial-isolator-3d-mixture-output
cat *.out > serial-isolator-3d-mixture-output
date >> serial-isolator-3d-mixture-output
rm *.out
date
