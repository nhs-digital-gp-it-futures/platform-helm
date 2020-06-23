#!/bin/bash

function displayHelp {
  printf "usage: ./launch-or-update-local.sh [OPTIONS]
          -h, --help
            Display help
          "
  exit
}
# Option strings
SHORT="h:"
LONG="help:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
chart="src/buyingcatalogue"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
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

CurrentFile=$(cat ./$chart/Chart.yaml)
Dependencies="false"

# Update the local cache from the Repo and confirm dev repo is queried
updaterepos=$(helm repo update|grep "gpitfuturesdevacr")

if [[ $updaterepos != "" ]]; then
  echo $'\n'"$updaterepos"$'\n'
else
  echo $'\n'"gpitfuturesdevacr not found in helm repos"$'\n'
  exit
fi

# Move or Remove old file
DateStamp=`date +%Y-%m-%d`
if test -f ./$chart/Chart-$DateStamp.yaml; then
  rm ./$chart/Chart.yaml
else
  mv ./$chart/Chart.yaml ./$chart/Chart-$DateStamp.yaml  
fi

echo "$CurrentFile"| while read line
do 
    if [[ $line =~ ^"dependencies"* ]]; then
      Dependencies="true"
    fi
    
    if [[ $line =~ ^"- name: "* ]]; then
        componentname=$(echo "$line" | cut -d " " -f3 | sed -r 's/\r$//')
        compversion="$(helm search repo "$componentname" --devel --output table | grep "gpitfuturesdevacr/$componentname" | grep -v "$componentname-" | cut -f2)"
        if [[ $compversion != "" ]]; then
          newversion="version: $compversion"
          echo "$componentname updated: $compversion"
        fi
    fi

    # Add line and return space characters for formatting
    if [[ $line =~ ^"condition: " ]] || [[ $line =~ ^"repository: " ]]; then
      line="  $line"
    fi

    if [[ $line =~ ^"version: " ]] && [[ $Dependencies == "true" ]]; then
      if [[ $newversion != "" ]]; then
        line="  $newversion"
        newversion=""
      else 
        line="  $line"
      fi
    fi

    echo "$line" | tee -a ./$chart/Chart.yaml >/dev/null
done