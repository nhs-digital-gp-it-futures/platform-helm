#!/bin/bash
FWStatus=$(az aks show -n gpitfutures-development-aks -g gpitfutures-development-rg-aks --query apiServerAccessProfile.authorizedIpRanges)
if [ ${FWStatus} != ""]; then 
echo "AKS FW is Running" else  echo "AKS FW is off" 



