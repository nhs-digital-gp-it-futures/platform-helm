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

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-ActiveGitBranches
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-Databases
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-Databases

### Error checking

if (!(az account show)){
    Write-host "ERROR: Not logged in to Azure"
    Exit 1
}

### Global Variables

$gitBranches = @()
$inactiveDatabases = @()

#$directories="platform-helm","platform"
$gitBranches = get-ActiveGitBranches -directories $directories

########################################
### Cleardown Leftover SQL Databases ###
########################################

write-host "`nSQL Database cleardown status`n"

$sqlDatabases = get-Databases -databaseServer $dbServer -rg $resourceGroup

foreach ($line in $sqlDatabases){ 
    $job = ($line -replace '\D+').Substring(0,4)

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
    }

    remove-Databases -branchNamespace $inactiveDBs -databaseServer $dbServer -rg $resourceGroup -debug $debugging
}

