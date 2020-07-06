#!/bin/bash

function displayHelp {
  printf "usage: ./update-chart-versions.sh [OPTIONS]
          -h, --help
            Display help
          [REQUIRED]
          -v, --version <master|development>
            Get latest component versions from either master or development branches.
          [OPTIONAL]
          -p, --passed-args-only
            If present, ignores differences between local / remote and updates passed in components to the specified version
          -o, --override
            Override component's version 
            Eg: ./update-chart-versions.sh -v master -o bapi=1.30.0 -o dapi=1.30.2
            will get latest from master for all components except for bapi, which will be 1.30.0 and dapi, which will be 1.30.2 
          "
  exit
}

# Option strings
SHORT="hv:po:"
LONG="help,version:,passed-args-only,override:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

chartDirectory="src/buyingcatalogue"
pathToChart="./$chartDirectory/Chart.yaml"

namePrefix="- name: "
versionPrefix="  version: "

localComponentNames=()
localComponentVersions=()
extraArgs=()

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -v | --version )
    case "$2" in
      master)
          ;;
      development)
          versionSource='--devel'
          ;;
      *)
          echo "Unknown version source '$2'. Allowed values are: 'master' or 'development'"
          exit 1
    esac
      versionSourceSet="true"
      shift 2
      ;;
    -p | --passed-args-only )
      usePassedArgsOnly="true"
      shift
      ;;
    -o | --override )    
      extraArgs+=("$2")
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

if [ -z "$versionSourceSet" ]; then
  echo "Version source is not set, please specify which version source you'd like to use and try again. For more info: ./update-chart-versions.sh -h"
  exit 1
fi

# Update the local cache from the Repo and confirm dev repo is queried
echo -e "Updating local repo cache... \n"
updateRepos=$(helm repo update|grep "gpitfuturesdevacr")

if [[ $updateRepos != "" ]]; then
  echo -e "$updateRepos \n"
else
  echo -e "gpitfuturesdevacr not found in helm repos, please add 'gpitfuturesdevacr' to your helm repos and try again.  \n"
  exit
fi

# Construct an indexed array of our components & their versions
while IFS= read -r line; do
  if [[ $line =~ ^"$namePrefix"* ]]; then
      localComponentNames+=($(echo "${line#${namePrefix}}"))
  fi

  if [[ $line =~ ^"$versionPrefix"* ]]; then
      localComponentVersions+=($(echo "${line#${versionPrefix}}"))
  fi
done < "$pathToChart"

if [ "${#localComponentNames[@]}" -ne "${#localComponentVersions[@]}" ]; then
  >&2 echo "Number of components doesn't match the number of versions, exiting."
  exit
fi

# build a map (chart => version) for local charts, eg:
# of => 1.27.1
# mp => 1.27.1
declare -A localChartsToVersions
for (( i=0; i<${#localComponentNames[@]}; i++ )); do
  localChartsToVersions["${localComponentNames[$i]}"]="${localComponentVersions[$i]}"
done

# build a map (chart => version) for remote charts
if [ -z $usePassedArgsOnly ]; then
  declare -A remoteChartsToVersions
  echo -e "Grabbing Chart information from the acr... \n"
  remoteChartsAndVersions=$(helm search repo gpit $versionSource | sed "s@gpitfuturesdevacr/@@" | awk 'NR>1{printf("%s:%s ", $1, $2)}')
  for entry in ${remoteChartsAndVersions[*]}; do
    component=$(echo $entry | cut -d: -f1 ) 
    version=$(echo $entry | cut -d: -f2 ) 
    remoteChartsToVersions[$component]=$version
  done
fi

# create a copy of the localChartsToVersions map that will serve as a change set
declare -A changeSet  
for key in "${!localChartsToVersions[@]}"; do
  changeSet["$key"]="${localChartsToVersions["$key"]}"
done

for component in ${!localChartsToVersions[@]}; do
  if [ "${remoteChartsToVersions[$component]+isset}" ]; then
    localVersion="${localChartsToVersions[$component]}"
    remoteVersion="${remoteChartsToVersions[$component]}"
    if [ "$localVersion" != "$remoteVersion" ]; then
        changeSet[$component]=$remoteVersion
    fi
  fi
done

# Override some components and their versions as per args supplied to the -o option
for argument in ${extraArgs[@]}; do
  component=$(echo $argument | cut -d= -f1 ) 
  version=$(echo $argument | cut -d= -f2 ) 
  if [ "${changeSet[$component]+isset}" ]; then
    changeSet[$component]=$version
  else
    echo -e "Component '$component' passed in is not in Chart.yaml, please double check the spelling and try again. \n"
  fi
done

echo -e "List of updates to be carried out: \n"
printf '%-20s  %-8s %-16s %-12s %-16s\n' "COMPONENT" "" "CURRENT VERSION" "" "UPDATED VERSION"
for component in ${!changeSet[@]}; do
  printf '%-20s from %-4s %-16s %-4s => %-4s %-16s\n' "$component" "" "${localChartsToVersions[$component]}" "" "" "${changeSet[$component]}"
done

# Make a back-up of the previous version of the Chart.yaml
dateStamp=$(date +%Y-%m-%d)

if [ -f "$chartDirectory/Chart-$dateStamp.yaml" ]; then
  rm "$chartDirectory/Chart.yaml"
else
  mv "$pathToChart" "$chartDirectory/Chart-$dateStamp.yaml"
fi

# Create new chart file from template and changeSet map 
templateRegex='^(.*)(%%)([a-zA-Z-]+)(%%)'
while IFS= read -r line; do
  if [[ $line =~ $templateRegex ]]; then
    component=$(echo ${BASH_REMATCH[3]})
    line=$(echo "$line" | sed "s/%%$component%%/${changeSet[$component]}/g")
  fi
  echo "$line" | tr -d '\r' >> $pathToChart
done < "$chartDirectory/Chart.template"

# Remove old versions of Chart-<date>.yaml (older than 2 days)
find ./$chartDirectory/ -name "Chart-*.yaml" -type f -mtime +3 -exec rm -f {} \;

