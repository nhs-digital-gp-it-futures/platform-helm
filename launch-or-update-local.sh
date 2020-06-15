#!/bin/bash

function displayHelp {
  printf "usage: ./launch-or-update-local.sh [OPTIONS]
          -h, --help
            Display help
          -u, --update [true|false]
            Update Helm Charts (defaults to true)
          "
  exit
}
# Option strings
SHORT="h:u:"
LONG="help,update:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
chart="gpitfuturesdevacr/buyingcatalogue"
wait="false"
update="true"
context=`kubectl config current-context`

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    
    -u | --update )
      if [ "$2" = "false" ]
        then 
          $update = "false"
        fi
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

if [[ "$context" != "docker-desktop" ]]; then 
  >&2 echo "Not Local Context - $context"
  exit 1
fi

if [ "$update" = "true" ]
  then 
    echo "Updating Dependencies..."
    chart="src/buyingcatalogue"
    rm $chart/charts/*.tgz
    helm dependency update $chart
fi

if [[ "$OSTYPE" == "darwin"* ]]; then 
  helm upgrade bc src/buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f environments/local-docker-mac.yaml -f local-overrides.yaml $@
else
  helm upgrade bc src/buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml $@
fi
