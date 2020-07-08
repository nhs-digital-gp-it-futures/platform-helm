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