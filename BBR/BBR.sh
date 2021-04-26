#!/bin/sh

clear

## Check Root Privilege
if [ $(id -u) -ne 0 ]; then 
    tput setaf 1; echo  "This script needs root permission to run" 
    exit 1 
fi

## Installing BBR
cd $HOME
clear
curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/.tweaking.sh && source .tweaking.sh
BBR_Tweaking

## Clear
rm BBR.sh
rm .tweaking.sh

echo "Tweaked BBR Installation Complete"
