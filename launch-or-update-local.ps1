#######################################################
### Deploy local cluster                            ###
### usage:                                          ###
###  ./launch-or-update-local.ps1                   ###
###                                                 ###
### without setting repo latest versions            ###
###  ./launch-or-update-local.ps1 -latest false     ###
###  ./launch-or-update-local.ps1 -l                ###
###                                                 ###
### without downloading updates for set versions    ###
###  ./launch-or-update-local.ps1 -update false     ###
###  ./launch-or-update-local.ps1 -u                ###
###                                                 ###
### without refreshing at all...                    ###
###  ./launch-or-update-local.ps1 -l -u             ###
#######################################################

param(
        [Parameter()]
        [ValidateSet('true','false')]
        [string]$update,
        [Parameter()]
        [switch]$u=$false,
        [ValidateSet('true','false')]
        [string]$latest,
        [Parameter()]
        [switch]$l=$false
    )

$chart="src/buyingcatalogue"

if (($latest -ne "false") -and ($l -eq $false))
{
    write-host "Getting Latest Chart Versions..."
    invoke-expression -Command "./get-latest-charts.ps1 -chart $chart"
}
else
{
    write-host "Getting Main Chart Versions..."
    invoke-expression -Command "./get-latest-charts.ps1 -chart $chart -m"
}


if (($update -ne "false") -and ($u -eq $false))
{  
    write-host "`nUpdating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "`nDeploying helm charts"
helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
