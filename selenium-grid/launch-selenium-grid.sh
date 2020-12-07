#!/bin/bash

function displayHelp {
  printf "usage: ./launch-selenium-grid.sh [OPTIONS]
          -h, --help
            Display help
          [OPTIONAL]
          -a, --add <dns compliant host name>
            Add a host name that will resolve to the provided IP
          [OPTIONAL]
          -i, --ip <ipv4 address>
            Sets the ip address to which any host names will resolve. If not set, no host names will be overridden.
          -n, --namespace <ns>
            Sets the namespace where selenium grid is installed. Defaults to '$namespace'
          -t, --timeout <number of seconds>
            Sets the timeout for waiting on living pods, defaults to $timeout
          -p, --pod-count <number of desired chrome pods>
            Sets the replica count for chrome pods, defaults to $pods
          --helm-upgrade-args <arguments>
            Pass additional arguments to helm upgrade
          "
  exit
}

# Option strings
SHORT="ha:i:n:t:p:"
LONG="help,add:,ip:,namespace:,timeout:,pod-count:,helm-upgrade-args:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
namespace="selenium-grid"
ip=""
timeout=30
pods=4

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -a | --add )
      hostToBeAdded="$2"
      shift 2
      ;;
    -i | --ip )
      ip="$2"
      shift 2
      ;;
    -n | --namespace )
      namespace="$2"
      shift 2
      ;;
    -t | --timeout )
      timeout="$2"
      shift 2
      ;;
    -p | --pod-count )
      pods="$2"
      shift 2
      ;;
    --helm-upgrade-args )
      helmUpgradeArgs="$2"
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

function makeSureNamespaceExists {
  response=$(kubectl get ns $namespace)
  if [ -z "$response" ]; then
    kubectl apply -f grid-namespace.yml
  fi
}

function constructHostAliasArgs {
  if [ -z "$ip" ]
  then
    >&2 echo "No IP Set"
    echo ""
    return 0
  fi

  >&2 echo "Trying to find living pods to compare host aliases with..."
  n=0
  while [ ! -s "hosts" ] && [ "$n" -lt "$timeout" ]; do
    chromePodName=$(kubectl get pods -l app=sel-grid-selenium-chrome -n $namespace 2>/dev/null | awk 'FNR == 2 { print $1 }')
    kubectl exec $chromePodName -n $namespace -- cat /etc/hosts 2>/dev/null > hosts
    n=$((n+1)) 
    sleep 1
  done

  if [ ! -s "hosts" ]; then >&2 echo "Could not find living pods to compare host aliases with."; fi

  while IFS= read line; do
    if [[ $line = "$ip"* ]]; then
      addresses="$line $hostToBeAdded"
      addresses=$(printf '%s\n' "$addresses" | awk -v RS='[[:space:]]+' '!a[$0]++{printf "%s%s", $0, RT}') # remove duplicates
    fi
  done < hosts

  rm hosts

  if [ -z "$addresses" ] && [ -n "$hostToBeAdded" ]; then addresses="$ip    $hostToBeAdded"; fi

  if [ -n "$addresses" ]; then
    hostAliasArgs="--set global.hostAliases[0].ip=$ip"
    hostNames=($(echo $addresses | cut -f 1 -d ' ' --complement))
    for ((i = 0; i < ${#hostNames[@]}; ++i)); do
      hostAliasArgs="$hostAliasArgs --set global.hostAliases[0].hostnames[$i]=${hostNames[$i]}"
    done
    echo $hostAliasArgs
    return 0
  fi
  echo ""
}

makeSureNamespaceExists

helm upgrade sel-grid stable/selenium -i -f values.yaml -n $namespace $(constructHostAliasArgs) --set chrome.replicas=$pods $helmUpgradeArgs
