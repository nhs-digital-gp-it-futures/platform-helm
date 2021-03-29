param(
        [Parameter()]
        [ValidateSet('true','false')]
        [switch]$q=$false
    )

$scriptPath=".\src\scripts\pscore"
$context=kubectl config current-context

if ($context -ne "docker-desktop") {
    Write-Host "$context is not a local context!"
    exit 1
}

$nsCheck = kubectl get namespace buyingcatalogue
if (!($nsCheck)) {
    Write-Host "Namespace does not exist"
    exit 1
}

$clusterStatus=kubectl get pods -n buyingcatalogue -o json | ConvertFrom-Json | select-object -expandproperty items
if (!($clusterStatus)) {
    Write-Host "Cluster has not been deployed yet"
    exit 1
}

$clusterArray = @()

foreach ($pod in $clusterStatus) {
    $podStatus = @{}
    $podStatus.name = $pod.status.containerStatuses.name
    $podStatus.podName = $pod.metadata.name
    $podStatus.status = $pod.status.containerStatuses.started
    $podStatus.state = $pod.status.phase
    $podStatus.healthy = $pod.status.containerStatuses.ready
    $podStatus.restartCount = $pod.status.containerStatuses.restartCount
    $podStatus.podLogs = $pod
    $podStatus.terminatedStatus = $pod.status.containerStatuses.state.terminated.reason

    if ($podStatus.terminatedStatus -ne "Completed") {
        $clusterArray += [pscustomobject]$podStatus
    }
}

write-host "--- Cluster Pod Status ---"
$clusterArray | select-object name,healthy,state,restartCount | format-table -AutoSize

if (!($q)) {
    $logsgenertated=@()

    foreach ($line in $clusterArray) {
        if (($line.healthy -ne $True) -or ($line.status -ne $True)) {
            if (($line.healthy -eq $False) -and ($line.status -eq $True)) {
                write-host "Potential Issue found in $($line.name)"
                kubectl logs --tail=100 $($line.podName) -n buyingcatalogue > $scriptPath\logs\$($line.podName).txt
                $logsgenertated+="$scriptPath\logs\$($line.podName).txt"
            }
        }
    }

    # Get URL Status
    $URLStatus = @()

    $siteStatus = @{}
    $siteStatus.url = "host.docker.internal"
    $siteStatus.port = 443
    $siteStatus.name = "host.docker.internal"
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 443
    $siteStatus.name = "localhost (https)" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 80
    $siteStatus.name = "localhost (http)"
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 5100
    $siteStatus.name = "BAPI" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 5101
    $siteStatus.name = "DAPI" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 5102
    $siteStatus.name = "ISAPI" 
    $siteStatus.link = "https://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 5103
    $siteStatus.name = "OAPI" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 5104
    $siteStatus.name = "ORDAPI" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 3000
    $siteStatus.name = "PB" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 3005
    $siteStatus.name = "ADMIN" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 3006
    $siteStatus.name = "OF" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    $siteStatus = @{}
    $siteStatus.url = "localhost"
    $siteStatus.port = 1080
    $siteStatus.name = "EMAIL" 
    $siteStatus.link = "http://$($siteStatus.url):$($siteStatus.port)"
    $siteStatus.functional=Test-NetConnection -ComputerName $siteStatus.url -Port $siteStatus.port | select-object -ExpandProperty TcpTestSucceeded
    $URLStatus += [pscustomobject]$siteStatus

    write-host "--- URL Status ---"
    $URLStatus | select-object name, link, functional | format-table -AutoSize 

    write-host "The following (Tailed) logs for unhealthy components have been written:"
    $logsgenertated | foreach-object {$_} | Out-String
}
