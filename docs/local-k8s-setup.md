# Installation

Depending on your machine setup please choose the most appropriate Installation Method from below

Please the relevant option:
[Windows Local](#windows-installation)
[Windows Subsystem for Linux (WSL)](#wsl-installation)
[Mac Local](#mac-installation)
[Linux Local](#linux-installation)

## Windows Installation

### Prerequisites

- Have [Docker for Desktop](https://www.docker.com/products/docker-desktop) installed and running 

### How to
- Click on the Docker Desktop icon (in the System Tray) and click 'Settings'
- Click on the 'Kubernetes' setting on the left
- Click on 'Enable Kubernetes' and allow it to be installed

You can find a visual guide for reference [here](https://www.techrepublic.com/article/how-to-add-kubernetes-support-to-docker-desktop/) 

To verify the installation was sucessful, execute the following snippet from PowerShell
```
kubectl get nodes
```

If the response looks similar to this you are good to go
```
NAME             STATUS   ROLES    AGE    VERSION
docker-desktop   Ready    master   1m     v1.14.3
```

NOTE: This is everything needed for the K8s Windows installation, [please browse back to the previous guide](run-local.md)

## WSL Installation

From the root of the repository run the `wsl-setup.sh` script located in 'docs/scripts' as su

```
sudo ./docs/scripts/wsl-setup.sh
```

To verify the installation was sucessful, execute the following snippet
```
kubectl get nodes
```

If the response looks similar to this, you are good to go
```
NAME             STATUS   ROLES    AGE    VERSION
docker-desktop   Ready    master   1m     v1.14.3
```

NOTE: This is everything needed for the K8s Windows WSL installation, [please browse back to the previous guide](run-local.md)

## Mac Installation

### Prerequisites

- Have [Docker for Desktop](https://www.docker.com/products/docker-desktop) installed and running 

### How to
- Click on the Docker Desktop icon (in the macOS panel) and click Preferences
- Click the 'Kubernetes' tab
- Click on 'Enable Kubernetes' and allow it to be installed

You can find a visual guide for reference [here](https://www.techrepublic.com/article/how-to-add-kubernetes-support-to-docker-desktop/) 

To verify the installation was sucessful, execute the following snippet from terminal
```
kubectl get nodes
```

If the response looks similar to this you are good to go
```
NAME             STATUS   ROLES    AGE    VERSION
docker-desktop   Ready    master   1m     v1.14.3
```

NOTE: This is everything needed for the K8s Mac installation, [please browse back to the previous guide](run-local.md)

## Linux Installation
To set up, please follow [this](https://kubernetes.io/docs/tasks/tools/install-minikube) tutorial

## Linux in a VM
run the `linux-vm-setup.sh` script located in the 'Scripts' directory using bash as su

```
sudo bash ./Scripts/linux-vm-setup.sh
```

# Starting the development environment
To bring the system up in your local kubernetes cluster, have a look [here](./run-local.md)