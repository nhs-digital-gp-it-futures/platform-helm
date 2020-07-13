###########################
### Housekeeping        ###
### usage:              ###
###  ./housekeeping.ps1 ###
###########################

param(
        [Parameter()] 
        [string]$dbServer="gpitfutures-dev-sql-pri",
        [Parameter()]  
        [string]$resourceGroup="gpitfutures-dev-rg-sql-pri",
        [Parameter(Mandatory)]  
        [string]$azureStorageConnectionString,
        [Parameter()] 
        [string]$debugging=$true
)

### Functions

function remove-KubernetesResources {
    param(
        [Parameter(Mandatory)]   
        [string]$branchNamespace,
        [Parameter()] 
        [string]$codeDebug=$true
    )    

    if ($codeDebug -eq $false){
        kubectl delete ns $branchNamespace
    }
    else {
        write-host "DEBUG: kubectl delete ns $branchNamespace"
    }
}

function remove-BlobStoreContainers {
    param(
        [Parameter(Mandatory)]   
        [string]$branchNamespace,
        [Parameter(Mandatory)]  
        [string]$storageConnectionString,
        [Parameter()] 
        [string]$codeDebug=$true
    ) 

    if ($codeDebug -eq $false){
        az storage container delete --name '$branchNamespace-documents' --connection-string '$storageConnectionString'
    }
    else {
        write-host "DEBUG: az storage container delete --name '$branchNamespace-documents' --connection-string '$storageConnectionString'"
    }
}

function remove-Databases {
    param(
        [Parameter(Mandatory)]   
        [string]$branchNamespace,
        [Parameter(Mandatory)]  
        [string]$databaseServer,
        [Parameter(Mandatory)]  
        [string]$rg,
        [Parameter()]  
        [object]$services=@("bapi", "isapi", "ordapi"),
        [Parameter()] 
        [string]$codeDebug=$true
    ) 

    $databaseNames=@()
    foreach ($service in $services){
        $databaseNames += "bc-$branchNamespace-$service"
    }

    foreach ($dbName in $databaseNames){
        if ($codeDebug -eq $false){
            az sql db delete --name "$dbName" --resource-group "$rg" --server "$dbServer" --yes
        }
        else{
            write-host "DEBUG: az sql db delete --name '$dbName' --resource-group '$rg' --server '$dbServer' --yes"
        }
    }    
}

### Error checking

if (!(az account show)){
    Write-host "Not logged in to Azure"
    #Exit 1
}

if (!(kubectl get namespaces)){
    Write-host "Not logged in to Kubernetes Cluster"
    #Exit 1
}
else {
    $namespaces=kubectl get namespaces
}

if (!(git branch -r)){
    Write-host "Not connected to git repo"
    #Exit 1
}
else{
    $gitBranches=git branch -r
}

### Global Variables

$inactiveNamespaces = @()

### Determine inactive namespaces

foreach ($line in $namespaces){
    if ($line -like "bc-*" -and $line -notlike "bc-merge*"){
        if ($gitBranches -match $line.split("-")[1]){
            write-host "active branch:"$line.split(" ")[0] "found" -ForegroundColor Green
        }
        else {
            write-host "inactive branch:"$line.split(" ")[0] -ForegroundColor Red
            $inactiveNamespaces += $line.split(" ")[0]
        }
    }
}



foreach ($inactiveNs in $inactiveNamespaces){
    if ($codeDebug -ne $false){
        write-host "`nDEBUGGING...."
    }

    remove-KubernetesResources -branchNamespace $inactiveNs -debug $debugging
    remove-BlobStoreContainers -branchNamespace $inactiveNs -storageConnectionString $azureStorageConnectionString -debug $debugging
    remove-Databases -branchNamespace $inactiveNs -databaseServer $dbServer -rg $resourceGroup -debug $debugging
}

