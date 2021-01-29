# Rancher Setup

## Setup instructions modification
When using Rancher, the recommended certificate option is to use Rancher generated certificates. However, there is a modification to the step in the provided [instructions](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/). 

In [step 6](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/#6-install-rancher-with-helm-and-your-chosen-certificate-option) The Hostname for Rancher should be set to `hostname=rancher.localhost`, as shown in the below script

```
# Windows: 
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=rancher.localhost

# Mac
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=<TBC>
```

This will open Rancher on https://rancher.localhost when all steps have been completed.

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