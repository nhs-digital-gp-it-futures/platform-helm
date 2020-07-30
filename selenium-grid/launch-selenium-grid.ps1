$namespace="selenium-grid"

$response=$(kubectl get ns $namespace)
if ($response -ne "")
{
    kubectl apply -f grid-namespace.yml
}

helm upgrade sel-grid stable/selenium -i -f values.yaml -n $namespace