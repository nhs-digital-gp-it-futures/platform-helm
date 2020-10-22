param(
    #[Parameter(Mandatory)]  
    #[string]$azureStorageConnectionString,
    # [Parameter()]  
    # [string]$directories,
    # [Parameter()] 
    # [string]$dbServer="gpitfutures-dev-sql-pri",
    [Parameter()] 
    [string]$resourceGroup="gpitfutures-dev-rg-aks-pool",
    [Parameter()] 
    [bool]$debugging=$true
)

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-PersistentVolume -force
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-ShareVolume -force

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
    $namespaces=(kubectl get namespaces --output JSON | convertfrom-json).items.metadata.name
}

### Global Variables

$gitBranches = @()
# $inactiveNamespaces = @()

# $gitBranches = get-ActiveGitBranches -directories $directories

write-host "`nKubernetes Persistent Volume cleardown status`n"

###############################################
### Cleardown Kubernetes Persistent Volumes ###
###############################################

$boundVolumes=@()
$inactiveVols=@()

foreach ($namespace in $namespaces)
{
    $boundVolumes += (kubectl get pvc -n $namespace --output JSON | convertfrom-json).items.spec.volumeName
}

$persistentVolumes = (kubectl get pv --output JSON | convertfrom-json).items

foreach ($volume in $persistentVolumes){
    if ($boundVolumes -notcontains $volume.metadata.name){
        write-host $volume.metadata.name
        write-host $volume.status.phase

        $inactiveVols+=$volume.metadata.name
        remove-PersistentVolume -volumeName $volume.metadata.name -codeDebug $debugging
        remove-ShareVolume -volumeName $volume.metadata.name -resourceGroup "$resourceGroup" -codeDebug
    }
}

start-sleep 10