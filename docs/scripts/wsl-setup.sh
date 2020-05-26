#!/bin/bash

#get kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

username=$(eval "cmd.exe /c echo %username%")
ln -s /mnt/c/Users/$username/.kube ~/.kube
kubectl config use-context docker-for-desktop