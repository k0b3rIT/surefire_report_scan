#!/bin/bash
#
# This script parses the results of the surefire run
# by bkondrat


#set -u -e


ALL_TEST=0
ALL_FAIL=0
ALL_SKIPPED=0
ALL_ERRORS=0

VERBOSE_ARGUMENT="-q"
IS_VERBOSE=1

#$1 testCaseName
#$2 testResultXmlFile
printTestResult() {

  HAS_FAIL=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/failure" $2)
  IS_SKIPPED=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/skipped" $2)
  HAS_ERROR=$(xmlstarlet sel -t -c "testsuite/testcase[@name='$1']/error" $2)

  TEST_NAME="[32m ${1} [0m"

  if [ ! -z "$HAS_FAIL" ]; then
    TEST_NAME="[31m ${1} [0m"
  elif [  ! -z "$IS_SKIPPED" ]; then
    TEST_NAME="[36m ${1} [0m"
  elif [ ! -z "$HAS_ERROR" ]; then
    TEST_NAME="[35m ${1} [0m"
  fi
  
  if [ $IS_VERBOSE == 1 ] || [ ! -z "$HAS_FAIL" ] || [  ! -z "$IS_SKIPPED" ] || [ ! -z "$HAS_ERROR" ];then
    if [ $IS_VERBOSE == 0 ];then
      echo [33m$(xmlstarlet sel -t -v "testsuite/@name" $2) [0m
    fi
    echo "        "$TEST_NAME
  fi
}

#$1 testResultXmlFile
printResultsFromFile() {
    
    [ $IS_VERBOSE == 1 ] && echo [33m$(xmlstarlet sel -t -v "testsuite/@name" $1) [0m
    #echo "-------------------------------------------"

    Failures=$(xmlstarlet sel -t -v "testsuite/@failures" $1)

    ALL_FAIL=$(($ALL_FAIL+$Failures))

    if [ "$Failures" != "0" ]; then
      Failures="[31m ${Failures} [0m"
    fi


    NUM_OF_ERRORS=$(xmlstarlet sel -t -v "testsuite/@errors" $1)
    NUM_OF_SKIPPED=$(xmlstarlet sel -t -v "testsuite/@skipped" $1)
    NUM_OF_TESTS=$(xmlstarlet sel -t -v "testsuite/@tests" $1)

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



CLI_ARGUMENTS=( "$@" )

for element in ${CLI_ARGUMENTS[@]}
    do
      [[ "$element" == "$VERBOSE_ARGUMENT" ]] && IS_VERBOSE=0 && break     
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



