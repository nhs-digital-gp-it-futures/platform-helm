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
            [REQUIRED] SQL database server to deploy to
          -u, --db-admin-user <user name>
            [REQUIRED] SQL Admin User Name
          -p, --db-admin-pass <password>
            [REQUIRED] SQL Admin Password
          -a, --azure-storage-connection-string <connection string>
            [REQUIRED] Azure Storage Connection String
          "
  exit
}

# Option strings
SHORT="hn:m:d:u:p:a:"
LONG="help,namespace:,commit-message:,db-server:,db-admin-user:,db-admin-pass:,azure-storage-connection-string:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options... exiting." >&2 ; exit 1 ; fi
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
    -m | --commit-message )
      commitMessage="$2"
      shift 2
      ;;
    -d | --db-server )
      dbServer="$2"
      shift 2
      ;;
    -u | --db-admin-user )
      saUserName="$2"
      shift 2
      ;;
    -p | --db-admin-pass )
      saPassword="$2"
      shift 2
      ;;
    -a | --azure-storage-connection-string )
      azureStorageConnectionString="$2"
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
    branchName=$(curl https://api.github.com/repos/nhs-digital-gp-it-futures/platform-helm/pulls/$prNumber | jq --raw-output '.head.ref' )
}

function calculateNamespaceNames {
    if [ ! $1 ]; then
        branchNamespace=`echo $branchName | sed 's/feature[[:punct:]]/bc-/g'`
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
    deleteQueries=()

    for service in ${services[*]}; do
        deleteQueries+=("DROP DATABASE [bc-$branchNamespace-$service];")
        deleteQueries+=("DROP DATABASE [bc-$prNamespace-$service];")
    done

    for query in ${deleteQueries[*]}; do
        sqlcmd -S $dbServer -U "$saUserName" -P "$saPassword" -d master -Q $query || true
    done
}

function deleteAllResources {
    deleteKuberetesResources
    deleteBlobStoreContainers
    deleteDatabases
}

if [ -z "$commitMessage" ]; then
    echo "missing commit message argument, relying on provided namespace name..."
    calculateNamespaceNames "$namespace"
    deleteAllResources
    exit
fi

if [ -z "$commitMessage" ] && [ -z "$namespace" ]; then
    echo "missing commit message and namespace name, cannot calculate namespace name, exiting..."
    exit
fi

calculatePrNumber
calculateBranchName
calculateNamespaceNames

deleteAllResources