#!/bin/bash

commitMessage=$1
containsReferenceToPR='^(.*)([#][0-9]{1,3})[^0-9](.*)$'


if [[ $commitMessage =~ $containsReferenceToPR ]]; then
    prNumber=$(echo ${BASH_REMATCH[2]} | tr -d '#') # grab the matched group
    echo $prNumber
else
   echo "Couldn't extract PR number from the commit message, exiting."
   exit 1
fi

branchName=$(curl https://api.github.com/repos/nhs-digital-gp-it-futures/platform-helm/pulls/$prNumber | jq --raw-output '.head.ref')
echo $branchName
branchNamespace=`echo $branchName | sed 's/feature[[:punct:]]/bc-/g'`
prNamespace="bc-merge-$prNumber"

echo "going to delete ns $branchNamespace"
echo "going to delete ns $prNamespace"


# helm delete bc -n $namespace

# kubectl delete ns $namespace
