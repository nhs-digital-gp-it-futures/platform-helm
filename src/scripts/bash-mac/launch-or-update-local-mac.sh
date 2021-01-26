#!/usr/local/bin/bash

echo $BASH_VERSION

function displayHelp {
  printf "usage: ./launch-or-update-local.sh [OPTIONS]
          -h, --help
            Display help
          -l, --latest [true|false]
            Set repo to latest dev versions (defaults to true)
          -r, --useRemote [true|false]
            Use remote repo (defaults to true)
          -u, --updateCharts [true|false]
            Update charts from dev/master (defaults to true)
          "
  exit
}

# Option strings
SHORT="hl:r:u:"
LONG="help,latest:,useRemote:,updateCharts:"

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
    -r | --useRemote )
      if [ "$2" = "false" ]; then 
          useRemote="false"
      fi
      shift 2
      ;;
    -u | --updateCharts )
      if [ "$2" = "false" ]; then
          updateCharts="false"
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

echo -e "# Switches Selected for run are: \n#"
if [[ "$useRemote" != "false" ]]; then
  echo -e "# Use Remote Repo for Updates\t\t(change with -r false)"
  if [[ "$updateCharts" != "false" ]]; then
    echo -e "# Download Updated Versions of Charts\t(change with -u false)"
    if [[ "$latest" != "false" ]]; then
      echo -e "# Version of Charts to get: Development\t(change with -l false)"
    else
      echo -e "# Version of Charts to get: Master"
    fi
  else
    echo -e "# Download Current Versions of Charts"
  fi
else
  echo -e "# Use Local Files - no updates"
fi

echo -e "#\n# If this is not correct please CTRL + C now (continuing in 5 seconds)"
sleep 5s

if [[ "$useRemote" != "false" ]]; then
  if [[ "$updateCharts" != "false" ]]; then
    if [[ "$latest" != "false" ]]; then
      echo -e "Getting Latest Chart Versions... \n"
      ./src/scripts/bash-mac/update-chart-versions-mac.sh -v development
    else
      echo -e "Getting Master Chart Versions... \n"
      ./src/scripts/bash-mac/update-chart-versions-mac.sh -v master
    fi 
  fi

  echo -e "\n Updating Dependencies... \n"
  rm $chart/charts/*.tgz
  helm dependency update $chart
fi

# if [ ! -d "$chart/templates/allure" ] || [ ! -d "$chart/templates/azurite" ] || [ ! -d "$chart/templates/db" ] || [ ! -d "$chart/templates/redis-commander" ]; then
#   echo "Error: ./$chart/Templates is missing one or more core folders (allure, azurite, db or redis-commander)."
# fi  

echo "helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml $@"

if [[ "$OSTYPE" == "darwin"* ]]; then 
  helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f environments/local-docker-mac.yaml -f local-overrides.yaml #$@
else
  helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml #$@
fi
