#!/bin/bash

function displayHelp {
  printf "usage: ./port-forward-cloud-apis-locally.sh [OPTIONS]
          -h, --help
            Display help
          -n, --namespace <namespace> to which port forward to
            Namespace to which port forward to
          "
  exit
}

# Option strings
SHORT="hn:"
LONG="help,namespace:"

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
    -n | --namespace )
      namespace="$2"
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

apiServices=("bapi" "dapi" "isapi" "oapi" "ordapi")
declare -A servicesToPorts

function constructServicesToPortsMap() {
    servicesToPorts[bapi]=5100
    servicesToPorts[dapi]=5101
    servicesToPorts[isapi]=5102
    servicesToPorts[oapi]=5103
    servicesToPorts[ordapi]=5104
}

constructServicesToPortsMap

for service in ${apiServices[*]}; do
    kubectl port-forward service/gpitfutures-bc-$service ${servicesToPorts[$service]}:${servicesToPorts[$service]} -n $namespace &
done

wait