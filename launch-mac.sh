#!/bin/bash

os=$(uname -s)

if [[ "$os" != "Darwin" ]]; then 
  >&2 echo -e "Script is not running on a mac!\n"
  sleep 2
  #exit 1
fi

if [ -f "/usr/local/bin/bash" ]; then
#if [ -f "/usr/local/bin/helm" ]; then ##### SWITCHME!!!
  echo -e "Correct Bash version detected\n"
else
  echo -e "Unsupported Bash version detected: $BASH_VERSION"
  echo -e 'To run Buying Catalogue Scripts on Mac you will need to update Bash to a later version:'
  echo -e '-> See https://itnext.io/upgrading-bash-on-macos-7138bd1066ba'
  echo -e '-> Once done you will need to restart your terminal session'
  
  #sleep 20
  #exit 1
fi

optionSelected=$1

if [ -z "$optionSelected" ]; then
  echo -e "\nLaunch and Update Buying Catalogue locally"
  echo -e "- 1: Launch a copy of the Buying Catalogue locally (Master Branch)"
  echo -e "- 2: Launch a copy of the Buying Catalogue locally (Development Branch)"

  echo -e "\nUpdate Chart Versions"
  echo -e "- 3: Update local chart versions (using Master Branch)"
  echo -e "- 4: Update local chart versions (using Development Branch)"

  echo -e "\nDashboards"
  echo -e "- 5: Install Local Dashboard"
  echo -e "- 6: Start Local Dashboard"

  echo -e "\nTear Down Local Environment"
  echo -e "- 7: Tear Down Local Environment\n"

  echo -e "\nx: To quit script\n"

  read -p "Select Option from choices above: " optionSelected
fi

echo -e "\nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
echo -e "CTRL-C now if this is incorrect...\n"
sleep 5

if [[ $optionSelected = "x" ]]; then
  exit 0
elif [[ $optionSelected = "1" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/launch-or-update-local-mac.sh -l false
elif [[ $optionSelected = "2" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/launch-or-update-local-mac.sh
elif [[ $optionSelected = "3" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/update-chart-versions-mac.sh
elif [[ $optionSelected = "4" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/update-chart-versions-mac.sh -v development
elif [[ $optionSelected = "5" ]]; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
  sleep 10
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/start-dashboard-proxy-mac.sh
elif [[ $optionSelected = "6" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/start-dashboard-proxy-mac.sh
elif [[ $optionSelected = "7" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-mac/tear-down-local-mac.sh
else
  echo "Unrecognised response ($optionSelected) - please try again..."
  sleep 5
  exit 1
fi