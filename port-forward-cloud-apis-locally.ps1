#############################################################
### Port forward cloud env locally                        ###
### usage:                                                ###
###  ./port-forward-cloud-apis-locally.ps1 -n <Namespace> ###
#############################################################


param(
        [Parameter()]
        [string]$Namespace
    )

function constructServicesToPortsMap()
{
    $Map = @{
    "bapi" = "5100"
    "dapi" = "5101"
    "isapi" = "5102"
    "oapi" = "5103"
    "ordapi" = "5104"
    }
    return $Map
}

$ServicesToPorts = constructServicesToPortsMap


$JobIds=@()
try
{
    $ServicesToPorts.keys | ForEach-Object {

        $ScriptBlock = { 
        param
        (
            $key,
            $value,
            $Namespace
        )
        kubectl port-forward service/gpitfutures-bc-$key $($value):$($value) -n $Namespace
        }

        $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $_, $ServicesToPorts[$_], $Namespace -Name $_
        $JobIds+=$Job.Id
    }
    write-host "Starting..." 
    Read-Host -Prompt "To stop port forwarding, please either press Enter or kill this process (Ctrl + C)."
}

catch { }

finally
{
    Write-Host "`nStarting cleanup..."
    foreach ($Job in $JobIds)
    {
        Stop-Job -Id $Job
    }
    Write-Host -ForegroundColor Green "Cleanup completed!"
}