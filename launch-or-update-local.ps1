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
        [switch]$u=$false,
        [ValidateSet('true','false')]
        [string]$latest,
        [Parameter()]
        [switch]$l=$false
    )
    
# -u, --update [true|false]

$chart="src/buyingcatalogue"

### Build array of versions ###
$index = 0
$ChartVersions = @()

$LatestChartVersions = helm search repo gpit --devel | ConvertFrom-String -Delimiter "`t" -PropertyNames NAME,"CHART VERSION","APP VERSION",DESCRIPTION | select -Skip 1
$CurrentFile = @(Get-Content ./$chart/chart.yaml)

$DateStamp = get-date -uformat "%Y-%m-%d"
if (!(Test-Path "./$chart/Chart-$DateStamp.yaml") -and ($latest -ne "false") -and ($l -eq $false))
{
    Rename-Item -Path ./$chart/Chart.yaml -NewName "Chart-$DateStamp.yaml"
}

foreach ($line in $CurrentFile)
{
    if ($line.startswith("- name:") -and ($latest -ne "false") -and ($l -eq $false))
    {
        $Chartver = @{}
        $Chartver.name = "$line" -replace "- name: "
        $Chartver.currentversion = $CurrentFile[$index+2] -replace "  version: "
        # Check if it exists in the repo
        if (($LatestChartVersions -match "gpitfuturesdevacr/"+$Chartver.name)[0])
        {
            [string]$Chartver.latestversion = (($LatestChartVersions -match "gpitfuturesdevacr/"+$Chartver.name)[0] | select -ExpandProperty "Chart Version").trim()
            if ($Chartver.latestversion -gt $Chartver.currentversion)
            {
                # Update desired version to latest
                $CurrentFile[$index+2]="  version: " + $Chartver.latestversion
                $Chartver.updated = "True"
                $Chartver.updatedversion = $CurrentFile[$index+2] -replace "  version: "
            }
            else 
            {
                $Chartver.updated = "False"
            }
        }
        else 
        {
            $Chartver.updated = "False"
        }
        $ChartVersions += [pscustomobject]$Chartver | select name,currentversion,latestversion,updated,updatedversion
    }

    $index = $index+1
}

$ChartVersions | ft

set-content -path ./$chart/Chart.yaml -Value $CurrentFile -force

if (($update -ne "false") -and ($u -eq $false))
{  
    write-host "Updating Dependencies..."
    Remove-Item $chart/charts/*.tgz
    helm dependency update $chart
}

write-host "Deploying helm charts"
#helm upgrade bc $chart -n buyingcatalogue -i -f environments/local-docker.yaml -f local-overrides.yaml
