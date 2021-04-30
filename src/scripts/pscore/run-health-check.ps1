param(
        [Parameter()]
        [ValidateSet('true','false')]
        [switch]$q=$false
    )

$scriptPath=".\src\scripts\pscore"

# Check docker is current context
$context=kubectl config current-context
if ($context -ne "docker-desktop") {
    Write-Host "ERROR: $context is not a local context!" -ForegroundColor yellow
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check docker is running 
$docker = kubectl get nodes
if (!($docker)) {
    write-host "ERROR: Docker is not running on this computer - please investigate" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check for functioning host.docker.internal redirect for Kubernetes
$hostDockerInternal=Test-NetConnection -ComputerName host.docker.internal -Port 443 | select-object -ExpandProperty TcpTestSucceeded
if ($hostDockerInternal -ne "True") {
    write-host "ERROR: Critical Docker for Desktop Kubernetes port is not functioning - this usually requires re-installing Docker Desktop" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check if Ingress is installed
$helmDefaultNS=@(helm list -A -q)
if ($helmDefaultNS -notcontains "bc") {
    Write-Host "ERROR: Ingress has not been setup yet - please set up this component first before continuing" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check if Namespace is deployed
$nsCheck = kubectl get namespace buyingcatalogue
if (!($nsCheck)) {
    Write-Host "WARNING: Namespace does not exist" -ForegroundColor yellow
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check for ACR key
$ACRkey=kubectl get secret regcredlocal --namespace buyingcatalogue
if (!($ACRkey)) {
    Write-Host "ERROR: Could not find ACR key - see: https://github.com/nhs-digital-gp-it-futures/platform-helm/blob/master/docs/k8s-private-registry.md" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check ACR access
$updateRepos=helm repo update | select-string -SimpleMatch "gpitfuturesdevacr"
if ($updateRepos -notlike "...Successfully got an update*") {
    Write-Host "ERROR: Could not connect to ACR - possible issue with ACR credentials added" -ForegroundColor red
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check if cluster deployed
$clusterStatus=kubectl get pods -n buyingcatalogue -o json | ConvertFrom-Json | select-object -expandproperty items
if (!($clusterStatus)) {
    Write-Host "WARNING: Cluster has not been deployed yet" -ForegroundColor yellow
    write-host "Exiting...."
    start-sleep 5
    exit 1
}

# Check if for missing performance affecting config 
$WSLconfigFile=test-path -path "c:\users\$env:UserName\.wslconfig"
if (!($WSLconfigFile)) {
    Write-Host "INFO: WSL Config file not added which could affect performance and memory usage in WSL2 mode" -ForegroundColor white
    Write-Host "INFO: For more info see: https://buyingcatalog.visualstudio.com/Buying%20Catalogue/_wiki/wikis/Wiki/311/Docker-desktop-hogs-resources-and-causes-performance-issues`n" -ForegroundColor white
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
