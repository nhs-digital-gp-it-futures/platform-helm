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
#index = 0
#ChartVersions = @()

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

CurrentFile=$(cat ./$chart/chart.yaml)
Dependencies="false"

echo "$CurrentFile"| while read line
do 
    if [[ $line =~ ^"dependencies"* ]]; then
      Dependencies="true"
    fi
    
    if [[ $line =~ ^"- name: "* ]]; then
        componentname=$(echo "$line" | cut -d " " -f3 | sed -r 's/\r$//')
#        echo "$componentname"
        compversion="$(helm search repo "$componentname" --devel --output table | grep "gpitfuturesdevacr/$componentname" | grep -v "$componentname-" | cut -f2)"
        if [[ $compversion != "" ]]; then
          newversion="version: $compversion"
#          echo "$newversion"
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

    echo "$line" | tee -a ./$chart/chartnew.yaml
done