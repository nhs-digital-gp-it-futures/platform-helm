# How to: port-forward services in cloud environment locally

## Prerequisites
- have kubernetes cli installed - [install it](local-k8s-setup.md)

## Steps

1) Find out which namespace you want to port forward to

   If you've pushed a branch in this repo called feature/some-cool-feature, your namespace will be: `bc-some-cool-feature`

2) From the root of the repository 
   bash
   ```sh
   bash port-forward-cloud-services-locally.sh -n <name of the namespace from step 1>
   ```

   powershell
   ```powershell
   .\port-forward-cloud-services-locally.ps1 <name of the namespace from step 1>
   ```

You should now be able to access all your services on http://localhost:{port} - see [this table](../README.md#configuration-overview) for a map of services and their ports
