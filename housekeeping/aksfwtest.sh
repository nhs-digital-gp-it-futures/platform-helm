#!/bin/bash
FWStatus=$(az aks show -n gpitfutures-development-aks -g gpitfutures-development-rg-aks --query apiServerAccessProfile.authorizedIpRanges)
if [ -n ${FWStatus} ]; then 
echo "AKS FW is Running"; else  echo "AKS FW is off"; fi 













if [[ -z "$FWStatus" ]]; then echo "empty"; else echo "not"; fi


