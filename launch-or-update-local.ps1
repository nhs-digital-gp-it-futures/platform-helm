####################################################
### Deploy local cluster                         ###
### usage:                                       ###
###  ./launch-or-update-local.ps1                ###
### or without downloading updates...            ###
###  ./launch-or-update-local.ps1 -update false  ###
###  ./launch-or-update-local.ps1 -u             ###
####################################################

param(
        [Parameter()]
        [ValidateSet('true','false')]
        [string]$update,
        [Parameter()]
        [switch]$u=$false
    )
    
# -u, --update [true|false]

$chart="src/buyingcatalogue"

if (($update -ne "false") -and ($u -eq $false))
{  
    write-host "Updating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "Deploying helm charts"
helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
