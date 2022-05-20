#!/bin/bash

EMIRGE_HOME=$1
TESTING_RESULTS_FILE=$2
TESTING_LOG_FILE=$3

printf "Testing serial injection 3D with mixture EOS... \n"
./test-serial-isolator-3d-mixture-lassen.sh ${EMIRGE_HOME}
return_code=$?
printf "Serial 3D mixture script return code: ${return_code}"
cat serial-isolator-3d-mixture-output >> ${TESTING_LOG_FILE}
test_result=$(cat serial-injection-3d-mixture-result)
printf "serial-isolator-3d-mixture: ${test_result}\n" >> ${TESTING_RESULTS_FILE}
# Next - do parallel isolator tests (waits on parallel capability)
