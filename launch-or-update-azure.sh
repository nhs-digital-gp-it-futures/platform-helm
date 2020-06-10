#!/bin/bash

if [ $# -ne 4  ]; then
  echo "usage ./launch-or-update-azure.sh <namespace> <azure sql server> <azure sql user> <azure sql pass>"  
  exit
fi

namespace=$1
dbServer=$2
saUserName=$3
saPassword=$4
basePath="$namespace-dev.buyingcatalogue.digital.nhs.uk"
baseUrl="https://$basePath"
baseIdentityUrl="$baseUrl/identity"
bapiDbName=buyingcatalogue-$namespace

#helm dependency update src/buyingcatalogue/

sed "s/REPLACENAMESPACE/$namespace/g" environments/azure-namespace-template.yml > namespace.yaml
cat namespace.yaml
kubectl apply -f namespace.yaml

#helm upgrade bc gpitfuturesdevacr/buyingcatalogue -n $namespace -i -f environments/azure.yaml --debug \
helm upgrade bc src/buyingcatalogue -n $namespace -i -f environments/azure.yaml --debug \
  --set saUserName=$3 \
  --set saPassword=$4 \
  --set dbPassword=DisruptTheMarket1! \
  --set db.dbs.bapi.name=$bapiDbName \
  --set bapi-db-deploy.db.name=$bapiDbName \
  --set bapi-db-deploy.db.sqlPackageArgs="/p:DatabaseEdition=Standard /p:DatabaseServiceObjective=S0" \
  --set db.disabledUrl=$dbServer \
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