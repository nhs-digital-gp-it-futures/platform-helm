#!/bin/bash

chart="gpitfuturesdevacr/buyingcatalogue"
wait="true"

while getopts "hc:n:d:u:p:v:w:b:s:a:i:" opt; do
  case $opt in
    h)  echo "usage ./launch-or-update-azure.sh c=<local | remote> n=<namespace> d=<azure sql server> s=<azure sql user> p=<azure sql pass> v=<version> w=<wait?> b=<base path> s=<sql package args> a=<azure storage connection string> i=<ip>"
        echo "chart is (default)remote(gpitfuturesdevacr/buyingcatalogue), or local (src/buyingcatalogue). Version paramter (-v) applies to remote only"
        echo "wait=(default)true or false, whether helm will wait for the intallation to be complete"
        exit
    ;;
    c)  if [ "$OPTARG" = "local" ]
        then 
          chart="src/buyingcatalogue"
          rm $chart/charts/*.tgz
          helm dependency update $chart
        fi
    ;;
    n) namespace="$OPTARG"
    ;;
    d) dbServer="$OPTARG"
    ;;
    u) saUserName="$OPTARG"
    ;;
    p) saPassword="$OPTARG"
    ;;
    v) version="$OPTARG"
    ;;
    w) wait="$OPTARG"
    ;;
    b) basePath="$OPTARG"
    ;;
    s) sqlPackageArgs="$OPTARG"
    ;;
    a) azureStorageConnectionString="$OPTARG"
    ;;
    i) ipOverride="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z ${namespace+x} ]
then 
  namespace=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
  echo "namespace not set: generated $namespace"
fi

if [ -z ${dbServer+x} ] || [ -z ${saUserName+x} ] || [ -z ${saPassword+x} ]
then   
  echo "db server not set"
  exit
fi

if [ -n "$version" ] && [ "$chart" = "gpitfuturesdevacr/buyingcatalogue" ]
then  
  versionArg="--version $version"  
fi

if [ "$wait" = "true" ]
then  
  waitArg="--wait"  
fi

basePath=${basePath:-"$namespace-dev.buyingcatalogue.digital.nhs.uk"}

if [ -n "$ipOverride" ]
then  
  hostAliases="--set isapi.hostAliases[0].ip=$ipOverride \
  --set isapi.hostAliases[0].hostnames[0]=$basePath \
  --set oapi.hostAliases[0].ip=$ipOverride \
  --set oapi.hostAliases[0].hostnames[0]=$basePath \
  --set ordapi.hostAliases[0].ip=$ipOverride \
  --set ordapi.hostAliases[0].hostnames[0]=$basePath
  --set pb.hostAliases[0].ip=$ipOverride \
  --set pb.hostAliases[0].hostnames[0]=$basePath \
  --set admin.hostAliases[0].ip=$ipOverride \
  --set admin.hostAliases[0].hostnames[0]=$basePath \
  --set of.hostAliases[0].ip=$ipOverride \
  --set of.hostAliases[0].hostnames[0]=$basePath"
  echo "$hostAliases"
fi

baseUrl="https://$basePath"
baseIdentityUrl="$baseUrl/identity"
dbName=bc-$namespace
containerName=$namespace-documents


saUserStart=`echo $saUserName | cut -c-3`
saPassStart=`echo $saPassword | cut -c-3`
echo "launch-or-update-azure.sh c=$chart n=$namespace d=$dbServer u=$saUserStart* p=$saPassStart* v=$version w=$wait b=$baseUrl a=$azureStorageConnectionString"  

sed "s/REPLACENAMESPACE/$namespace/g" environments/azure-namespace-template.yml > namespace.yaml
cat namespace.yaml
kubectl apply -f namespace.yaml

helm upgrade bc $chart -n $namespace -i -f environments/azure.yaml \
  --timeout 10m0s \
  --set saUserName="$saUserName" \
  --set saPassword="$saPassword" \
  --set dbPassword=DisruptTheMarket1! \
  --set db.dbs.bapi.name=$dbName-bapi \
  --set bapi-db-deploy.db.name=$dbName-bapi \
  --set bapi-db-deploy.db.sqlPackageArgs="$sqlPackageArgs" \
  --set db.dbs.isapi.name=$dbName-isapi \
  --set isapi-db-deploy.db.name=$dbName-isapi \
  --set isapi-db-deploy.db.sqlPackageArgs="$sqlPackageArgs" \
  --set db.dbs.ordapi.name=$dbName-ordapi \
  --set ordapi-db-deploy.db.name=$dbName-ordapi \
  --set ordapi-db-deploy.db.sqlPackageArgs="$sqlPackageArgs" \
  --set db.disabledUrl=$dbServer \
  --set azurite.connectionString="$azureStorageConnectionString" \
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
  --set email.ingress.hosts[0].host=$basePath \
  --set mp.ingress.hosts[0].host=$basePath \
  --set pb.ingress.hosts[0].host=$basePath \
  --set pb.baseUri=$baseUrl \
  --set admin.ingress.hosts[0].host=$basePath \
  --set of.ingress.hosts[0].host=$basePath \
  --set redis-commander.ingress.hosts[0].host=$basePath \
  --set file-loader.azureBlobStorage.containerName=$containerName \
  --set dapi.azureBlobStorage.containerName=$containerName \
  $versionArg \
  $waitArg \
  $hostAliases
