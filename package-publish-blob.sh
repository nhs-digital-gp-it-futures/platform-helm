#!/bin/bash

# Help Text
function displayHelp {
  printf "usage: ./launch-or-update-azure.sh [OPTIONS]
          -h, --help
            Display help
          -s, --storage-account <storage account name>
            Storage Account Name, default gpitfuturesdevhelm
          -k, --storage-account-key <key>
            [REQUIRED] Storage account Key. Alternatively, uses environment variable AZURE_STORAGE_KEY
          -v, --version <version>
            [REQUIRED] Version to publish as
          "
  exit
}
# Option strings
SHORT="hs:k:v:"
LONG="help,storage-account:,storage-account-key:,version:"

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
    -s | --storage-account )
      AZURE_STORAGE_ACCOUNT="$2"
      shift 2
      ;;
    -k | --storage-account-key )
      AZURE_STORAGE_KEY="$2"
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

if [ -z ${AZURE_STORAGE_ACCOUNT+x} ]
then 
  AZURE_STORAGE_ACCOUNT=gpitfuturesdevhelm
fi

if [ -z ${AZURE_STORAGE_KEY+x} ] || [ -z ${version+x} ]
then 
  echo "required parameter not set"
  displayHelp
fi

if [ -z `helm plugin list | grep blob` ]
then
  helm plugin install https://github.com/C123R/helm-blob.git
fi

echo "Package and Publish src/buyingcatalogue to $AZURE_STORAGE_ACCOUNT with version $version"

helm repo add gpitfutures azblob://helm
helm dependency update src/buyingcatalogue
helm package \
    --version $version \
    --app-version $version \
    src/buyingcatalogue
export HELM_EXPERIMENTAL_OCI=1
chartPackage=$(ls buyingcatalogue-*.tgz)
echo "Chart Package $chartPackage"

helm blob push "$chartPackage" gpitfutures

# helm repo update

# helm repo search buyingcatalogue --devel

# echo $(jq -n --arg ver "$version" '{helmChartVersion: $ver}') > $(build.artifactStagingDirectory)/variables.json
