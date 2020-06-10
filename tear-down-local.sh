#!/bin/bash

context=`kubectl config current-context`
if [[ "$context" != "docker-desktop" ]]; then 
  >&2 echo "Not Local Context - $context"
  exit 1
fi

helm delete bc -n buyingcatalogue