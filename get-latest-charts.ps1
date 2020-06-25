####################################################
### Update Charts with Latest Release            ###
### usage:                                       ###
###  ./get-latest-charts.ps1                     ###
####################################################

param(
        [Parameter()] 
        [string]$chart="src/buyingcatalogue",
        [Parameter()] 
        [switch]$m
    )

# Global Variables and return code
$index = 0
$chartVersions = @()
$versionSource = If ($m) {$null} Else {"--devel"} #If -m flag is present, grab the latest master versions, if not, use the --devel flag

# Update the local cache from the Repo and confirm dev repo is queried
$updateRepos=helm repo update | select-string -SimpleMatch "gpitfuturesdevacr"

if ($updateRepos)
{
    write-host "$updateRepos"
}
else
{
    write-host "`ngpitfuturesdevacr not found in helm repos`n"
    exit
}  

### Build array of versions ###
$latestChartVersions = helm search repo gpit $versionSource 
$currentFile = @(Get-Content ./$chart/chart.yaml)

foreach ($line in $currentFile)
{
    if ($line.startswith("- name:"))
    {
        $chartLine = @{}
        $chartLine.name = "$line" -replace "- name: "
        $chartLine.currentVersion = $currentFile[$index+2] -replace "  version: "
        # Check if it exists in the repo
        if (($latestChartVersions -match "gpitfuturesdevacr/"+$chartLine.name)[0])
        {
            [string]$chartLine.latestVersion = ($latestChartVersions -match "gpitfuturesdevacr/"+$chartLine.name)[0].split("`t")[1]  
            if ($chartLine.latestVersion -ne $chartLine.currentVersion)
            {
                # Update desired version to latest for component
                $currentFile[$index+2]="  version: " + $chartLine.latestVersion
                $chartLine.updated = "True"
                $chartLine.updatedVersion = $currentFile[$index+2] -replace "  version: "
            }
            else 
            {
                $chartLine.updated = "False"
            }
        }
        else 
        {
            $chartLine.updated = "False"
        }
        $chartVersions += [pscustomobject]$chartLine | select name,currentVersion,latestVersion,updated,updatedVersion
    }

    $index = $index+1
}

$chartVersions | ft

$dateStamp = get-date -uformat "%Y-%m-%d"
if (!(Test-Path "./$chart/Chart-$dateStamp.yaml"))
{
    Rename-Item -Path ./$chart/Chart.yaml -NewName "Chart-$dateStamp.yaml"
}

set-content -path ./$chart/Chart.yaml -Value $currentFile -force

# Remove old versions of Chart-<date>.yaml (older than 2 days)
Get-ChildItem -Path ./$chart/ Chart-*.yaml | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt ((Get-Date).AddDays(-2)) } | Remove-Item -Force
