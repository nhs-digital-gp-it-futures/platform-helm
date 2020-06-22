#!/bin/bash

function displayHelp {
  printf "usage: ./tear-down-azure.sh [OPTIONS]
          -h, --help
            Display help
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
SHORT="hm:d:u:p:a:"
LONG="help,commit-message:,db-server:,db-admin-user:,db-admin-pass:,azure-storage-connection-string:"

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



containsReferenceToPR='^(.*)([#][0-9]{1,3})[^0-9](.*)$'


if [[ $commitMessage =~ $containsReferenceToPR ]]; then
    prNumber=$(echo ${BASH_REMATCH[2]} | tr -d '#') # grab the matched group
else
   echo "Couldn't extract PR number from the commit message, exiting."
   exit 1
fi

branchName=$(curl https://api.github.com/repos/nhs-digital-gp-it-futures/platform-helm/pulls/$prNumber | jq --raw-output '.head.ref')

branchNamespace=`echo $branchName | sed 's/feature[[:punct:]]/bc-/g'`
prNamespace="bc-merge-$prNumber"

echo "helm delete bc -n $branchNamespace"
echo "kubectl delete ns $prNamespace"

#test az storage works
az storage container list --connection-string "$azureStorageConnectionString"

#az storage container delete --name $branchNamespace --connection-string "$azureStorageConnectionString"
#az storage container delete --name $prNamespace --connection-string "$azureStorageConnectionString"

#db

# check sqlcmd is installed
sqlcmd -?

# modify IFS to allow spaces in array elements
IFS=""
services=("bapi"  "isapi"  "ordapi")
deleteQueries=()

for service in ${services[*]}; do
     deleteQueries+=("DROP DATABASE bc-$branchNamespace-$service;")
     deleteQueries+=("DROP DATABASE bc-$prNamespace-$service;")
done

for query in ${deleteQueries[*]}; do
     echo "sqlcmd -S dbServer -U saUserName -P saPassword -d master -i $query"
done
