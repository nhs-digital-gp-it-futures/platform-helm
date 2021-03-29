$context=kubectl config current-context

if (helm list -n buyingcatalogue -o json | ConvertFrom-Json) {
    if ($context -ne "docker-desktop") {
        Write-Host "$context is not a local context!"
        exit 1
    }
    else {
        helm delete bc -n buyingcatalogue
    }
}
else {
    write-host "Buying Catalogue not installed"
}

if (kubectl describe pvc -l app=redis -n buyingcatalogue){
    kubectl delete pvc -l app=redis -n buyingcatalogue
}
else {
    write-host "Redis Cache not found"
}