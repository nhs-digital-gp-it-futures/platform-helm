#!/bin/bash

function displayHelp {
  printf "usage: ./tear-down-azure.sh [OPTIONS]
          -h, --help
            Display help
          -n, --namespace <namespace>
            Name of the namespace to delete
          -m, --commit-message <commit-message>
            Message of the latest commit on this branch
          -d, --db-server <database server>
            [OPTIONAL] SQL database server to delete databases from
            defaults to: gpitfutures-dev-sql-pri
          -a, --azure-storage-connection-string <connection string>
            [REQUIRED] Azure Storage Connection String
          -g, --resource-group <rg>
            [OPTIONAL] Resource group of the db 
            defaults to: gpitfutures-dev-rg-sql-pri
          "
  exit
}

# Option strings
SHORT="hn:m:d:a:g:"
LONG="help,namespace:,commit-message:,db-server:,azure-storage-connection-string:,resource-group:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options... exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# Defaults
dbServer="gpitfutures-development-sql-pri"
resourceGroup="gpitfutures-development-rg-sql-pri"

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
    -m | --commit-message )
      commitMessage="$2"
      shift 2
      ;;
    -d | --db-server )
      dbServer="$2"
      shift 2
      ;;
    -a | --azure-storage-connection-string )
      azureStorageConnectionString="$2"
      shift 2
      ;;
    -g | --resource-group )
      resourceGroup="$2"
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

function calculatePrNumber {
    containsReferenceToPR='^(.*)([#][0-9]{1,3})[^0-9]?(.*)$'

    if [[ $commitMessage =~ $containsReferenceToPR ]]; then
        prNumber=$(echo ${BASH_REMATCH[2]} | tr -d '#') # grab the matched group
    else
        echo "Couldn't extract PR number from the commit message, exiting."
        exit 0
    fi
}

function calculateBranchName {
    branchName=$(curl https://api.github.com/repos/nhs-digital-gp-it-futures/platform-helm/pulls/$prNumber | jq --raw-output '.head.ref' | tr '[:upper:]' '[:lower:]' )
}

function calculateNamespaceNames {
    if [ ! $1 ]; then
        branchNamespace=$(echo $branchName | sed 's/feature[[:punct:]]/bc-/g')
        prNamespace="bc-merge-$prNumber"
        return 
    fi
    
    branchNamespace="$1"
}

function deleteKubernetesResources {
    kubectl delete ns $branchNamespace $prNamespace || true
}

function deleteBlobStoreContainers {
    az storage container delete --name "$branchNamespace-documents" --connection-string "$azureStorageConnectionString" || true
    az storage container delete --name "$prNamespace-documents" --connection-string "$azureStorageConnectionString" || true
}

function deleteDatabases {
    # modify IFS to allow spaces in array elements
    IFS=""
    services=("bapi"  "isapi"  "ordapi")
    databaseNames=()

    for service in ${services[*]}; do
        databaseNames+=("bc-$branchNamespace-$service")
        databaseNames+=("bc-$prNamespace-$service")
    done

    for dbName in ${databaseNames[*]}; do
        az sql db delete --name "$dbName" --resource-group "$resourceGroup" --server "$dbServer" --yes
    done
}

function deleteAllResources {
    deleteKubernetesResources
    deleteBlobStoreContainers 2> /dev/null
    deleteDatabases
}

if [ -z "$azureStorageConnectionString" ]; then
    echo "Missing blob storage connection string argument, exiting..."
    exit
fi

if [ -z "$commitMessage" ]; then
    echo "Missing commit message argument, relying on provided namespace name..."
    calculateNamespaceNames "$namespace"
    deleteAllResources
    exit
fi

if [ -z "$commitMessage" ] && [ -z "$namespace" ]; then
    echo "Missing commit message and namespace name, cannot calculate namespace name, exiting..."
    exit
fi

calculatePrNumber
calculateBranchName
calculateNamespaceNames

deleteAllResources

