#!/bin/bash
set -e

function extractStoryIdFromBranchName {
    storyIdRegex='^(refs/heads/feature/)([0-9]{4,5})[^0-9]?(.*)$'

    if [[ "$1" =~ $storyIdRegex ]]; then
      storyId=$(echo ${BASH_REMATCH[2]}) # get the 2nd captured group
    else
        >&2 echo "Couldn't extract the story Id from branch name, assuming a new namespace needs to be made."
        return 1
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

# if we can extract the story id from the branch name, look for an existing namespace with that story id in it.
  if extractStoryIdFromBranchName $branchName ; then
    allNamespaces=$(kubectl get ns -o=custom-columns=NAME:.metadata.name)
    for namespace in ${allNamespaces[*]}; do
      if [[ "$namespace" == *"$storyId"* ]]; then
        featureNamespace=$namespace
        break
      fi
    done
  fi

  if [ -z "$featureNamespace" ]; then
    unwantedPrefix="refs/heads/"
    featureNamespace=$(echo "${branchName#${unwantedPrefix}}" | sed 's/feature[[:punct:]]/bc-/g')
    echo "##vso[task.setvariable variable=IsNewNamespace;isOutput=true]true"
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
