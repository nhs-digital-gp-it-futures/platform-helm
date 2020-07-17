param(
    [Parameter(Mandatory)]  
    [string]$azureStorageConnectionString,
    [Parameter()]  
    [array]$directories,
    [Parameter()] 
    [string]$dbServer="gpitfutures-dev-sql-pri",
    [Parameter()] 
    [string]$resourceGroup="gpitfutures-dev-rg-sql-pri",
    [Parameter()] 
    [string]$debugging=$true
)

#Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-KubernetesResources
#Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-BlobStoreContainers
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-KubernetesResources
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-Databases
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
#$inactiveNamespaces = @()
$inactiveDatabases = @()

#if (!($directories))
#{
#    git fetch
#    if (!(git branch -r))
#    {
#        Write-host "Not connected to git repo"
#        Exit 1
#    }
#    else
#    {
#        $gitBranches=git branch -r
#    }
#}
#
#if ($directories)
#{
#   foreach ($gitDir in $directories)
#   {
#        set-location -path .\$gitDir
#        #write-host "`nDEBUG: $gitDir"
#        git fetch
#        foreach ($gitbranch in (git branch -r))
#        {  
#            $gitBranches += $gitbranch.trim()
#            #write-host "DEBUG: -"$gitbranch.trim()
#        }
#        set-location -path ..\
#   } 
#}

$gitBranches = get-KubernetesResources -directories $directories

#if ($debugging -ne $false){
#    write-host "`nDEBUGGING...."
#
#    get-childitem | write-host 
#
#    foreach ($output in $gitBranches)
#    {
#        #write-host "$output"
#    }
#}

########################################
### Cleardown Leftover SQL Databases ###
########################################

write-host "`nSQL Database cleardown status`n"

$sqlDatabases = get-Databases -databaseServer $dbServer -rg $resourceGroup
#$sqlDatabases = get-Databases -databaseServer $dbserver -rg $rg 

foreach ($line in $sqlDatabases){ 
    $job = $line -replace '\D+' ###########################################"bc-feature-8071-replace-k8s-nodes-ordapi" returns 80718
    #write-host $line
    #write-host $job

    if ($gitBranches -match $job){
        write-host "active database: $line found" -ForegroundColor Green
    }
    else {
        write-host "inactive database: $line" -ForegroundColor Red
        $inactiveDatabases += $line.Substring(0, $line.lastIndexOf('-'))
    }
}

foreach ($inactiveDBs in ($inactiveDatabases | select-object -Unique)){
    if ($debugging -ne $false){
        write-host "`nDEBUGGING SQL Cleardown...."
        #write-host "DBs to cleardown are:"$inactiveDBs
    }

    remove-Databases -branchNamespace $inactiveDBs -databaseServer $dbServer -rg $resourceGroup -debug $debugging
}

