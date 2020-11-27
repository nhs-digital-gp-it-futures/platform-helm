# Running in Azure

The build pipeline for this repository is set up so that each branch publishes to its own namespace in the dev environment, which is then available when pushed.

*****WARNING*****
Resources on the cluster are limited, so please try not to create too many environments, and remove them once finished.

## Prerequisites
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed
- have kubernetes cli installed - [install it](local-k8s-setup.md)

## Viewing the Kubernetes Dashboard for the Dev environment

To view the kubernetes dashboard in dev, run the snippet below 

```PS
az aks get-credentials --name gpitfutures-development-aks -g gpitfutures-development-rg-aks --admin
az aks browse --name gpitfutures-development-aks -g gpitfutures-development-rg-aks
```

Note: In the event of issues accessing 127.0.0.1 '(NET::ERR_CERT_INVALID)' that CANNOT be overriden in Chrome, a [setting can be changed here to allow access - chrome://flags/#allow-insecure-localhost](chrome://flags/#allow-insecure-localhost)

## Creating & Viewing an environment

Create a branch & push it

```bash
git checkout -b feature/<story-id>-my-feature
<Do Something>
git push
```

The pipeline will start creating an environment. Progress can be viewed here: [nhs-digital-gp-it-futures.platform-helm](https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_build?definitionId=75&_a=summary)

Once the environment is created, you'll see a namespace in the dashboard called `bc-<story-id>-my-feature`. 

## Launch from script

There is a helper script that allows the direct creation of an environment in azure, mimicking the build process. To use:

- Point `kubectl` to the development cluster 
  - `az aks get-credentials -n gpitfutures-development-aks -g gpitfutures-development-rg-aks` to get the credentials, if you've not previously connected.
- Run `launch-or-update-azure.sh -h` for details of the parameters needed to deploy the system in the cloud. 

## PR Process

The deployment is also hooked up to the PR process, which will create another environment, currently called `merge-<pull request number>`. This is subject to change, but allows the checks that run against the PR to fully create the environment, and validate the deployment. It is intended this will also run the acceptance tests, allowing feedback on issues across the entire system. This means there will be two environments per PR, one for the branch, and one for the PR.

## Environment Removal

**IT IS IMPORTANT TO CLEAR DOWN ANY CREATED ENVIRONMENTS**

*****NOTE*****
In order for the script to also clear the databases and storage containers, you'll need to be connected to the VPN

Run the tear down script 

`tear-down-azure.sh -n <namespace> -a '<blob store account connection string>'`

you can get the connection string from the [azure portal](https://portal.azure.com/#@HSCIC365.onmicrosoft.com/resource/subscriptions/7b12a8a2-f06f-456f-b6f9-aa2d92e0b2ec/resourceGroups/gpitfutures-dev-rg-sa/providers/Microsoft.Storage/storageAccounts/gpitfuturesdevsa/keys)