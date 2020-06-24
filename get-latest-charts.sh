#!/bin/bash

function displayHelp {
  printf "usage: ./get-latest-charts.sh [OPTIONS]
          -h, --help
            Display help
          -m, --main
            Get latest from the main release instead of alpha releases
          "
  exit
}
# Option strings
SHORT="hm"
LONG="help,main"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
chart="src/buyingcatalogue"
currentFile=$(cat ./$chart/Chart.yaml)
dependencies="false"
versionSource='--devel'

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -m | --main )
      unset versionSource
      shift
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

# Update the local cache from the Repo and confirm dev repo is queried
updateRepos=$(helm repo update|grep "gpitfuturesdevacr")

if [[ $updateRepos != "" ]]; then
  echo $'\n'"$updateRepos"$'\n'
else
  echo $'\n'"gpitfuturesdevacr not found in helm repos"$'\n'
  exit
fi

# Move or Remove old file
dateStamp=`date +%Y-%m-%d`
if test -f ./$chart/Chart-$dateStamp.yaml; then
  rm ./$chart/Chart.yaml
else
  mv ./$chart/Chart.yaml ./$chart/Chart-$dateStamp.yaml  
fi

echo "$currentFile"| while read line
do 
    if [[ $line =~ ^"dependencies"* ]]; then
      dependencies="true"
    fi
    
    if [[ $line =~ ^"- name: "* ]]; then
        componentName=$(echo "$line" | cut -d " " -f3 | sed -r 's/\r$//')
        compVersion="$(helm search repo "$componentName" $versionSource --output table | grep "gpitfuturesdevacr/$componentName" | grep -v "$componentName-" | cut -f2)"
        if [[ $compVersion != "" ]]; then
          newVersion="version: $compVersion"
          echo "$componentName updated: $compVersion"
        fi
    fi

    # Add line and return space characters for formatting
    if [[ $line =~ ^"condition: " ]] || [[ $line =~ ^"repository: " ]]; then
      line="  $line"
    fi

    if [[ $line =~ ^"version: " ]] && [[ $dependencies == "true" ]]; then
      if [[ $newVersion != "" ]]; then
        line="  $newVersion"
        newVersion=""
      else 
        line="  $line"
      fi
    fi

    echo "$line" | tee -a ./$chart/Chart.yaml >/dev/null
done

# Remove old versions of Chart-<date>.yaml (older than 2 days)
find ./$chart/ -name "Chart-*.yaml" -type f -mtime +3 -exec rm -f {} \;