#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then 
  helm upgrade bc buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f environments/local-docker-mac.yaml -f local-overrides.yaml $@
else
  helm upgrade bc buyingcatalogue -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml $@
fi
