param(
    [Parameter()]  
    [string]$directories,
    [Parameter(Mandatory)]  
    [string]$azureStorageConnectionString,
    [Parameter()] 
    [string]$debugging="true"
)

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-ActiveGitBranches
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-BlobStoreContainers
Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function remove-BlobStoreContainers

### Error checking

if (!(az account show)){
    Write-host "ERROR: Not logged in to Azure"
    Exit 1
}

### Global Variables

$gitBranches = @()
$inactiveContainers = @()
$jobLength = 4
$jobLengthExt = 5

$gitBranches = get-ActiveGitBranches -directories $directories

#####################################################
### Cleardown Leftover Storage Account Containers ###
#####################################################

write-host "`nStorage Account Container cleardown status`n"

$containers = get-BlobStoreContainers -storageConnectionString $azureStorageConnectionString

foreach ($line in $containers){ 
    if (($line -replace '\D+').length -gt 3){
        try
        {
            $job = ($line -replace '\D+').Substring(0,$jobLengthExt)
        }
        catch
        {
            $job = ($line -replace '\D+').Substring(0,$jobLength)
        }

        if ($gitBranches -match $job){
            write-host "active container: $line found" -ForegroundColor Green
        }
        else {
            write-host "inactive container: $line" -ForegroundColor Red
            $inactiveContainers += $line.Substring(0, $line.lastIndexOf('-'))
        }
        $job=""
    }
}

foreach ($inactiveCont in ($inactiveContainers | select-object -Unique)){
    if ($debugging -ne "false"){
        write-host "`nDEBUGGING Container Cleardown...."
    }

    remove-BlobStoreContainers -branchNamespace $inactiveCont -storageConnectionString $azureStorageConnectionString -codeDebug "$debugging"
}

