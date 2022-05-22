#!/bin/bash

EMIRGE_HOME=$1
TESTING_LOG_FILE=$2
TESTING_RESULTS_FILE=$3
TEST_NAME=$4

origin=$(pwd)
BATCH_SCRIPT_NAME="${TEST_NAME}-lassen-batch.sh"
running_dir="${origin}/../smoke_test_injection_3d"

printf "Running Lassen batch script Test ($TEST_NAME):\n"
printf " Origin directory: ${origin}\n"
printf " Running directory: ${running_dir}\n"
printf " Emirge home: ${EMIRGE_HOME}\n"
printf " Log file: ${TESTING_LOG_FILE}\n"
printf " Results file: ${TESTING_RESTULS_FILE}\n"

# Most of the batch script stuff is boiler-plate
# There is a short test-specific section marked below

# - Generate a batch script to run the tests on a Lassen compute node
# TODO: Generalize and create a utilty for generating the common batch stuff
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
rm -f ${origin}/${TEST_NAME}-testing-done
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

# VVVVVVVVV Test specific section VVVVVVVVVV

echo "*** Running isolator in $running_dir ..."
echo "Init phase...\n"
\$serial_spawner_cmd python -O -u -m mpi4py ./isolator_injection_init.py -i run_params.yaml --lazy
echo "Run phase...\n"
\$serial_spawner_cmd python -O -u -m mpi4py ./isolator_injection_run.py -i run_params.yaml -r restart_data/isolator_init-000000 --log --lazy
test_result="0"
if [ ! -f restart_data/isolator-000020-0000.pkl ];
then
   test_result="1"
fi

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

printf "${TEST_NAME}: \${test_result}\n" >> ${TESTING_RESULTS_FILE}

touch ${origin}/${TEST_NAME}-testing-done
exit \$numfail

EOF

# ---- Submit the batch script and wait for the job to finish
rm -f ${TEST_NAME}-testing-done
chmod +x ${BATCH_SCRIPT_NAME}
bsub ${BATCH_SCRIPT_NAME}

# ---- Wait 15 minutes right off the bat
printf "Waiting for batch script to finish."
sleep 900
iwait=0
while [ ! -f ./${TEST_NAME}-testing-done ]; do 
    iwait=$((iwait+1))
    if [ "$iwait" -gt 89 ]; then # give up after almost 1 hours
        printf "Timed out waiting on batch job.\n"
        exit 1 # skip the rest of the script
    fi
    printf "."
    sleep 30
done
printf "\n"
sleep 30  # give the batch system time to spew its junk into the log
printf "Output from Lassen batch job for test (${TEST_NAME}):\n" >> ${TESTING_LOG_FILE}
cat *.out >> ${TESTING_LOG_FILE}
date >> ${TESTING_LOG_FILE}
rm *.out
date
