#!/bin/bash

# Help Text
function displayHelp {
  printf "usage: ./launch-or-update-azure.sh [OPTIONS]
          -h, --help
            Display help
          -c, --chart [local|local-cache|remote]
            chart is (default) remote(gpitfuturesdevacr/buyingcatalogue), or local (src/buyingcatalogue) 
          -n, --namespace <namespace>
            Namespace to deploy to; otherwise generated to be a random 8 characters
          -d, --db-server <database server>
            [REQUIRED] SQL database server to deploy to
          -u, --db-admin-user <user name>
            [REQUIRED] SQL Admin User Name
          -p, --db-admin-pass <password>
            [REQUIRED] SQL Admin Password
          -v, --version <version>
            Version to deploy (Remote Chart Only)
          -w --wait
            wait for deployment to complete successfully (up to 10 minutes)
          -b, --base-path <path>
            Base path to application, will default to '\$namespace-dev.buyingcatalogue.digital.nhs.uk'
          -s, --sql-package-args
          -a, --azure-storage-connection-string <connection string>
            [REQUIRED] Azure Storage Connection String
          -i, --ip <IP Address>
            Overrides host config and sets IP for the given base path 
          -r, --redis-server <redis host url>
            [REQUIRED] Url to connect to Redis
          -q, --redis-password <redis host password>
            [REQUIRED] Password connect to Redis
          -f, --file-overrides
            A comma-separated list of file names. These are the names of override files to apply.
            NOTE: these files are expected to be in the 'environments' directory
            E.g: '-f public.yaml,no-data-insert.yaml' will apply environments/public.yaml & environments/no-data-insert.yaml 
          --client-secret <client secret>
            The client secret to use for the cookie encryption. Default 'NodeClientSecret'
          --cookie-secret <cookie secret>
            The cookie secret to use for the cookie encryption. Default 'secret squirrel'
          --db-pass <pass>
            The password for use by the api db users Default 'DisruptTheMarket1!'
          --email-server
            If set, disable the internal email server, and use external. Email Username & password must also be set.
          --email-user
            Email username if email-server is set
          --email-pass
            Email password if email-server is set
          --helm-upgrade-args <arguments>
            Pass additional arguments to helm upgrade
          "
  exit
}
# Option strings
SHORT="hc:n:d:u:p:v:wb:s:a:i:r:q:f"
LONG="help,chart:,namespace:,db-server:,db-admin-user:,db-admin-pass:,version:,wait,base-path:,sql-package-args:,azure-storage-connection-string:,ip,redis-server:,redis-password:,file-overrides:,client-secret:,cookie-secret:,db-pass:,email-server:,email-user:,email-pass:,helm-upgrade-args:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# set initial values
chart="gpitfuturesdevacr/buyingcatalogue"
wait="false"
dbPassword="DisruptTheMarket1!"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    
    -c | --chart )
      if [ "$2" = "local" ]
      then 
        chart="src/buyingcatalogue"
        rm $chart/charts/*.tgz
        helm dependency update $chart
      elif [ "$2" = "local-cache" ]
      then
        chart="src/buyingcatalogue"
      fi
      shift 2
      ;;
    -n | --namespace )
      namespace="$2"
      shift 2
      ;;
    -d | --db-server )
      dbServer="$2"
      shift 2
      ;;
    -u | --db-admin-user )
      saUserName="$2"
      shift 2
      ;;
    -p | --db-admin-pass )
      saPassword="$2"
      shift 2
      ;;
    -v | --version )
      version="$2"
      shift 2
      ;;
    -w | --wait )
      wait="true"
      shift 1
      ;;
    -b | --base-path )
      basePath="$2"
      shift 2
      ;;
    -s | --sql-package-args )
      sqlPackageArgs="$2"
      shift 2
      ;;
    -a | --azure-storage-connection-string )
      azureStorageConnectionString="$2"
      shift 2
      ;;
    -i | --ip )
      ipOverride="$2"
      shift 2
      ;;
    -r | --redis-server )
      redisServer="$2"
      shift 2
      ;;
    -q | --redis-password )
      redisPassword="$2"
      shift 2
      ;;
    -f | --file-overrides )
      overrideFiles="$2"
      shift 2
      ;;
    --client-secret )
      clientSecret="$2"
      if [ ! -n "$clientSecret" ]; then
        clientSecret="NodeClientSecret"
      fi
      shift 2
      ;;
    --cookie-secret )
      cookieSecret="$2"
      if [ ! -n "$cookieSecret" ]; then
        cookieSecret="secret squirrel"
      fi
      shift 2
      ;;
    --db-pass )
      dbPassword="$2"
      shift 2
      ;;
    --email-server )
      emailServer="$2"
      shift 2
      ;;
    --email-user )
      emailUser="$2"
      shift 2
      ;;
    --email-pass )
      emailPassword="$2"
      shift 2
      ;;
    --helm-upgrade-args )
      helmUpgradeArgs="$2"
      shift 2
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

context=`kubectl config current-context`
if [[ "$context" = "docker-desktop" ]]; then 
  >&2 echo "Error - Local Context - $context"
  exit 1
fi

if [ -z ${namespace+x} ]
then 
  namespace=`cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 8 | head -n 1`
  echo "namespace not set: generated $namespace"
else #truncate to 63 chars
  namespace=`echo "$namespace" | cut -c 1-63`
fi

if [ -z ${dbServer+x} ] || [ -z ${saUserName+x} ] || [ -z ${saPassword+x} ]
then   
  echo "db server not set"
  exit
fi

if [ -z ${redisServer+x} ] || [ -z ${redisPassword+x} ]; then   
  echo "redis server not set properly"
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

if [ -n "$overrideFiles" ]; then  
  fileOverrideArgs=""
  IFS=',' read -ra FILES <<< "$overrideFiles"
  for file in "${FILES[@]}"; do
      fileOverrideArgs="$fileOverrideArgs -f environments/$file"
  done
fi

basePath=${basePath:-"$namespace-dev.buyingcatalogue.digital.nhs.uk"}

if [ -z ${emailServer+x} ] || [ -z ${emailUser+x} ] || [ -z ${emailPassword+x} ]
then
  #no email set, so use internal
  emailArg="--set email.ingress.hosts[0].host=$basePath"
else
  #email set
  emailArg="--set email.enabled=false 
  --set email.disabledUrl=$emailServer 
  --set email.disabledUserName=$emailUserName 
  --set email.disabledPassword=$emailPassword 
  --set isapi.serviceDependencies.email.authenticationRequired=true 
  --set isapi.serviceDependencies.email.allowInvalidCertificate=true 
  --set isapi.passwordReset.emailMessage.senderAddress=$emailUserName 
  --set isapi.registration.emailMessage.senderAddress=$emailUserName"
fi

if [ -n "$ipOverride" ]
then  
  hostAliases="--set isapi.hostAliases[0].ip=$ipOverride 
  --set isapi.hostAliases[0].hostnames[0]=$basePath 
  --set oapi.hostAliases[0].ip=$ipOverride 
  --set oapi.hostAliases[0].hostnames[0]=$basePath 
  --set ordapi.hostAliases[0].ip=$ipOverride 
  --set ordapi.hostAliases[0].hostnames[0]=$basePath
  --set pb.hostAliases[0].ip=$ipOverride 
  --set pb.hostAliases[0].hostnames[0]=$basePath 
  --set admin.hostAliases[0].ip=$ipOverride 
  --set admin.hostAliases[0].hostnames[0]=$basePath 
  --set of.hostAliases[0].ip=$ipOverride 
  --set of.hostAliases[0].hostnames[0]=$basePath"  
fi

baseUrl="https://$basePath"
baseIdentityUrl="$baseUrl/identity"
dbName=bc-$namespace
containerName=$namespace-documents


saUserStart=`echo $saUserName | cut -c-3`
saPassStart=`echo $saPassword | cut -c-3`
dbPassStart=`echo $dbPassword | cut -c-3`
redisPassStart=`echo $redisPassword | cut -c-3`
azureStorageConnectionStringStart=`echo $azureStorageConnectionString | cut -c-10`
clientSecretStart=`echo $clientSecret | cut -c-3`
cookieSecretStart=`echo $cookieSecret | cut -c-3`

printf "launch-or-update-azure.sh
        chart = $chart
        namespace = $namespace
        db-server = $dbServer
        db-admin-user = $saUserStart*
        db-admin-pass = $saPassStart*
        version = $version
        wait = $wait
        base-path = $basePath
        sql-package-args = $sqlPackageArgs
        azure-storage-connection-string = $azureStorageConnectionStringStart*
        ip = $ipOverride
        redis-server = $redisServer
        redis-password = $redisPassStart
        file-overrides = $overrideFiles
        client-secret = $clientSecretStart*
        cookie-secret = $cookieSecretStart*
        db-pass = $dbPassStart
        "

sed "s/REPLACENAMESPACE/$namespace/g" environments/azure-namespace-template.yml > namespace.yaml
cat namespace.yaml
kubectl apply -f namespace.yaml

helm upgrade bc $chart -n $namespace -i -f environments/azure.yaml \
  $fileOverrideArgs \
  --timeout 10m0s \
  --set saUserName="$saUserName" \
  --set saPassword="$saPassword" \
  --set dbPassword="$dbPassword" \
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
  --set clientSecret=$clientSecret \
  --set cookieSecret=$cookieSecret \
  --set appBaseUrl=$baseUrl \
  --set baseIsapiEnabledUrl=$baseIdentityUrl \
  --set isapi.clients[0].redirectUrls[0]=$baseUrl/oauth/callback \
  --set isapi.clients[0].redirectUrls[1]=$baseUrl/admin/oauth/callback \
  --set isapi.clients[0].redirectUrls[2]=$baseUrl/order/oauth/callback \
  --set isapi.clients[0].postLogoutRedirectUrls[0]=$baseUrl/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[1]=$baseUrl/admin/signout-callback-oidc \
  --set isapi.clients[0].postLogoutRedirectUrls[2]=$baseUrl/order/signout-callback-oidc \
  --set isapi.ingress.hosts[0].host=$basePath \
  --set mp.ingress.hosts[0].host=$basePath \
  --set pb.ingress.hosts[0].host=$basePath \
  --set pb.baseUri=$baseUrl \
  --set admin.ingress.hosts[0].host=$basePath \
  --set of.ingress.hosts[0].host=$basePath \
  --set redis-commander.ingress.hosts[0].host=$basePath \
  --set azurite.connectionString="$azureStorageConnectionString" \
  --set file-loader.azureBlobStorage.containerName=$containerName \
  --set dapi.azureBlobStorage.containerName=$containerName \
  --set redis.disabledUrl=$redisServer \
  --set redisPassword="$redisPassword" \
  $versionArg \
  $waitArg \
  $emailArg \
  $helmUpgradeArgs \
  $hostAliases