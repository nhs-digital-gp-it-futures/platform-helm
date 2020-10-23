param(
    [Parameter()] 
    [string]$resourceGroup="gpitfutures-dev-rg-aks-pool",
    [Parameter()] 
    [string]$debugging="true"
)

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -force

### Error checking

if (!(az account show)){
    Write-host "ERROR: Not logged in to Azure"
    Exit 1
}

if (!(kubectl get namespaces)){
    Write-host "ERROR: Not logged in to Kubernetes Cluster"
    Exit 1
}
else{
    $namespaces=(kubectl get namespaces --output JSON | convertfrom-json).items.metadata.name
}

### Global Variables

$boundVolumes=@()

write-host "`nKubernetes Persistent Volume cleardown status`n"

###############################################
### Cleardown Kubernetes Persistent Volumes ###
###############################################

foreach ($namespace in $namespaces){    
    $pvc=(kubectl get pvc -n $namespace --output JSON | convertfrom-json).items

    if ($pvc.status.phase -eq "Bound"){
        $boundVolumes += $pvc.spec.volumeName
        
        if ($debugging -eq "true")
        {
            write-host "DEBUG: PVC Found: " $pvc.spec.volumeName
        }
    }
}

$persistentVolumes = (kubectl get pv --output JSON | convertfrom-json).items

foreach ($volume in $persistentVolumes){
    if ($boundVolumes -notcontains $volume.metadata.name){
        write-host "UnBound Volume: "$volume.metadata.name -ForegroundColor Red

        remove-PersistentVolume -volumeName $volume.metadata.name -codeDebug "$debugging"
        remove-ShareVolume -volumeName $volume.metadata.name -resourceGroup "$resourceGroup" -codeDebug "$debugging"
    }
    else{
        write-host "Bound Volume: "$volume.metadata.name  -ForegroundColor Green
    }

}

start-sleep 10