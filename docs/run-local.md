# Running Locally

This process is designed to easily allow a developer to spin up the current environment, and easily work on component(s), while having the rest of the system in place.

Note: You will need Admin rights on your laptop to set this up. If you do not have access this will need to be requested from the supplier of your laptop.

Please ensure you set your Execution Policy to Bypass:

```
set-executionpolicy bypass
```

## System Setup

Instructions expect you to be in the local-helm directory of the platform repository. To do this you will need to clone the repository locally and browse to the platform-helm folder.

The following steps are needed to be able to run the system successfully:

### Setup Kubernetes

To begin, make sure you have kubernetes running locally as per the [Kubernetes Dev Setup Instructions](../docs/local-k8s-setup.md)

### Setup Helm

Note that this system relies upon helm charts. Instructions on how to install helm can be found [here](https://helm.sh/docs/intro/install/).

### Set up Ingress

Ingress is required for the identity api to work. To enable the ingress, execute these three snippets in shell of your preference

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add stable https://charts.helm.sh/stable
helm install bc ingress-nginx/ingress-nginx
```

### Add Namespace

If this is not the initial build, please ensure you are pointing at your local Kubernetes desktop version.

Create the buying catalogue namespace - `kubectl apply -f environments/local-namespace.yml`

### Add Container Registry Secret

Create a secret in kubernetes to access the private container registry, as per the [Connect Local Kubernetes with our Private Container Registry Instructions](k8s-private-registry.md).

### (Optional) Run Dashboard

You may wish to run the dashboard. Instructions are [here](run-dashboard.md).

### (Optional) Run Rancher

You may wish to run Rancher rather than the dashboard. Rancher provide a step by step walkthrough to install, which is linked [here](rancher-setup.md)

## Add Dependencies

In order to run locally, a dependancy to the ACR must be added to Helm. This can be done using the below command (replace `$(gpitfuturesdevacr-pass)` with the password from azure portal you obtained in [k8s-private-registry.md](k8s-private-registry.md))

```
helm repo add gpitfuturesdevacr https://gpitfuturesdevacr.azurecr.io/helm/v1/repo --username gpitfuturesdevacr --password <password>
```

## Install Dependencies

The umbrella chart depends on some standard charts. These need to be added by running `helm dependency update src/buyingcatalogue`.

## Launching, Updating the Environment

In order to launch or update the system to the latest built images or chosen config, simply run the appropriate launch script. It will run until torn down, even being restarted automatically once kubernetes is running again after a system restart.

### Bash

```bash
./launch-or-update-local.sh
# or to run without getting the latest development chart versions (i.e. run with versions that are coming from builds on master branches)
./launch-or-update-local.sh -l false #(or --latest false)
# or to run using configuration and local files only - no updates will be performed
./launch-or-update-local.sh -r false #(or --useRemote false)
```

### PS

```Powershell
./launch-or-update-local.ps1
# or to run without getting the latest development chart versions (i.e. run with versions coming from builds or master branches)
./launch-or-update-local.ps1 -l #(or -latest false)
# or to run using configuration and local files only - no updates will be performed
./launch-or-update-local.ps1 -r #(or -useRemote false)
```

The script will start [all services available on these ports](../README.md#configuration-overview) on localhost, or update them if they are running.

Ingress is also set up, so the front ends are exposed on localhost, as they would be when running in production.

## Overrides

Overrides in [local-overrides.yaml](../local-overrides.yaml) can be set to choose whether to run a component in Kubernetes, or to consider it as running on the developers machine. When a service is disabled, anything that uses that service routes out to the developers machine, using `host.docker.internal` or `docker.for.mac.localhost` for mac.

By default cluster spins up containers ~~from latest images built from development branches ~~ with the latest specified versions. You can, however, override this and use a locally build image.

```yaml
mp:
  enabled: true
  useLocalImage: true
```

If you update the local image, e.g. by running `docker-compose build` in the component directory, you will need to redeploy it / delete the pod for the new image to be used.

### Local Charts

Each component, e.g. public browse, bapi etc. now has its' charts in their respective repository, with the expectation that the chart will evolve with the code.

When updating the chart for a component, it is useful to be able to deploy that local version of the chart within the cluster to confirm it works as expected.

To do so, ensure the local image for a component is built. Run the following command in the directory of the component:

`docker-compose build`

To use a file repository instead of the Azure Container Registry (ACR), edit the following file in the `platform-helm` repository:

 `src/buyingcatalogue/Chart.yaml`

Using ISAPI as an example, within this file, look for the section with the line:

`- name: isapi`

The `version` will need to be changed to `~0.1.0` and the `repository` value will need to be altered to use a file.

Here is an example of the final settings for ISAPI with these changes:

```yaml
- name: isapi
  condition: isapi.enabled
  version: ~0.1.0           #local charts are all left at v0.1.0
  repository: "file://../../../BuyingCatalogueIdentity/charts/isapi/"  #path to isapi chart. This assumes platform-helm and BuyingCatalogueIdentity repositories are cloned to the same root folder
```

***Please remember to NOT commit this change to source control.***

For it to pick up the updated chart in the component directory, you need to run

`helm dependency update src/buyingcatalogue`

To introduce this to the local environment, you will need to amend the `local-overrides.yaml` file.

Using ISAPI as an example, add the `useLocalImage: true` line as shown below:

```yaml
isapi:
  enabled: true
  useLocalImage: true
```

Now when the local environment is launched it will contain your new version of a component.

## Tearing Down the Environment

In order to tear down the system, simply run the appropriate tear down script.

### Bash

```bash
.\tear-down-local.sh
```

### PS

```Powershell
.\tear-down-local.ps1
```
