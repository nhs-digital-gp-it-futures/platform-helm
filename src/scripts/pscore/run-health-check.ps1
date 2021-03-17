$scriptPath=".\src\scripts\pscore"
$context=kubectl config current-context

if ($context -ne "docker-desktop") {
    Write-Host "$context is not a local context!"
    exit 1
}

$nsCheck = kubectl get namespace buyingcatalogues
if (!($nsCheck)) {
    Write-Host "Namespace does not exist"
    exit 1
}

$clusterStatus=kubectl get pods -n buyingcatalogue -o json | ConvertFrom-Json | select-object -expandproperty items

$clusterArray = @()

foreach ($pod in $clusterStatus) {
    $podStatus = @{}
    $podStatus.name = $pod.status.containerStatuses.name
    $podStatus.podName = $pod.metadata.name
    $podStatus.status = $pod.status.containerStatuses.started
    $podStatus.state = $pod.status.containerStatuses.state
    $podStatus.healthy = $pod.status.containerStatuses.ready
    $podStatus.restartCount = $pod.status.containerStatuses.restartCount
    $podStatus.podLogs = $pod
    $podStatus.terminatedStatus = $pod.status.containerStatuses.state.terminated.reason

    $clusterArray += [pscustomobject]$podStatus
}

### Command Retained here to get full status ###
# $clusterArray | select name,healthy,state,terminatedStatus,restartCount | ft -AutoSize

foreach ($line in $clusterArray) {
    if (($line.healthy -ne $True) -or ($line.status -ne $True)) {
        if (($line.healthy -eq $False) -and ($line.status -eq $True)) {
            write-host "Potential Issue found in $($line.name)"
            kubectl logs --tail=100 $($line.podName) -n buyingcatalogue > $scriptPath\logs\$($line.podName).txt
        }
    }
}

write-host "`nTailed logs written to $scriptPath\logs"