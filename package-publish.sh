#!/bin/bash

# Help Text
function displayHelp {
  printf "usage: ./launch-or-update-azure.sh [OPTIONS]
          -h, --help
            Display help
          -r, --registry-name <acr registry name>
            [REQUIRED] Registry name, e.g. gpitfuturesdevacr
          -u, --username <user name>
            [REQUIRED] Repo User Name
          -p, --password <password>
            [REQUIRED] Repo Password
          -v, --version <version>
            [REQUIRED] Version to publish as
          "
  exit
}
# Option strings
SHORT="hr:u:p:v:"
LONG="help,registry-name:,username:,password:,version:"

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      displayHelp
      shift
      ;;
    -r | --registry-name )
      registryName="$2"
      shift 2
      ;;
    -u | --username )
      username="$2"
      shift 2
      ;;
    -p | --password )
      password="$2"
      passStart=$(echo $password | cut -c-3)
      shift 2
      ;;
    -v | --version )
      version="$2"
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

if [ -z ${username+x} ] || [ -z ${password+x} ] || [ -z ${registryName+x} ] || [ -z ${version+x} ]
then 
  echo "required parameter not set"
  displayHelp
fi

echo "Package and Publish src/buyingcatalogue to $registryName with version $version, user $username, pass $passStart*"
registryFullName="$registryName.azurecr.io"

helm repo add $registryName "https://$registryFullName/helm/" --username "$username" --password "$password"
helm dependency update src/buyingcatalogue
helm package \
    --version $version \
    --app-version $version \
    src/buyingcatalogue
export HELM_EXPERIMENTAL_OCI=1
chartPackage=$(ls buyingcatalogue-*.tgz)
echo "Chart Package $chartPackage"
helm chart save $chartPackage "$registryFullName/helm/buyingcatalogue:$version"
helm chart list
helm registry login $registryFullName --username "$username" --password "$password"
helm chart push $registryFullName/helm/buyingcatalogue:$version

az acr repository show \
  --name $registryName \
  --repository helm/buyingcatalogue

# helm repo update

# helm repo search buyingcatalogue --devel

# echo $(jq -n --arg ver "$version" '{helmChartVersion: $ver}') > $(build.artifactStagingDirectory)/variables.json
