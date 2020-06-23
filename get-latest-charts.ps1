####################################################
### Update Charts with Latest Release            ###
### usage:                                       ###
###  ./get-latest-charts.ps1                     ###
####################################################

param(
        [Parameter()] 
        [string]$chart="src/buyingcatalogue"
    )

# Global Variables and retun code
$index = 0
$ChartVersions = @()

### Build array of versions ###
$LatestChartVersions = helm search repo gpit --devel | ConvertFrom-String -Delimiter "`t" -PropertyNames NAME,"CHART VERSION","APP VERSION",DESCRIPTION | select -Skip 1
$CurrentFile = @(Get-Content ./$chart/chart.yaml)

foreach ($line in $CurrentFile)
{
    if ($line.startswith("- name:"))
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
                # Update desired version to latest for component
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

$DateStamp = get-date -uformat "%Y-%m-%d"
if (!(Test-Path "./$chart/Chart-$DateStamp.yaml"))
{
    Rename-Item -Path ./$chart/Chart.yaml -NewName "Chart-$DateStamp.yaml"
}

set-content -path ./$chart/Chart.yaml -Value $CurrentFile -force
