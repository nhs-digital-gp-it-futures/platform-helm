$optionSelected=$args[0]

If ($optionSelected -eq $null) {
  write-output "`nAdvanced Options"
  write-output "- A: For Advanced Options Menu"
  
  write-output "`nLaunch and Update Buying Catalogue locally"
  write-output "- 1: Launch a copy of the Buying Catalogue locally (Master Branch)"
  write-output "- 2: Launch a copy of the Buying Catalogue locally (Development Branch)"

  write-output "`nUpdate Chart Versions"
  write-output "- 3: Update local chart versions (using Master Branch)"
  write-output "- 4: Update local chart versions (using Development Branch)"

  write-output "`nDashboards"
  write-output "- 6: Start Local Kubernetes Dashboard"
  write-output "- 7: Start Local Rancher Dashboard"

  write-output "`nTroubleshooting"
  write-output "- 8: Run troubleshooting on Local Cluster"

  write-output "`nTear Down Local Environment"
  write-output "- 9: Tear Down and redeploy Development to Local Environment"
  write-output "- 0: Tear Down Local Environment`n"

  write-output "x: To quit script`n"

  $optionSelected=Read-Host -Prompt "Select Option from choices above"
} 

if ($optionSelected -eq "a" -or $optionSelected -eq "A") {
  $optionSelected=$NULL
  clear-host
  write-host "`nLaunch and Update Buying Catalogue locally"
  write-host "- 1: Launch a copy of the Buying Catalogue locally (Master Branch)"
  write-host "- 2: Launch a copy of the Buying Catalogue locally (Development Branch)"

  write-host "`nUpdate Chart Versions"
  write-host "- 3: Update local chart versions (using Master Branch)"
  write-host "- 31: Update Public Browse chart version only (using Master Branch)" -ForegroundColor yellow
  write-host "- 32: Update chart version only - except ORDAPI components (using Master Branch)" -ForegroundColor yellow
  write-host "- 4: Update local chart versions (using Development Branch)"
  write-host "- 41: Update Public Browse chart version only (using Development Branch)" -ForegroundColor yellow
  write-host "- 42: Update chart version only - except ORDAPI components (using Development Branch)" -ForegroundColor yellow
  
  write-host "`nAdvanced Setup"
  write-host "- 51: Launch Local Cluster Startup Wizard" -ForegroundColor yellow

  write-host "`nDashboards"
  write-host "- 6: Start Local Kubernetes Dashboard"
  write-host "- 61: Launch Azure Kubernetes Dashboard (VPN required)" -ForegroundColor yellow
  write-host "- 7: Start Local Rancher Dashboard"
  write-host "- 71: Launch Azure Rancher Dashboard (VPN required)" -ForegroundColor yellow

  write-host "`nTroubleshooting"
  write-host "- 8: Run troubleshooting on Local Cluster"

  write-host "`nTear Down Local Environment"
  write-host "- 9: Tear Down and redeploy Development to Local Environment"
  write-host "- 91: Tear Down and redeploy Master to Local Environment" -ForegroundColor yellow
  write-host "- 0: Tear Down Local Environment`n"

  write-host "x: To quit script`n"

  $optionSelected=Read-Host -Prompt "Select Option from choices above"
}

write-output "`nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
write-output "CTRL-C now if this is incorrect...`n"
start-sleep 5

$scriptPath=".\src\scripts\pscore"

New-Item -Path "$scriptPath\" -Name "logs" -ItemType "directory" -ErrorAction SilentlyContinue

if ($optionSelected -eq "x"){
  exit 0
}
elseif ($optionSelected -eq "1"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\launch-or-update-local.ps1" -l $false | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "2"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\launch-or-update-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "3"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "4"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" -v development | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "6"){
  write-output "<---------STARTING SCRIPT---------->`n"   
  . "$scriptPath\start-dashboard-proxy.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "7"){
  write-output "<---------STARTING SCRIPT---------->`n"
  start-process https://rancher.localhost/ | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "8"){
  write-output "`n--- Health Check Script ---"   
  $optionSelected2=Read-Host -Prompt "Q: Do you want to run quick local cluster health check? (Yes/No)"
  
  while("yes","no","y","n" -notcontains $optionSelected2)
  {
    write-host "Answer not recognised..." 
    $optionSelected2 = Read-Host "Q: Do you want to run local cluster quick health check? (Yes/No)"
  }

  if ("no","n" -contains $optionSelected2){
    write-output "<---------STARTING SCRIPT---------->`n"   
    . "$scriptPath\run-health-check.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
  }
  else {
    write-output "<---------STARTING SCRIPT---------->`n"   
    . "$scriptPath\run-health-check.ps1" -q | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
  }
}
elseif ($optionSelected -eq "9"){
  write-output "<---------STARTING SCRIPT---------->`n"   
  . "$scriptPath\tear-down-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
  write-output "`nwait 30 seconds before starting deploy...`n"
  start-sleep 30
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\launch-or-update-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
}
elseif ($optionSelected -eq "0"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\tear-down-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
# Advanced Options
elseif ($optionSelected -eq "31"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" -pbonly | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "32"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" -excludeComponent "ordapi" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "41"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" -v development -pbonly | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "42"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\update-chart-versions.ps1" -v development -excludeComponent "ordapi" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "51"){
  write-output "`n--- Advanced Local Launch ---"   
  $optionSelected2=Read-Host -Prompt "Q: Do you want to download Remote Files from Azure Container Repository (Yes/No)"
  
  while("yes","no","y","n" -notcontains $optionSelected2)
  {
    write-host "Answer not recognised..." 
    $optionSelected2 = Read-Host "Q: Do you want to download Remote Files from Azure Container Repository? (Yes/No)"
  }

  if ("no","n" -contains $optionSelected2){
    write-output "<---------STARTING SCRIPT---------->`n"
    . "$scriptPath\launch-or-update-local.ps1" -r $false | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
  }
  else {
    $optionSelected3=Read-Host -Prompt "Q: Do you want to download updated versions of the Charts? (Yes/No)"
    
    while("yes","no","y","n" -notcontains $optionSelected3)
    {
      write-host "Answer not recognised..." 
      $optionSelected3 = Read-Host "Q: Do you want to download updated versions of the Charts? (Yes/No)"
    }

    if ("no","n" -contains $optionSelected3){
      write-output "<---------STARTING SCRIPT---------->`n"
      . "$scriptPath\launch-or-update-local.ps1" -u $false | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
    }
    else {
      $optionSelected4=Read-Host -Prompt "Q: Do you want to download Development Versions from the Repository? (Yes/No)"
      
      while("yes","no","y","n" -notcontains $optionSelected4)
      {
        write-host "Answer not recognised..." 
        $optionSelected4 = Read-Host "Q: Do you want to download Development Versions from the Repository? (Yes/No)"
      }

      if ("no","n" -contains $optionSelected4){
        write-output "<---------STARTING SCRIPT---------->`n"
        . "$scriptPath\launch-or-update-local.ps1" -l $true | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
      }
      else {
        write-output "<---------STARTING SCRIPT---------->`n"
        . "$scriptPath\launch-or-update-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
      }
    }
  }
}
elseif ($optionSelected -eq "61"){
  write-output "<---------STARTING SCRIPT---------->`n"   
  . "$scriptPath\start-azure-dashboard.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "71"){
  write-output "<---------STARTING SCRIPT---------->`n"
  start-process https://rancher.dynamic.buyingcatalogue.digital.nhs.uk/login | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "91"){
  write-output "<---------STARTING SCRIPT---------->`n"   
  . "$scriptPath\tear-down-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
  write-output "`nwait 30 seconds before starting deploy...`n"
  start-sleep 30
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\launch-or-update-local.ps1" -l $false | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt" -Append
}
else
{
  write-output "Unrecognised response ($optionSelected) - please try again..."
  start-sleep 5
  exit 1
}
