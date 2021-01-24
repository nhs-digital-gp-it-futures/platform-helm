Write-Host "Starting dashboard proxy"

$TOKEN=((kubectl -n kube-system describe secret default | Select-String "token:") -split " +")[1]
kubectl config set-credentials docker-desktop --token="${TOKEN}"

$dashboardUrl = "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=buyingcatalogue"
Set-Clipboard -Value $dashboardUrl
Write-Host "Copied '$dashboardUrl' to your clip board"

kubectl proxy
