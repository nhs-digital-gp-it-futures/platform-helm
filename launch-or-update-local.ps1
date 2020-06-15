####################################################
### Deploy local cluster                         ###
### usage:                                       ###
###  ./launch-or-update-local.ps1                ###
### or without downloading updates...            ###
###  ./launch-or-update-local.ps1 -update false  ###
###  ./launch-or-update-local.ps1 -u false       ###
####################################################

param(
        [Parameter()]
        [ValidateSet('true','false','')]
        [string]$update,
        [Parameter()]
        [ValidateSet('true','false','')]
        [string]$u
    )
    
$chart="src/buyingcatalogue"

if ($update -ne "false" -and $u -ne "false")
{  
    write-host "Updating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "Deploying helm charts"
helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
