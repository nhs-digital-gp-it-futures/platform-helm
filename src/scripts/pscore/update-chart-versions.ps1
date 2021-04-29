####################################################
### Update Charts with Latest Release            ###
### usage:                                       ###
###  ./update-chart-versions.ps1                 ###
####################################################

param(
        [Parameter()] 
        [string]$chart="src/buyingcatalogue",
        [ValidateSet('master','development')]
        [string]$v='master',
        [Parameter()]
        [switch]$pbOnly=$false,
        [Parameter()]
        [string]$excludeComponent
    )

# Global Variables and return code
$index = 0
$chartVersions = @()
$versionSource = If ($v -eq "master") {$null} Else {"--devel"} 
$gitFlow=@(
    "isapi",
    "isapi-db-deploy",
    "oapi",
    "of"
)
#write-host $gitFlow

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
$masterChartVersions = helm search repo gpit
$currentFile = @(Get-Content ./$chart/chart.yaml)

foreach ($line in $currentFile) {
    if ($pbOnly) {
        if ($line -eq "- name: pb") {
            $updatedPB = ($masterChartVersions -match "gpitfuturesdevacr/pb")[0].split("`t")[1] -replace " ", ""
            $currentFile[$index+2] = "  version: " + $updatedPB
        }
    }
    else { 
        if ($line.startswith("- name:")) {
            $chartLine = @{}
            $chartLine.name = "$line" -replace "- name: "
            $chartLine.currentVersion = $currentFile[$index+2] -replace "  version: "
            if ((!($excludeComponent)) -or $line -notlike "- name: $excludeComponent*") {
                # Check if it exists in the repo
                if (($latestChartVersions -match "gpitfuturesdevacr/"+$chartLine.name)[0]) {
                    $latestCompVersion = ($latestChartVersions -match "gpitfuturesdevacr/"+$chartLine.name)[0].split("`t")[1] -replace " ", ""
                    
                    if ($gitFlow -match $chartLine.name -or $latestCompVersion -gt 2) {
                        [string]$chartLine.latestVersion = $latestCompVersion
                    }
                    else {
                        [string]$chartLine.latestVersion = ($masterChartVersions -match "gpitfuturesdevacr/"+$chartLine.name)[0].split("`t")[1] -replace " ", ""
                    }
                    
                    if ($chartLine.latestVersion -ne $chartLine.currentVersion) {
                        # Update desired version to latest for component
                        $currentFile[$index+2]="  version: " + $chartLine.latestVersion
                        $chartLine.updated = "True"
                        $chartLine.updatedVersion = $currentFile[$index+2] -replace "  version: "
                    }
                    else {
                        $chartLine.updated = "False"
                    }
                }
                else {
                    $chartLine.updated = "False"
                }
            }
            else {
                $chartLine.updated = "False"
            }
            $chartVersions += [pscustomobject]$chartLine | select name,currentVersion,latestVersion,updated,updatedVersion
        }
    }
    $index = $index+1
}

if ($pbOnly)
{
    "`nPublic Browse Updated`n"
}
else
{
    $chartVersions | ft
}

$dateStamp = get-date -uformat "%Y-%m-%d"
if (!(Test-Path "./$chart/Chart-$dateStamp.yaml"))
{
    Rename-Item -Path ./$chart/Chart.yaml -NewName "Chart-$dateStamp.yaml"
}

$updatedFile = @()
foreach ($line in $currentFile)
{
    $updatedLine=$line.replace("`n","").replace("`r","")
    $updatedFile+=$updatedLine
}

set-content -path ./$chart/Chart.yaml -Value $updatedFile -force

# Remove old versions of Chart-<date>.yaml (older than 2 days)
Get-ChildItem -Path ./$chart/ Chart-*.yaml | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt ((Get-Date).AddDays(-2)) } | Remove-Item -Force
