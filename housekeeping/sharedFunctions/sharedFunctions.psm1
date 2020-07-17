### Housekeeping Functions

function get-KubernetesResources {
    param(
        [Parameter(Mandatory)]   
        [array]$directories
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
        foreach ($gitDir in $directories){
            set-location -path .\$gitDir
            #write-host "`nDEBUG: $gitDir"
            git fetch
            foreach ($gitbranch in (git branch -r))
            {  
                $gitBranches += $gitbranch.trim()
                #write-host "DEBUG: -"$gitbranch.trim()
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

function get-Databases {
    param(
        [Parameter(Mandatory)]  
        [string]$databaseServer,
        [Parameter(Mandatory)]  
        [string]$rg,
        [Parameter()] 
        [string]$codeDebug=$true
    ) 

    $databaseNames=@()
    $databaseNames = az sql db list --resource-group "$rg" --server "$dbServer"--output json | convertfrom-json 

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
        [string]$codeDebug=$true
    ) 

    $services=@("bapi","isapi","ordapi")

    $databaseNames=@()
    foreach ($service in $services){
        $databaseNames += "$branchNamespace-$service"
    }

    foreach ($dbName in $databaseNames){
        if ($codeDebug -eq $false){
            az sql db delete --name "$dbName" --resource-group "$rg" --server "$databaseServer" --yes
        }
        else{
            write-host "DEBUG: az sql db delete --name '$dbName' --resource-group '$rg' --server '$databaseServer' --yes"
        }
    }    
}