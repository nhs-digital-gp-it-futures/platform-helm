### Housekeeping Functions

function get-ActiveGitBranches {
    param(
        [Parameter(Mandatory)]   
        [string]$directories
    )    
    
    $gitBranches = @()
    
    if (!($directories)){
        git fetch
        if (!(git branch -r)){
            Write-host "Not connected to git repo"
            Exit 1
        }
        else{
            $gitBranches=git branch -r
        }
    }

    if ($directories){
        foreach ($gitDir in $directories -split(",")){
            set-location -path .\$gitDir
            git fetch
            foreach ($gitbranch in (git branch -r))
            {  
                $gitBranches += $gitbranch.trim()
            }
            set-location -path ..\
        } 
    }
    Return $gitBranches
}

function remove-KubernetesResources {
    param(
        [Parameter(Mandatory)]   
        [string]$branchNamespace,
        [Parameter()] 
        [string]$codeDebug="true"
    )    

    if ($codeDebug -eq "false"){
        kubectl delete ns $branchNamespace
    }
    else {
        write-host "DEBUG: kubectl delete ns $branchNamespace"
    }
}

function get-Databases {
    param(
        [Parameter(Mandatory)]  
        [string]$databaseServer,
        [Parameter(Mandatory)]  
        [string]$rg
    ) 

    $databaseNames=@()
    $databaseNames = az sql db list --resource-group "$rg" --server "$databaseServer"--output json | convertfrom-json 

    return $databaseNames | Select-Object -ExpandProperty name | Where-Object {$_ -like "bc-*"} | sort-object
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
        [string]$codeDebug="true"
    ) 

    $services=@("bapi","isapi","ordapi")

    $databaseNames=@()
    foreach ($service in $services){
        $databaseNames += "$branchNamespace-$service"
    }

    foreach ($dbName in $databaseNames){
        if ($codeDebug -eq "false"){
            az sql db delete --name "$dbName" --resource-group "$rg" --server "$databaseServer" --yes
        }
        else{
            write-host "DEBUG: az sql db delete --name '$dbName' --resource-group '$rg' --server '$databaseServer' --yes"
        }
    }    
}

function get-BlobStoreContainers {
    param(
        [Parameter(Mandatory)]  
        [string]$storageConnectionString
    ) 

    $containerNames = az storage container list --connection-string "$storageConnectionString" --connection-string "$storageConnectionString"  --output JSON | convertfrom-json #--name "$branchNamespace-documents" 

    return $containerNames | Select-Object -ExpandProperty name | Where-Object {$_ -like "bc-*" -or $_ -like "feature-*"} | sort-object    
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

    if ($codeDebug -eq "false"){
        az storage container delete --name "$branchNamespace-documents" --connection-string "$storageConnectionString"
    }
    else {
        write-host "DEBUG: az storage container delete --name '$branchNamespace-documents' --connection-string '<storageConnectionString>'"
    }
}

function remove-PersistentVolume {
    param(
        [Parameter(Mandatory)]   
        [string]$volumeName,
        [Parameter()] 
        [string]$codeDebug="true"
    ) 

    if ($codeDebug -eq "false"){
        "delete"
    }
    else {
        write-host "DEBUG: kubectl delete pv $volumeName"
        #write-host "DEBUG: az storage container delete --name '$branchNamespace-documents' --connection-string '<storageConnectionString>'"
    }
}

function remove-ShareVolume {
    param(
        [Parameter(Mandatory)]   
        [string]$volumeName,
        [Parameter(Mandatory)]   
        [string]$resourceGroup,
        [Parameter()] 
        [string]$codeDebug="true"
    ) 

    $saName=$(az storage account list --resource-group $resourceGroup | ConvertFrom-Json | select -ExpandProperty name)
    $saConnectionString=$(az storage account show-connection-string --name $saName --resource-group $resourceGroup --query connectionString -o tsv)

    if ($codeDebug -eq "false"){
        "delete"
    }
    else {
        write-host "DEBUG: az storage share delete --name "kubernetes-dynamic-$volumeName" --connection-string <storageConnectionString>"
        az storage share exists --name "kubernetes-dynamic-$volumeName" --connection-string $saConnectionString
    }
}