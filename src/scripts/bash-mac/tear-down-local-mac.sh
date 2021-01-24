#!/usr/local/bin/bash

context=`kubectl config current-context`
if [[ "$context" != "docker-desktop" ]]; then 
  >&2 echo "$context is not a local context!"
  exit 1
fi

helm delete bc -n buyingcatalogue