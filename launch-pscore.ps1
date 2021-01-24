$os=$PSVersionTable | select-object -expandproperty PSEdition -ErrorAction SilentlyContinue

if ($os -ne "Core"){
    echo "Script is not running in PowerShell Core!"
    exit 1
}

$optionSelected=$args[0]

If (!($optionSelected)){
  echo "`nLaunch and Update Buying Catalogue locally"
  echo "- 1: Launch a copy of the Buying Catalogue locally (Master Branch)"
  echo "- 2: Launch a copy of the Buying Catalogue locally (Development Branch)"

  echo "`nUpdate Chart Versions"
  echo "- 3: Update local chart versions (using Master Branch)"
  echo "- 4: Update local chart versions (using Development Branch)"

  echo "`nDashboards"
  echo "- 5: Install Local Dashboard"
  echo "- 6: Start Local Dashboard"

  echo "`nTear Down Local Environment"
  echo "- 7: Tear Down Local Environment`n"

  echo "x: To quit script`n"

  $optionSelected=Read-Host -Prompt "Select Option from choices above: "
} 

echo "`nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
echo "CTRL-C now if this is incorrect...`n"
start-sleep 5

if ($optionSelected -eq "x"){
  exit 0
}
elseif ($optionSelected -eq "1"){
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\launch-or-update-local.ps1" -l $false
}
elseif ($optionSelected -eq "2"){
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\launch-or-update-local.ps1"
}
elseif ($optionSelected -eq "3"){
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\update-chart-versions.ps1"
}
elseif ($optionSelected -eq "4"){
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\update-chart-versions.ps1" -v development 
}
elseif ($optionSelected -eq "5"){
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
  start-sleep 10
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\start-dashboard-proxy.ps1"
}
elseif ($optionSelected -eq "6"){
  echo "<---------STARTING SCRIPT---------->`n"   
  . ".\src\scripts\pscore\start-dashboard-proxy.ps1"
}
elseif ($optionSelected -eq "7"){
  echo "<---------STARTING SCRIPT---------->`n"
  . ".\src\scripts\pscore\tear-down-local.ps1"
}
else
{
  echo "Unrecognised response ($optionSelected) - please try again..."
  start-sleep 5
  exit 1
}