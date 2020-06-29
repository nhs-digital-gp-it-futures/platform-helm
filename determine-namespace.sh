#!/bin/bash

function extractStoryIdFromBranchName {
    storyIdRegex='^(refs/heads/feature/)([0-9]{4,5})[^0-9]?(.*)$'

    if [[ "$1" =~ $storyIdRegex ]]; then
      storyId=$(echo ${BASH_REMATCH[2]}) # get the 2nd captured group
    else
        echo "Couldn't extract the story Id from branch name, exiting."
        exit 1
    fi
}

function calculateNamespaceFromRemoteBranch {
  # Gets name of the variable following given pattern
  branchNameVariableName=$(compgen -A variable | grep 'RESOURCES_PIPELINE_.*SOURCEBRANCH')

  # Gets the value from the variable name captured above
  branchName="${!branchNameVariableName}"

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

  namespace=$featureNamespace
}


if [ "$BUILD_REASON" = "PullRequest" ]; then
    namespace=$(echo "bc-$BUILD_SOURCEBRANCHNAME-$SYSTEM_PULLREQUEST_PULLREQUESTNUMBER" | sed 's/[[:punct:]]/-/g')
elif [ "$BUILD_REASON" = "ResourceTrigger" ]; then
    calculateNamespaceFromRemoteBranch
else
    namespace=$(echo "bc-$BUILD_SOURCEBRANCHNAME" | sed 's/[[:punct:]]/-/g')
fi

echo "namespace=$namespace"
echo "##vso[task.setvariable variable=Namespace;isOutput=true]$namespace"
