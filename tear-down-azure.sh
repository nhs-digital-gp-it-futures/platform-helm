#!/bin/bash

if [ $# -ne 1  ]; then
  echo "usage ./launch-or-update-azure.sh <namespace>"
  exit
fi

helm delete bc -n $1

kubectl delete ns $1