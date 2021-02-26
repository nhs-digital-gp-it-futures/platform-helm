$context=kubectl config current-context

if ($context -ne "docker-desktop") {
    Write-Host "$context is not a local context!"
    exit 1
}
else {
    write-host "helm delete bc -n buyingcatalogue"
}
