# Running the dashboard
You may wish to use the Kubernetes dashboard to view what is happening within the cluster.

From a terminal at the `platform/local-helm` sub folder, run one of the following scripts depending on your environment.

**Running this script will take over your terminal!**

-----

#### Powershell
```powershell
.\start-dashboard-proxy.ps1
```
The address of the dashboard will be copied to your clipboard. To browse to the dashboard paste the copied URL into a browser.

-----

#### Bash
```bash
./start-dashboard-proxy.sh
```
Copy the URL displayed in your terminal and paste it into a browser to view the dashboard.

-----

If prompted to signin to the Kubernetes dashboard, select the Kubeconfig option and pick the “config” file under '`C:\Users\<Username>\.kube\config`'.

#### Notes

In the event of issues reporting 'services\"kubernetes-dashboard\" not found' (Error 404) then run the following command to update to the latest dashboard: 
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

Microsoft Edge does not work currently allow you to select 'Sign-in', use Chrome 

#### References

The source material used to configure the Kubernetes dashboard can be found [here](https://collabnix.com/kubernetes-dashboard-on-docker-desktop-for-windows-2-0-0-3-in-2-minutes/).

