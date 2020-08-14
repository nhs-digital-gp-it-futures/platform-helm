# How to: BA horn using dynamic environments

## Prerequisites

- have az cli installed - [install it](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest#install)

## Steps

**Note** The steps below demonstrate one way of creating a dynamic env. for a BA horn, it is also possible to create a dynamic environment using the [launch script](docs/run-azure.md#launch-from-script).
1) Checkout latest master branch the  [plaform-helm repository](https://github.com/nhs-digital-gp-it-futures/platform-helm)

2) Create a new branch, eg: "feature/ba-horn-story-x"

3) Adjust component versions if need be

   1. Check which component versions you want - you can map commits to builds and find out the version you want [here](https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_build?view=pipelines)
   2. Amend src/buyingcatalogue/Chart.yaml with those versions

      **NOTE:** you can run `./update-chart-versions.sh|ps1 -v development` to get latest from the development branches, or `./update-chart-versions.sh|ps1 -v master` to get latest from the master branches, for more options `./update-chart-versions.sh|ps1 -h`

4) Push this branch

5) Finish the BA horn

   you can now do the BA horn by going to `https://bc-<your branch name>-dev.buyingcatalogue.digital.nhs.uk`

6) Tear down the environment

   In root of the repository, run `./tear-down-azure.sh -a "<storage account connection string>" -n "bc-<your branch name>`

   Click [here](https://portal.azure.com/#@HSCIC365.onmicrosoft.com/resource/subscriptions/7b12a8a2-f06f-456f-b6f9-aa2d92e0b2ec/resourceGroups/gpitfutures-dev-rg-sa/providers/Microsoft.Storage/storageAccounts/gpitfuturesdevsa/keys) to find the storage account connection string
