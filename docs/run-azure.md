# Running in Azure

The build pipeline for this repository is set up so that each branch publishes to a its' own namespace in the dev environment, which is then available to look at, when pushed.

*****WARNING*****
Resources on the cluster are limited, so please try not too create many environments, and remove them once finished.

## Viewing the Kubernetes Dashboard for the Dev environment

To view the kubernetes dashboar din dev, run the below (assumming you have the [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed)

```PS
az aks browse --name gpitfutures-dev-aks -g gpitfutures-dev-rg-aks
```

## Creating & Viewing an environment

Create a branch & push it

```bash
git checkout -b feature/my-feature
<Do Something>
git push
```

The pipeline will start creating an environment. Progress can be viewed here: [nhs-digital-gp-it-futures.platform-helm](https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_build?definitionId=75&_a=summary)

Once the environment is created, you'll see a namespace in the dashboard called `buyingcatalogue-<branch name>`.
If you amend your hosts file as below (replacing <namespace>), you'll be able to browse to the environment:

```text
51.11.46.27 <namespace>-dev.buyingcatalogue.digital.nhs.uk
```

## Launch from script

There is a helper script that allows the direct creation of an environment in azure, mimicking the build process. To use:

- Point `kubectl` to the development cluster 
  - `az aks get-credentials -n gpitfutures-dev-aks -g gpitfutures-dev-rg-aks` to get the credentials, if you've not previously connected.
- Run `launch-or-update-azure.sh <chart> <namespace> <azure sql server> <azure sql user> <azure sql pass>` to deploy the system. 

## PR Process

The deployment is also hooked up to the PR process, which will create another environment, currently called `merge-<pull request number>`. This is subject to change, but allows the checks that run against the PR to fully create the environment, and validate the deployment. It is intended this will also run the acceptance tests, allowing feedback on issues across the entire system. This means there will be two environments per PR, one for the branch, and one for the PR.

## Environment Removal

**IT IS IMPORTANT TO CLEAR DOWN ANY CREATED ENVIRONMENTS**
To do so, connect `kubectl` as above, and run:

- `tear-down-azure.sh <namespace>` to remove the deployment
- `kubectl delete ns <namespace>` to remove the namespace