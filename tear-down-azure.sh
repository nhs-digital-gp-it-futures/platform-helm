#!/bin/bash

if [ $# -neq 1  ]
  echo "usage ./launch-or-update-azure.sh <namespace>"
  exit
fi

helm delete bc -n $1