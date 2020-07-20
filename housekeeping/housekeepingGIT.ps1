param(
    [Parameter()]  
    [string]$directories
)

Import-Module -Name "$PSScriptRoot/sharedFunctions/sharedFunctions.psm1" -Function get-ActiveGitBranches

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

$gitBranches = get-ActiveGitBranches -directories $directories

#############################
### List Active Git Repos ###
#############################

write-host "`nActive Git Repos`n"

foreach ($line in $gitBranches | select-object -Unique | sort){ 
    $repo=$line.substring(7) 
    write-host "git branch:"$repo -ForegroundColor Blue
}
