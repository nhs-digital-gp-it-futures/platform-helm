####################################################
### Update Charts with Latest Release            ###
### usage:                                       ###
###  ./get-latest-charts.ps1                     ###
####################################################

param(
        [Parameter()] 
        [string]$chart="src/buyingcatalogue"
    )

# Global Variables and return code
$index = 0
$ChartVersions = @()

# Update the local cache from the Repo and confirm dev repo is queried
$updaterepos=helm repo update | select-string -SimpleMatch "gpitfuturesdevacr"

if ($updaterepos)
{
    write-host "$updaterepos"
}
else
{
    write-host "`ngpitfuturesdevacr not found in helm repos`n"
    exit
}  

### Build array of versions ###
$LatestChartVersions = helm search repo gpit --devel | ConvertFrom-String -Delimiter "`t" -PropertyNames NAME,"CHART VERSION","APP VERSION",DESCRIPTION | select -Skip 1
$CurrentFile = @(Get-Content ./$chart/chart.yaml)

foreach ($line in $CurrentFile)
{
    if ($line.startswith("- name:"))
    {
        $ChartLine = @{}
        $ChartLine.name = "$line" -replace "- name: "
        $ChartLine.currentVersion = $CurrentFile[$index+2] -replace "  version: "
        # Check if it exists in the repo
        if (($LatestChartVersions -match "gpitfuturesdevacr/"+$ChartLine.name)[0])
        {
            [string]$ChartLine.latestVersion = (($LatestChartVersions -match "gpitfuturesdevacr/"+$ChartLine.name)[0] | select -ExpandProperty "Chart Version").trim()
            if ($ChartLine.latestVersion -gt $ChartLine.currentVersion)
            {
                # Update desired version to latest for component
                $CurrentFile[$index+2]="  version: " + $ChartLine.latestVersion
                $ChartLine.updated = "True"
                $ChartLine.updatedVersion = $CurrentFile[$index+2] -replace "  version: "
            }
            else 
            {
                $ChartLine.updated = "False"
            }
        }
        else 
        {
            $ChartLine.updated = "False"
        }
        $ChartVersions += [pscustomobject]$ChartLine | select name,currentVersion,latestVersion,updated,updatedVersion
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

# Remove old versions of Chart-<date>.yaml (older than 2 days)
Get-ChildItem -Path ./$chart/ Chart-*.yaml | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt ((Get-Date).AddDays(-2)) } | Remove-Item -Force
