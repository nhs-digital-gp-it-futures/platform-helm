#!/bin/bash

context=`kubectl config current-context`
if [[ "$context" != "docker-desktop" ]]; then 
  >&2 echo "Not Local Context - $context"
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then 
  helm upgrade bc src/buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f environments/local-docker-mac.yaml -f local-overrides.yaml $@
else
  helm upgrade bc src/buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml $@
fi
