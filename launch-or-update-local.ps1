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
        [switch]$r=$true
    )

$chart="src/buyingcatalogue"

if (($useRemote -ne "false") -and ($r -eq $false))
{
    if(($updateCharts -ne "false"))
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
