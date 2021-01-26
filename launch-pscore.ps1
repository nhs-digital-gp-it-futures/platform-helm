$optionSelected=$args[0]

If (!($optionSelected)){
  write-output "`nLaunch and Update Buying Catalogue locally"
  write-output "- 1: Launch a copy of the Buying Catalogue locally (Master Branch)"
  write-output "- 2: Launch a copy of the Buying Catalogue locally (Development Branch)"

  write-output "`nUpdate Chart Versions"
  write-output "- 3: Update local chart versions (using Master Branch)"
  write-output "- 4: Update local chart versions (using Development Branch)"

  write-output "`nDashboards"
  write-output "- 5: Install Local Dashboard"
  write-output "- 6: Start Local Dashboard"

  write-output "`nTear Down Local Environment"
  write-output "- 7: Tear Down Local Environment`n"

  write-output "x: To quit script`n"

  $optionSelected=Read-Host -Prompt "Select Option from choices above: "
} 

write-output "`nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
write-output "CTRL-C now if this is incorrect...`n"
start-sleep 5

$scriptPath=".\src\scripts\pscore"

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
elseif ($optionSelected -eq "5"){
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
  start-sleep 10
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\start-dashboard-proxy.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "6"){
  write-output "<---------STARTING SCRIPT---------->`n"   
  . "$scriptPath\start-dashboard-proxy.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
elseif ($optionSelected -eq "7"){
  write-output "<---------STARTING SCRIPT---------->`n"
  . "$scriptPath\tear-down-local.ps1" | Tee-Object -file "$scriptPath\logs\$optionSelected-Outputlogs.txt"
}
else
{
  write-output "Unrecognised response ($optionSelected) - please try again..."
  start-sleep 5
  exit 1
}
