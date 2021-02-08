#!/bin/bash
FWStatus=$(az aks show -n gpitfutures-development-aks -g gpitfutures-development-rg-aks --query apiServerAccessProfile.authorizedIpRanges)
if [${FWStatus} != ""]; echo "AKS FW is Running"




