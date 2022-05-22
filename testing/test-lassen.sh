#!/bin/bash

EMIRGE_HOME=$1
TESTING_RESULTS_FILE=$2
TESTING_LOG_FILE=$3

printf "Isolator testing suite running on Lassen:\n"
printf " - Emirge home: ${EMIRGE_HOME}\n"
printf " - Testing results file: ${TESTING_RESULTS_FILE}\n"
printf " - Testing log file: ${TESTING_LOG_FILE}\n"

# Dispatch all the isolator-based tests from this script.
# (1) 3d injection with mixture EOS (smoke_test_injection_3d)
# - 1 GPU
printf "Testing serial injection 3D with combustion... \n"
./test-serial-3d-combustion-lassen.sh ${EMIRGE_HOME} ${TESTING_LOG_FILE} ${TESTING_RESULTS_FILE} "serial-3d-combustion"

# Next - do parallel isolator tests (waits on parallel capability)
# - 2 GPUs
# - 4 GPUs
