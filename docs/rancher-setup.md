# Rancher Setup

## Add the Helm Chart Repository

Use the below helm repo add command to add the Helm chart repository that contains charts to install Rancher

```
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

## Create a Namespace for Rancher

We’ll need to define a Kubernetes namespace where the resources created by the Chart should be installed. This should always be cattle-system:

```
kubectl create namespace cattle-system
```

## Install cert-manager

### Install the CustomResourceDefinition resources separately

```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml
```

### Create the namespace for cert-manager

```
kubectl create namespace cert-manager
```

### Add the Jetstack Helm repository

```
helm repo add jetstack https://charts.jetstack.io
```

### Update your local Helm chart repository cache

```
helm repo update
```

### Install the cert-manager Helm chart

```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.0.4
```

Once you’ve installed cert-manager, you can verify it is deployed correctly by checking the cert-manager namespace for running pods:
```
kubectl get pods --namespace cert-manager
```
When each of the pods returned have a status of `Running`

## Install Rancher

```
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=rancher.localhost
```

Wait for Rancher to be rolled out:

```
kubectl -n cattle-system rollout status deploy/rancher
```

When the rollout has finished successfully you will be able to navigate to https://rancher.localhost.

## Setting projects in Rancher

Rancher groups namespaces under Projects, so that linked pieces of work can be grouped easily. To create a new project:

1. Select `Projects/Namespaces` from the navbar
2. Click `Add Project` in the top right
3. Name your project (i.e. `BuyingCatalogue`)
4. Navigate back to the `Projects/Namespaces` page
5. Check any number of namespaces and click `Move` above the list
6. Select the new project and click `Move` in the modal that appears

This will group your namespaces and deployments to enable easy to view pages and stats. You can view everything in a project by hovering over the dropdown in the navbar (leftmost item), hovering over `local` and selecting the project in the right of the dropdown area.

## Enabling Monitoring

Rancher can add monitoring via Graphana with very little effort. Follow the steps below to achieve this.

1. Hover over the dropdown in the navbar
2. Click `local` in the dropdown area (you should see 3 charts on screen after this)
3. Click `Enable Monitoring` in the top right
4. If you have available CPU and Memory, you will be able to click `Enable` at the bottom of the Enable Monitoring page

This will provide on the fly stats, as well as a history of the relative performance in the cluster