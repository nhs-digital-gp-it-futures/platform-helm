# Running Locally

This process is designed to easily allow a developer to spin up the current environment, and easily work on component(s), while having the rest of the system in place.

## System Setup

Instructions expect you to be in the local-helm directory of the platform repository.
The following steps are needed to be able to run the system successfully:

### Setup Kubernetes

To begin, make sure you have kubernetes running locally as per the [Kubernetes Dev Setup Instructions](../Docs/DevSetup/local-k8s-setup.md)

### Setup Helm

Note that this system relies upon helm charts. Instructions on how to install helm can be found [here](https://helm.sh/docs/intro/install/).

### Set up Ingress

Ingress is required for the identity api to work. To enable the ingress, execute these two snippets in shell of your preference

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm install bc stable/nginx-ingress
```

### Add Namespace

Create the buying catalogue namespace - `kubectl apply -f local-namespace.yml`

### Add Container Registry Secret

Create a secret in kubernetes to access the private container registry, as per the [Connect Local Kubernetes with our Private Container Registry Instructions](k8s-private-registry.md).

### (Optional) Run Dashboard

You may wish to run the dashboard. Instructions are [here](run-dashboard.md).

### (Optional) Run Rancher

You may wish to run Rancher rather than the dashboard. Rancher provide a step by step walkthrough to install, which is linked [here](rancher-setup.md)

## Install Dependencies

The umbrella chart depends on some standard charts. These need to be added by running `helm dependency update src/buyingcatalogue`.

## Launching, Updating the Environment

In order to launch or update the system to the latest built images or chosen config, simply run the appropriate launch script. It will run until torn down, even being restarted automatically once kubernetes is running again after a system restart.

#### Bash

```bash
./launch-or-update-local.sh
```

#### PS

```Powershell
./launch-or-update-local.ps1
```

The script will start [all services available on these ports](#configuration-overview) on localhost, or update them if they are running.

Ingress is also set up, so the front ends are exposed on localhost, as they would be when running in production.

### Overrides 
Overrides in [local-overrides.yaml](../local-overrides.yaml) can be set to choose whether to run a component in Kubernetes, or to consider it as running on the developers machine. When a service is disabled, anything that uses that service routes out to the developers machine, using `host.docker.internal` or `docker.for.mac.localhost` for mac.

By default cluster spins up containers ~~from latest images built from development branches ~~ with the latest specified versions. You can, however, override this and use a locally build image.

```yaml
mp:
  enabled: true
  useLocalImage: true
```

## Tearing Down the Environment

In order to tear down the system, simply run the appropriate tear down script.

#### Bash

```bash
.\tear-down-local.sh
```

#### PS

```Powershell
.\tear-down-local.ps1
```
