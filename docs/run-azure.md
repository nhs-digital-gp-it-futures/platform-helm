# Table of Contents
- [Simple Deployment to Azure](#Simple-Deployment-to-Azure)
  * [Prerequisites](#Prerequisites)
  * [Kubernetes Dashboard in Dev](#Kubernetes-Dashboard-in-Dev)
  * [Creating and Viewing an environment](#Creating-and-Viewing-an-environment)
  * [PR Process](#PR-Process)
  * [Environment Removal](#Environment-Removal)
    + [Housekeeping Teardown](#Housekeeping-Teardown)
    + [Manual Teardown](#Manual-Teardown)
  * [Launch from script - Advanced Environment Creation](#Launch-from-script---Advanced-Environment-Creation)

# Simple Deployment to Azure

The build pipeline for this repository is set up so that each branch publishes to its own namespace in the dev environment, which is then available when pushed.

*****WARNING*****
Resources on the cluster are limited, so please try not to create too many environments, and remove them once finished (see [Environment Removal](#Environment-Removal))

## Prerequisites

- Pull (locally) the latest copy of the [Platform Helm Repository](https://github.com/nhs-digital-gp-it-futures/platform-helm)

## Creating an Environment

Create a branch & push it

```bash
git checkout -b feature/<story-id>-<my-feature> # e.g. git checkout -b feature/12345-dummy-branch
```
Then run Either: .\update-chart-versions.ps1 -v development OR .\update-chart-versions.ps1 -v master

```bash
git push
```
## Viewing Development

The action of pushing a branch to Platform Helm is that the [Platform Helm Pipeline](https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_build?definitionId=75&_a=summary) will run and create an environment for you on the Development Kubernetes Cluster in Azure.

## Viewing Environemnt

The URL will be displayed during the deployment, but will be something like:

```bash
URL: https://bc-<story-id>-<my-feature>.dev.buyingcatalogue.digital.nhs.uk # eg. https://bc-feature-12345-dummy-branch.dev.buyingcatalogue.digital.nhs.uk
```

## Destroy Branch

Switch to Master Branch and destroy remote branch
```bash
git checkout master
git branch -D feature/<story-id>-<my-feature>
git push origin --delete feature/<story-id>-<my-feature>
```

## Prerequisites - Advanced

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed
- have kubernetes cli installed - [install it](local-k8s-setup.md)

**In Addition, you will need to be connected to your Corporate VPN solution**

## Kubernetes Dashboard in Dev

To view the kubernetes dashboard in dev, run the snippet below 

```Powershell
az login # Only needed once per day

# This will launch a browser - please authenticate with your SHORTCODE based NHS account

az account set --subscription "GP IT Futures Buying Catalogue"
az aks get-credentials --name gpitfutures-development-aks -g gpitfutures-development-rg-aks --admin
az aks browse --name gpitfutures-development-aks -g gpitfutures-development-rg-aks
```

Note: Best accesssed in Firefox

Note: In the event of issues accessing 127.0.0.1 (in Chromium Browsers) '(NET::ERR_CERT_INVALID)' that CANNOT be overriden, a [setting can be changed here to allow access - chrome://flags/#allow-insecure-localhost](chrome://flags/#allow-insecure-localhost)

## Creating and Viewing an environment

Create a branch & push it

```bash
git checkout -b feature/<story-id>-my-feature
<Do Something>
git push
```

The pipeline will start creating an environment. Progress can be viewed here: [nhs-digital-gp-it-futures.platform-helm](https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_build?definitionId=75&_a=summary)

Once the environment is created, you'll see a warning on the script spelling out your environment name:

- Warning: "The Dynamic Environment URL will be: https://bc-ticket-branch-name.dev.buyingcatalogue.digital.nhs.uk

## PR Process

The deployment is also hooked up to the PR process, which will create another environment, currently called `merge-<pull request number>`. This is subject to change, but allows the checks that run against the PR to fully create the environment, and validate the deployment. It is intended this will also run the acceptance tests, allowing feedback on issues across the entire system. This means there will be two environments per PR, one for the branch, and one for the PR.

## Environment Removal

**IT IS IMPORTANT TO CLEAR DOWN ANY CREATED ENVIRONMENTS**

### Housekeeping Teardown

A nightly housekeeping task runs that clears up any legacy environments (with properly formatted names). 

To utilise this cleardown method all you need to do is remove the branch associated with your environment. The housekeeping task will detect this and clear down the resources automatically.

### Manual Teardown

***NOTE***
In order for the script to also clear the databases and storage containers, you'll need to be connected to the VPN

Run the tear down script:

`tear-down-azure.sh -n <namespace> -a '<blob store account connection string>'`

you can get the connection string from the [azure portal](https://portal.azure.com/#@HSCIC365.onmicrosoft.com/resource/subscriptions/7b12a8a2-f06f-456f-b6f9-aa2d92e0b2ec/resourceGroups/gpitfutures-development-rg-sa/providers/Microsoft.Storage/storageAccounts/gpitfuturesdevelopment/keys)

## Launch from script - Advanced Environment Creation

There is a helper script that allows the direct creation of an environment in azure, mimicking the build process. To use:

- Point `kubectl` to the development cluster 
  - `az aks get-credentials -n gpitfutures-development-aks -g gpitfutures-development-rg-aks` to get the credentials, if you've not previously connected.
- Run `launch-or-update-azure.sh -h` for details of the parameters needed to deploy the system in the cloud. 
