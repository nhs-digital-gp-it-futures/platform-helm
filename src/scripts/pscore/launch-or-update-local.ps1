##########################################################
### Deploy local cluster                               ###
### usage:                                             ###
###  ./launch-or-update-local.ps1                      ###
###                                                    ###
### without setting repo latest versions               ###
###  ./launch-or-update-local.ps1 -latest false        ###
###  ./launch-or-update-local.ps1 -l                   ###
###                                                    ###
### without downloading updates for set versions       ###
###  ./launch-or-update-local.ps1 -updateCharts false  ###
###  ./launch-or-update-local.ps1 -u                   ###
###                                                    ###
### without refreshing at all...                       ###
###  ./launch-or-update-local.ps1 -r                   ###
###  ./launch-or-update-local.ps1 -useRemote false     ###
##########################################################

param(
        [Parameter()]
        [ValidateSet('true','false')]
        [string]$latest,
        [Parameter()]
        [switch]$l=$false,
        [ValidateSet('true','false')]
        [string]$useRemote,
        [Parameter()]
        [switch]$r=$false,
        [ValidateSet('true','false')]
        [string]$updateCharts,
        [Parameter()]
        [switch]$u=$false
    )

# Parameters   
$chart="src/buyingcatalogue"
$namespace="buyingcatalogue"

# Error Checking

# Check context is docker dashboard
$context = kubectl config current-context
if ($context -ne "docker-desktop")
{
    write-host "Not running in the local context - please switch to docker desktop" -ForegroundColor yellow
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check docker is running 
$docker = kubectl get nodes
if (!($docker))
{
    write-host "`nDocker is not running on this computer - please investigate" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check if Ingress is installed
$helmDefaultNS=@(helm list -A -q)
if ($helmDefaultNS -notcontains "bc") {
    Write-Host "Ingress has not been setup yet - please set up this component first before continuing" -ForegroundColor red
    exit 1
}

# Add namespace if missing
$namespacePresent = kubectl get namespace $namespace
if (!($namespacePresent))
{
    kubectl apply -f .\local-namespace.yml
}

# Check for Azure repo creds
$regCredentials=kubectl get secret regcredlocal -n $namespace
if (!($regCredentials))
{
    write-host "`nMissing Credentials for ACR - please follow instructions in docs\k8s-private-registry.md"
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check for Buying Catalogue Helm Repo
$helmRepoList=helm repo list -o json | ConvertFrom-Json
if ($helmRepoList.name -notcontains "gpitfuturesdevacr")
{
    write-host "`nMissing Buying Catalogue Repo"
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check for Missing templates from previous cancelled sessions
if (get-childitem -path "$chart/tmpcharts" -ErrorAction SilentlyContinue)
{
    write-host "`nFound old temp charts -moving`n"
    Move-Item -Path $chart/tmpcharts/* $chart/charts

    if(get-childitem -path "$chart/tmpcharts" -ErrorAction SilentlyContinue)
    {
        write-host "`nUnable to clear tmp folder - exiting!`n"
        start-sleep 10
        exit 1
    }
    else {
        Remove-Item -path $chart/tmpcharts
    }
}

Clear-Host
Write-Host "# Switches Selected for run are: `n"
if (($useRemote -ne "false") -and ($r -eq $false)){
    Write-Host "# Use Remote Repo for Updates`t`t(change with -r)"
    
    if (($updateCharts -ne "false") -and ($u -eq $false)){
        Write-Host "# Download Updated Versions of Charts`t(change with -u)"

        if (($latest -ne "false") -and ($l -eq $false)){
            Write-Host "# Version of Charts to get: Development`t(change with -l)"
        }
        else {
            Write-Host "# Version of Charts to get: Master"
        }
    }    
    else {
        Write-Host "# Download Current Versions of Charts"
    }
}
else {
    Write-Host "# Use Local Files - no updates"
}

Write-Host "#`n# If this is not correct please CTRL + C now (continuing in 5 seconds)"
start-sleep 5


if (($useRemote -ne "false") -and ($r -eq $false))
{
    if(($updateCharts -ne "false") -and ($u -eq $false))
    {    
        if (($latest -ne "false") -and ($l -eq $false))
        {
            write-host "Getting Latest Chart Versions..."
            invoke-expression -Command "./src/scripts/pscore/update-chart-versions.ps1 -chart $chart -v development"
        }
        else
        {
            write-host "Getting Master Chart Versions..."
            invoke-expression -Command "./src/scripts/pscore/update-chart-versions.ps1 -chart $chart -v master"
        }
    }

    write-host "`nUpdating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "`nDeploying helm charts"
helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
