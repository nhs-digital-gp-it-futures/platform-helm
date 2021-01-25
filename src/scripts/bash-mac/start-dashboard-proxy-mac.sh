#!/usr/local/bin/bash

echo $BASH_VERSION

echo "Starting dashboard proxy"

TOKEN=`kubectl -n kube-system describe secret default | grep token: | awk '{print $2}'`
kubectl config set-credentials docker-desktop --token=$TOKEN

DASHBOARDURL="http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=buyingcatalogue"
echo "Copy"
echo $DASHBOARDURL

kubectl proxy
