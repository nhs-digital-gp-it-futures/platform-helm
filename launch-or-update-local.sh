#!/bin/bash

function displayHelp {
  printf "usage: ./launch-or-update-local.sh [OPTIONS]
          -h, --help
            Display help
          -l, --latest [true|false]
            Set repo to latest dev versions (defaults to true)
          -u, --update [true|false]
            Update Helm Charts (defaults to true)
          -r, --useRemote [true|false]
            Use remote repo (defaults to true)
          "
  exit
}

# Option strings
SHORT="hl:u:r:"
LONG="help,latest:,update:,useRemote:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
chart="src/buyingcatalogue"
wait="false"
context=$(kubectl config current-context)

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -l | --latest )
      if [ "$2" = "false" ]; then 
          latest="false"
      fi
      shift 2
      ;;
    -u | --update )
      if [ "$2" = "false" ]; then 
          update="false"
      fi
      shift 2
      ;;
    -r | --useRemote )
      if [ "$2" = "false" ]; then 
          useRemote="false"
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
  >&2 echo "$context is not a local context!"
  exit 1
fi

if [[ "$useRemote" != "false" ]]; then
  if [[ "$latest" != "false" ]]; then
    echo -e "Getting Latest Chart Versions... \n"
    ./update-chart-versions.sh -v development
  else
    echo -e "Getting Master Chart Versions... \n"
    ./update-chart-versions.sh -v master
  fi 

  if [[ "$update" != "false" ]]; then
      echo -e "\n Updating Dependencies... \n"
      rm $chart/charts/*.tgz
      helm dependency update $chart
  fi
fi

if [[ "$OSTYPE" == "darwin"* ]]; then 
  helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f environments/local-docker-mac.yaml -f local-overrides.yaml $@
else
  helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml $@
fi