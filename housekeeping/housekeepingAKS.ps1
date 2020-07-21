param(
    [Parameter(Mandatory)]  
    [string]$azureStorageConnectionString,
    [Parameter()]  
    [string]$directories,
    [Parameter()] 
    [string]$dbServer="gpitfutures-dev-sql-pri",
    [Parameter()] 
    [string]$resourceGroup="gpitfutures-dev-rg-sql-pri",
    [Parameter()] 
    [string]$debugging=$true
)

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-ActiveGitBranches
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-KubernetesResources
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-BlobStoreContainers
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-Databases


### Error checking

if (!(az account show)){
    Write-host "ERROR: Not logged in to Azure"
    Exit 1
}

if (!(kubectl get namespaces)){
    Write-host "ERROR: Not logged in to Kubernetes Cluster"
    Exit 1
}
else {
    $namespaces=kubectl get namespaces
}

### Global Variables

$gitBranches = @()
$inactiveNamespaces = @()

$gitBranches = get-ActiveGitBranches -directories $directories

#########################################
### Cleardown Kubernetes environments ###
#########################################

write-host "`nKubernetes branch cleardown status`n"

foreach ($line in $namespaces){ 
    $ns = $line.split(" ")[0]
    $job = $ns.split("-")[1]

    if (($ns -like "bc-*" -or $ns -like "feature-*") -and $ns -notlike "bc-merge*"){
        
        if ($gitBranches -match $job){
            write-host "active branch:"$ns "found" -ForegroundColor Green
        }
        else {
            write-host "inactive branch:"$ns -ForegroundColor Red
            $inactiveNamespaces += $ns
        }
    }
}

foreach ($inactiveNs in $inactiveNamespaces){
    if ($debugging -ne $false){
        write-host "`nDEBUGGING k8s Cleardown...."
    }

    remove-KubernetesResources -branchNamespace $inactiveNs -debug $debugging
    remove-BlobStoreContainers -branchNamespace $inactiveNs -storageConnectionString $azureStorageConnectionString -debug $debugging
    remove-Databases -branchNamespace "bc-$inactiveNs" -databaseServer $dbServer -rg $resourceGroup -debug $debugging
}

start-sleep 10