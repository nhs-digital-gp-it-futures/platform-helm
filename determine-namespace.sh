#!/bin/bash
set -e

function extractStoryIdFromBranchName {
    storyIdRegex='^(refs/heads/feature/)([0-9]{4,5})[^0-9]?(.*)$'

    if [[ "$1" =~ $storyIdRegex ]]; then
      storyId=$(echo ${BASH_REMATCH[2]}) # get the 2nd captured group
    else
        >&2 echo "Couldn't extract the story Id from branch name, exiting."
        exit 1
    fi
}

function calculateBranchNameFromBranchOfRemoteTrigger {
  # Gets name of the variable following given pattern
  branchNameVariableName=$(compgen -A variable | grep 'RESOURCES_PIPELINE_.*SOURCEBRANCH')

  # returns the value from the variable name captured above
  echo ${!branchNameVariableName}
  return 0
}

function calculateNamespaceFromBranchName {
  branchName=$1

  extractStoryIdFromBranchName $branchName

  allNamespaces=$(kubectl get namespaces | awk 'NR>1{print $1}')

  for namespace in ${allNamespaces[*]}; do
    if [[ "$namespace" == *"$storyId"* ]]; then
      featureNamespace=$namespace
      break
    fi
  done

  if [ -z "$featureNamespace" ]; then
    unwantedPrefix="refs/heads/"
    featureNamespace=$(echo "${branchName#${unwantedPrefix}}" | sed 's/[[:punct:]]/-/g')
  fi

  echo "$featureNamespace"
  return 0
}


if [ "$BUILD_REASON" = "PullRequest" ]; then
    namespace=$(echo "bc-$BUILD_SOURCEBRANCHNAME-$SYSTEM_PULLREQUEST_PULLREQUESTNUMBER" | sed 's/[[:punct:]]/-/g')
elif [ "$BUILD_REASON" = "ResourceTrigger" ]; then
    branchName=$(calculateBranchNameFromBranchOfRemoteTrigger)
    namespace=$(calculateNamespaceFromBranchName $branchName)
else
    namespace=$(calculateNamespaceFromBranchName $BUILD_SOURCEBRANCH)
fi

echo "namespace=$namespace"
echo "##vso[task.setvariable variable=Namespace;isOutput=true]$namespace"
