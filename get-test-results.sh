#!/bin/bash

function displayHelp {
  printf "usage: ./get-test-results.sh [OPTIONS]
          -h, --help
            Display help
          [REQUIRED]
          -v, --version <version>
            Git version number generated by current build  
          [REQUIRED]
          -n, --namespace <namespace>
            Namespace from which to get the results from
          [OPTIONAL]
          -d, --dir <path>
            Absolute path to a directory where all test results are stored in the allure container
            Defaults to $resultsDir
          [OPTIONAL]
          -t, --timeout <number of seconds>
            Amount of seconds to keep trying to grab the latest results for before giving up
            Defaults to $timeout
          "
  exit
}

# Option strings
SHORT="hv:n:d:t:"
LONG="help,version:,namespace:,dir:,timeout:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -v | --version )
      version="$2"
      shift 2
      ;;
    -n | --namespace )
      namespace="$2"
      shift 2
      ;;
    -d | --dir )
      resultsDir="$2"
      shift 2
      ;;
    -t | --timeout )
      timeout="$2"
      shift 2
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

# Default values
timeout=600
resultsDir="/app/allure-results"
allurePodName=$(kubectl get pod -l app.kubernetes.io/name=allure -o jsonpath="{.items[0].metadata.name}" -n $namespace)

if [ -z ${version+x} ] || [ -z ${namespace+x} ]; then   
  echo "Required values are missing!"

  displayHelp
  exit 1
fi

echo "Waiting for any test results for build $version..."
n=0
#TODO: same flow, but make sure we have the report from this build from all ac-tests suites and copy them over to ./results
until [ -n "$recentTestResult" ] || [ "$n" -ge "$timeout" ]; do
  sleep 5
  n=$((n+5)) 
  recentTestResult=$(kubectl exec $allurePodName -n $namespace -- sh -c "cd $resultsDir && ls -t *$version-*.trx | awk 'NR==1'" 2> /dev/null)
done

if [ "$n" -eq "$timeout" ]; then echo "Couldn't find most recent test result for build $version in $timeout seconds, exiting..." && exit 1; fi

echo "Found the most recent test result for build $version in $recentTestResult"

kubectl cp $allurePodName:$resultsDir/$recentTestResult results/$recentTestResult -n $namespace
