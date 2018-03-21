#!/bin/bash
#
# This script parses the results of the surefire run
# by bkondrat


ALL_TEST=0
ALL_FAIL=0
ALL_SKIPPED=0
ALL_ERRORS=0

VERBOSE_ARGUMENT="-q"
PRINT_FILENAME_FOR_FAILED_TEST_ARGUMENT="-d"
PRINT_RERUN_COMMAND_ARGUMENT="-r"

PRINT_RERUN=0
DETAILED_ERROR=0
IS_VERBOSE=1


TESTS_TO_RERUN=()

#$1 testCaseName
#$2 testResultXmlFile
printTestResult() {

  HAS_FAIL=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/failure" $2)
  IS_SKIPPED=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/skipped" $2)
  HAS_ERROR=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/error" $2)

  TEST_NAME="[32m ${1} [0m"

  SUCCESS=1

  if [ ! -z "$HAS_FAIL" ]; then
    SUCCESS=0
    TEST_NAME="[31m ${1} [0m"
  elif [  ! -z "$IS_SKIPPED" ]; then
    SUCCESS=0
    TEST_NAME="[36m ${1} [0m"
  elif [ ! -z "$HAS_ERROR" ]; then
    SUCCESS=0
    TEST_NAME="[35m ${1} [0m"
  fi


  if [ $SUCCESS == 0 ];then
    SUIT=$(xmlstarlet sel -t -v "testsuite/@name" $2)
    SUIT=$(echo $SUIT | awk -F'.' '{print $NF}')
    if [[ $1 = *"."* ]]; then
      COMMAND="${SUIT}"
    else
      COMMAND="${SUIT}#${1}"
    fi
    TESTS_TO_RERUN+=($COMMAND)
  fi

  
  if [ $IS_VERBOSE == 1 ] || [ $SUCCESS == 0 ];then #if verbose or testfail
    echo "        "$TEST_NAME
  fi
}



#$1 testResultXmlFile
printResultsFromFile() {
    

    Failures=$(xmlstarlet sel -t -v "testsuite/@failures" $1)

    ALL_FAIL=$(($ALL_FAIL+$Failures))

    if [ "$Failures" != "0" ]; then
      Failures="[31m ${Failures} [0m"
    fi

    NUM_OF_FAILURES=$(xmlstarlet sel -t -v "testsuite/@failures" $1)
    NUM_OF_ERRORS=$(xmlstarlet sel -t -v "testsuite/@errors" $1)
    NUM_OF_SKIPPED=$(xmlstarlet sel -t -v "testsuite/@skipped" $1)
    NUM_OF_TESTS=$(xmlstarlet sel -t -v "testsuite/@tests" $1)

    HAS_FAILED=0

    if (( $NUM_OF_FAILURES > 0 )) || (( $NUM_OF_ERRORS > 0 )) || (( $NUM_OF_SKIPPED > 0 ));then
      HAS_FAILED=1
    fi

    SUIT=$(xmlstarlet sel -t -v "testsuite/@name" $1)
    SUIT=$(echo $SUIT | awk -F'.' '{print $NF}')

    if [ $IS_VERBOSE == 1 ] || [ $HAS_FAILED == 1 ];then
      
      if [ $DETAILED_ERROR == 1 ] && [ $HAS_FAILED == 1 ];then
        echo [33m$SUIT[0m"       "$1
      else
        echo [33m$SUIT[0m
      fi

    fi

    ALL_TEST=$(($ALL_TEST+$NUM_OF_TESTS))
    ALL_ERRORS=$(($ALL_ERRORS+$NUM_OF_ERRORS))
    ALL_SKIPPED=$(($ALL_SKIPPED+$NUM_OF_SKIPPED))
    
    [ $IS_VERBOSE == 1 ] && echo "    Run:" $NUM_OF_TESTS "Failures:" $Failures "Errors:" $NUM_OF_ERRORS "Skipped:" $NUM_OF_SKIPPED
    
    TEST_RESULT=$(xmlstarlet sel -t -v "testsuite/testcase/@name" $1)
    for element in $TEST_RESULT
      do
        printTestResult "$element" "$1"
      done

    [ $IS_VERBOSE == 1 ] && echo ""
}

printResultsFromFolder() {
    XML_FILES=$(find $1 -name '*.xml')
    for element in $XML_FILES
      do
        printResultsFromFile "$element"  
      done
}

printRerunCommand() {
  #REPORT_SCAN_MVN="mvn clean install -Dtest='{tests}' -Pitests,hadoop-2 -Dmaven.surefire.plugin.version=2.20.1"

  if [[ -z "${REPORT_SCAN_MVN}" ]]; then
    BASE_COMMAND="{tests}"
  else
    BASE_COMMAND=${REPORT_SCAN_MVN}
  fi

  CONCATED_TESTS=""
  for element in ${TESTS_TO_RERUN[@]}
    do
      CONCATED_TESTS=$CONCATED_TESTS$element","    
    done

  CONCATED_TESTS=$(echo $CONCATED_TESTS | sed 's/,$//') #Remove last ,

  COMMAND=$(echo $BASE_COMMAND | sed -e "s/{tests}/${CONCATED_TESTS}/")

  [ ! -z "$CONCATED_TESTS" ] && echo $COMMAND
  
}



CLI_ARGUMENTS=( "$@" )

for element in ${CLI_ARGUMENTS[@]}
    do
      [[ "$element" == "$VERBOSE_ARGUMENT" ]] && IS_VERBOSE=0
      [[ "$element" == "$PRINT_FILENAME_FOR_FAILED_TEST_ARGUMENT" ]] && DETAILED_ERROR=1
      [[ "$element" == "$PRINT_RERUN_COMMAND_ARGUMENT" ]] && PRINT_RERUN=1    
    done


#Find surefire report folders in current dir
REPORT_FOLDERS=$(find . -name 'surefire-reports')

for element in $REPORT_FOLDERS
    do
      printResultsFromFolder "$element"  
    done



echo "[34m-----------------------------------------------------------"
echo "    S U M M A R Y"
echo "-----------------------------------------------------------[0m"
echo "Total run:[32m" $ALL_TEST "[0mFailures:[31m" $ALL_FAIL "[0mErrors:[35m" $ALL_ERRORS "[0mSkipped:[36m" $ALL_SKIPPED "[0m"
echo ""

if [ $PRINT_RERUN == 1 ]; then
  printRerunCommand
fi



