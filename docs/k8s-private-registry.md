# How To Connect Local Kubernetes with our Private Container Registry

Eventually, a service principle will be set up. In the interim, the best approach is to create a local secret called regcredlocal using the command line as below.

## To retrieve the relevant password:

You will need to look in the azure portal https://portal.azure.com
Log in using your hscic.gov.uk email adress.

Go to: [All services > Containers > Container registries](https://portal.azure.com/#blade/HubsExtension/BrowseResourceBlade/resourceType/Microsoft.ContainerRegistry%2Fregistries) > gpitfuturesdevacr > Access Keys > password

One you have this password, run this snippet, replacing values in '<>'

```bash
kubectl create secret docker-registry regcredlocal --docker-server=gpitfuturesdevacr.azurecr.io --docker-username=gpitfuturesdevacr --docker-password=<password> --docker-email=<your-hscic.gov.uk email> --namespace buyingcatalogue
```

## References

Instructions on setting up Kubernetes with a private registry are [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).
Instructions on authenticating to Azure Container Registry are [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication).
