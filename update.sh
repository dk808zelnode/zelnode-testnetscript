#!/bin/bash

###### you must be logged in as a sudo user, not root #######
# This script will update your ZelNode daemon to the current release
# Version ZelNodeUpdate v1.1

#wallet information
COIN_NAME='zelcash'
WALLET_DOWNLOAD='https://zelcore.io/linux.zip'
WALLET_ZIP_FILE='linux.zip'
ZIPTAR='unzip'
CONFIG_FILE='zelcash.conf'
PORT=16125
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_PATH='/usr/local/bin'
USERNAME=$(who -m | awk '{print $1;}')
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
STOP='\e[0m'
FETCHPARAMS='https://raw.githubusercontent.com/zelcash/zelcash/master/zcutil/fetch-params.sh'
#end of required details

#Display script name and version
clear
echo -e '\033[1;33m==================================================================\033[0m'
echo -e 'ZelNode Update, v1.1'
echo -e '\033[1;33m==================================================================\033[0m'
echo -e '\033[1;34m19 Feb. 2019, by alltank fam, dk808zelnode, Goose-Tech & Skyslayer\033[0m'
echo -e
echo -e '\033[1;36mZelNode update starting, press [CTRL-C] to cancel.\033[0m'
sleep 3
echo -e
#check for correct user
USERNAME=$(who -m | awk '{print $1;}')
echo -e "\033[1;36mYou are currently logged in as \033[0m$USERNAME\033[1;36m.\n\n"
read -p 'Was this the username used to install the ZelNode? [Y/n] ' -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo ""
    echo -e "\033[1;33mPlease log out and login with the username you created for your ZelNode.\033[0m"
      exit 1
fi
#check for root and exit with notice if user is root
ISROOT=$(whoami | awk '{print $1;}')
if [ "$ISROOT" = "root" ]; then
    echo -e "\033[1;36mYou are currently logged in as \033[0mroot\033[1;36m, please log out and\nlog back in with as your sudo user.\033[0m"
    exit
fi

#Install Ubuntu updates
echo -e "\033[1;33m=======================================================\033[0m"
echo "Updating your OS..."
echo -e "\033[1;33m=======================================================\033[0m"
echo "Installing package updates..."
sudo apt-get update -y
sudo apt-get upgrade -y
echo -e "\033[1;32mLinux Packages Updates complete...\033[0m"
sleep 2

#Closing zelcash daemon
echo -e "\033[1;33mStopping & removing all old instances of $COIN_NAME and Downloading new wallet...\033[0m"
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 3
sudo zelcash-cli stop > /dev/null 2>&1 && sleep 5
sudo killall $COIN_DAEMON > /dev/null 2>&1
#Removing old zelcash files
#delete any existing zelcash form /usr/local/bin and /usr/bin
sudo rm /usr/local/bin/zelcash* > /dev/null 2>&1 && sleep 2
sudo rm /usr/bin/zelcash* > /dev/null 2>&1 && sleep 2
echo -e "\033[1;33mUpdating new wallet binaries...\033[0m"

#Install zelcash files using APT
wget -U Mozilla/5.0 $WALLET_DOWNLOAD
unzip $WALLET_ZIP_FILE -d $COIN_PATH
sudo chmod 755 /usr/local/bin/zelcash*
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
cd
#Notice to user we are complete and request a reboot
echo -e "\033[1;32mUpdate complete.\nPlease reboot the VPS by typing: \033[0msudo reboot -n\033[1;32m."
echo -e "Then verify the ZelCash daemon has started by typing: \033[0mzelcash-cli getinfo\033[1;32m.\033[0m"
