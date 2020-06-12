#!/bin/bash

if [ $# -ne 1  ]
then
  echo "usage ./launch-or-update-azure.sh <namespace>"
  exit
fi

namespace=$1

helm delete bc -n $namespace

kubectl delete ns $namespace
