#!/bin/bash

if [ $# -neq 1  ]
  echo "usage ./launch-or-update-azure.sh <namespace>"
  exit
fi

namespace=$1
basePath="$namespace-dev.buyingcatalogue.digital.nhs.uk"
baseUrl="https://$basePath"
baseIdentityUrl="$baseUrl/identity"

#helm upgrade bc gpitfuturesdevacr/buyingcatalogue -n $namespace -i -f environments/azure.yaml --debug \
helm upgrade bc src/buyingcatalogue -n $namespace -i -f environments/azure.yaml \
  --set dbPassword=DisruptTheMarket1! \
  --set clientSecret=SampleClientSecret \
  --set appBaseUrl=$baseUrl \
  --set baseIsapiEnabledUrl=$baseIdentityUrl \
  --set isapi.clients[0].redirectUrls[0]=$baseUrl/oauth/callback \
  --set isapi.clients[0].redirectUrls[1]=$baseUrl/admin/oauth/callback \
  --set isapi.clients[0].redirectUrls[2]=$baseUrl/order/oauth/callback \
  --set isapi.clients[0].postLogoutRedirectUrls[0]=$baseUrl/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[1]=$baseUrl/admin/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[2]=$baseUrl/order/signout-callback-oidc \
  --set isapi.ingress.hosts[0].host=$basePath \
  --set isapi.hostAliases[0].hostnames[0]=$basePath \
  --set oapi.hostAliases[0].hostnames[0]=$basePath \
  --set ordapi.hostAliases[0].hostnames[0]=$basePath \
  --set email.ingress.hosts[0].host=$basePath \
  --set mp.ingress.hosts[0].host=$basePath \
  --set pb.ingress.hosts[0].host=$basePath \
  --set pb.baseUri=$baseUrl \
  --set pb.hostAliases[0].hostnames[0]=$basePath \
  --set admin.ingress.hosts[0].host=$basePath \
  --set admin.hostAliases[0].hostnames[0]=$basePath \
  --set of.ingress.hosts[0].host=$basePath \
  --set of.hostAliases[0].hostnames[0]=$basePath \
  --set redis-commander.ingress.hosts[0].host=$basePath
  