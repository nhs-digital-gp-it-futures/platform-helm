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

# Check context is docker dashboard
$context = kubectl config current-context
if ($context -ne "docker-desktop")
{
    write-host "Not running in the local context - please switch to docker desktop"
    write-host "Exiting...."
    start-sleep 5
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

if (($useRemote -ne "false") -and ($r -eq $false))
{
    if(($updateCharts -ne "false") -and ($u -ne $false))
    {    
        if (($latest -ne "false") -and ($l -eq $false))
        {
            write-host "Getting Latest Chart Versions..."
            invoke-expression -Command "./update-chart-versions.ps1 -chart $chart -v development"
        }
        else
        {
            write-host "Getting Master Chart Versions..."
            invoke-expression -Command "./update-chart-versions.ps1 -chart $chart -v master"
        }
    }

    write-host "`nUpdating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "`nDeploying helm charts"
helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
