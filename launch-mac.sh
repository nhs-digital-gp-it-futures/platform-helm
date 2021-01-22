#!/bin/bash

os=$(uname -s)

if [[ "$os" != "Darwin" ]]; then 
  >&2 echo -e "Script is not running on a mac!\n"
  #exit 1
fi

#if [ -f "/usr/local/bin/bash" ]; then
if [ -f "/usr/local/bin/helm" ]; then ##### SWITCHME!!!
  echo -e "Correct Bash version detected\n"
else
  echo "Old Bash version detected: $BASH_VERSION"
  echo -e 'To run Buying Catalogue Scripts on Mac you will need to update Bash to a later version:'
  echo '-> See https://itnext.io/upgrading-bash-on-macos-7138bd1066ba'
  echo '-> Once done you will need to restart your terminal session'
  
  sleep 20
  exit 1
fi

echo "x: To quit script"
echo "1: Launch a copy of the Buying Catalogue locally (Master Branch)"
echo "2: Launch a copy of the Buying Catalogue locally (Development Branch)"
echo "3: Update local chart versions (using Master Branch)"
echo "4: Update local chart versions (using Development Branch)"

read -p "Select Option from choices above: " optionSelected

echo -e "\nYou have chosen ($optionSelected) - this will launch/quit in 5 seconds." 
echo -e "CTRL-C now if this is incorrect...\n"
sleep 5

if [[ $optionSelected = "x" ]]; then
  exit 0
elif [[ $optionSelected = "1" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-osx/launch-or-update-local-osx.sh -l false
elif [[ $optionSelected = "2" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-osx/launch-or-update-local-osx.sh
elif [[ $optionSelected = "3" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-osx/update-chart-versions-osx.sh
elif [[ $optionSelected = "4" ]]; then
  echo -e "<---------STARTING SCRIPT---------->\n"
  source ./src/scripts/bash-osx/update-chart-versions-osx.sh -v development
else
  echo "Unrecognised response ($optionSelected) - please try again..."
  sleep 5
  exit 1
fi