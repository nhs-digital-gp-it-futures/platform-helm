### Error Checking Azure CLI

if (!(az version)) {
    write-host "Azure CLI is not installed, please install here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli "
    exit 1
}

### Get User Input

$optionSelected=$args[0]

If (!($optionSelected)) {
  write-output "`nLaunch Azure Dashboard"
  write-output "- 1: Connect to and launch the Development Dashboard in Azure"
  write-output "- 2: Connect to and launch the Test Dashboard in Azure"
  write-output "- 3: Connect to and launch the Production Dashboard in Azure"
  
  write-output "`n- 4: Connect to and launch a Standalone Dynamic Environment Dashboard in Azure"
  
  write-output "`nx: To quit script`n"

  $optionSelected=Read-Host -Prompt "Select Option from choices above "
} 

write-output "`nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
write-output "CTRL-C now if this is incorrect...`n"

Write-Host "Starting dashboard proxy"

### Set correct Kubernetes Context

if ($optionSelected -eq "x") {
    exit 0
}
elseif ($optionSelected -eq "1") {
    az account set --subscription "GP IT Futures Buying Catalogue"
    az aks get-credentials --resource-group gpitfutures-development-rg-aks --name gpitfutures-development-aks --admin --overwrite-existing
}
elseif ($optionSelected -eq "2") {
    az account set --subscription "GP IT Futures Buying Catalogue"
    az aks get-credentials --resource-group gpitfutures-preprod-rg-aks --name gpitfutures-preprod-aks --admin --overwrite-existing
}
elseif ($optionSelected -eq "3") {
    az account set --subscription "GP IT Futures Prod"
    az aks get-credentials --resource-group gpitfutures-prod-rg-aks --name gpitfutures-prod-aks --admin --overwrite-existing
}
elseif ($optionSelected -eq "4") {
    $release=Read-Host -Prompt "Enter Feature Branch Number (no characters - e.g. 12345): "
    az account set --subscription "GP IT Futures Buying Catalogue"
    az aks get-credentials --resource-group gpitfutures-feature-$release-rg-aks --name gpitfutures-feature-$release-aks --admin --overwrite-existing
}

### Error Checking Firewall Access

if (!(kubectl get namespaces --ignore-not-found=true)) {
    write-host "`nERROR: Missing Firewall permissions to Kubernetes Infrastructure - please join relevant VPN and try again"
    exit 1
}

### Display releveant Dashboard

$dashboardUrl = "https://localhost:8443/"
Set-Clipboard -Value $dashboardUrl

write-host "###"
write-host "### Dashboard Proxy Launched, please browse to $dashboardUrl to access it ignoring any certificate errors"
write-host "###"
Write-Host "### Copied '$dashboardUrl' to your clip board"
write-host "###"

if (kubectl get namespace kubernetes-dashboard --ignore-not-found=true) {
    $POD_NAME=kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}"
    kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443
}
else {
    $POD_NAME=kubectl get pods -n kube-system -l "k8s-app=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}"
    kubectl -n kube-system port-forward $POD_NAME 8443:8443
}
