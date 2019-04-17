#!/bin/bash

#############################################################################################################################################################################
# IF PLANNING TO RUN ZELNODE FROM HOME/OFFICE/PERSONAL EQUIPMENT & NETWORK!!!
# You must understand the implications of running a ZelNode on your on equipment and network. There are many possible security issues. DYOR!!!
# Running a ZelNode from home should only be done by those with experience/knowledge of how to set up the proper security.
# It is recommended for most operators to use a VPS to run a ZelNode
#
#**Potential Issues (not an exhaustive list):**
#1. Your home network IP address will be displayed to the world. Without proper network security in place, a malicious person sniff around your IP for vulnerabilities to access your network.
#2. Port forwarding: The p2p port for ZelCash will need to be open.
#3. DDOS: VPS providers typically provide mitigation tools to resist a DDOS attack, while home networks typically don't have these tools.
#4. Zelcash daemon is ran with sudo permissions, meaning the daemon has elevated access to your system. **Do not run a ZelNode on equipment that also has a funded wallet loaded.**
#5. Static vs. Dynamic IPs: If you have a revolving IP, every time the IP address changes, the ZelNode will fail and need to be stood back up.
#6. Anti-cheating mechanisms: If a ZelNode fails benchmarking/anti-cheating tests too many times in the future, its possible your IP will be blacklisted and no nodes can not dirun using that public-facing IP.
#7. Home connections typically have a monthly data cap. ZelNodes will use 2.5 - 6 TB monthly usage depending on ZelNode tier, which can result in overage charges. Check your ISP agreement.
#8. Many home connections provide adequate download speeds but very low upload speeds. ZelNodes require 100mbps (12.5MB/s) download **AND** upload speeds. Ensure your ISP plan can provide this continually. 
#9. ZelNodes can saturate your network at times. If you are sharing the connection with other devices at home, its possible to fail a benchmark if network is saturated.
#############################################################################################################################################################################

#Version V3

###### you must be logged in as a sudo user, not root #######

COIN_NAME='zelcash'

#wallet information
WALLET_DOWNLOAD='https://zelcore.io/linux.zip'
WALLET_ZIP_FILE='linux.zip'
WALLET_BOOTSTRAP='https://zelcore.io/zelcashbootstraptxindex.zip'
BOOTSTRAP_ZIP_FILE='zelcashbootstraptxindex.zip'
ZIPTAR='unzip'
CONFIG_FILE='zelcash.conf'
PORT=16125
SSHPORT=22
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_TX='zelcash-tx'
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
#
#
#

#countdown timer to provide outputs for forced pauses
#countdown "00:00:30" is a 30 second countdown
countdown()
(
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo -e "\033[1K"
)



#Suppressing password prompts for this user so zelnode can operate
sudo echo -e "$(who -m | awk '{print $1;}') ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
clear
echo -e '${YELLOW}===============================================================================${NC}'
echo -e 'ZelNode Setup, v4.0'
echo -e '${YELLOW}===============================================================================${NC}'
echo -e '${BLUE}16 April 2019, by AltTank fam, dk808, Goose-Tech, Skyslayer, & Packetflow${NC}'
echo -e
echo -e '${CYAN}Node setup starting, press [CTRL-C] to cancel.${NC}'
countdown "00:00:03"
echo -e

if [ "$USERNAME" = "root" ]; then
    echo -e "${CYAN}You are currently logged in as ${NC}root${CYAN}, please log out and log back in with the username you just created.${NC}"
    exit
fi
 
# searcch sshd conf file for ssh port if not default ask user for new port/
# set var SSHPORT by user imput if not default this is used for UFW firewall settings
searchString="Port 22"
file="/etc/ssh/sshd_config"
if grep -Fq "$searchString" $file ; then
    echo -e "SSH is currently set to the default port 22."
else
    echo -e "Looks like you have configured a custom SSH port..."
    echo -e
    read -p 'Enter your custom SSH port, or hit [ENTER] for default: ' SSHPORT
	  if [ -z "$SSHPORT" ]; then
      SSHPORT=22
    fi
fi
echo -e "${YELLOW}Using SSH port:${GREEN}" $SSHPORT
echo -e "${NC}"
sleep 2

#get WAN IP ask user to verify it and or change it if needed 
WANIP=$(wget http://ipecho.net/plain -O - -q)
echo -e 'Detected IP Address is' $WANIP
echo -e
read -p 'Is IP Address correct? [Y/n] ' -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo -e
    read -p 'Enter the IP address for your VPS, then hit [ENTER]: ' WANIP
fi

echo ""
echo -e "${YELLOW}Enter the MAINNET ZELNODE KEY generated by your ZelMate/ZelCore wallet: ${NC}"
read zelnodeprivkey

echo -e "${YELLOW}=======================================================${NC}"
echo "INSTALLING ZELNODE DEPENDENCIES"
echo -e "${YELLOW}=======================================================${NC}"
echo "Adding ZelCash Repos & Installing Packages..."
sleep 2

#installing dependencies
echo -e "${YELLOW}Installing Packages...${NC}"
sudo apt-get install software-properties-common -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install nano htop pwgen ufw figlet -y
sudo apt-get install build-essential libtool pkg-config -y
sudo apt-get install libc6-dev m4 g++-multilib -y
sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y
sudo apt-get install wget curl bsdmainutils automake -y
sudo apt-get remove sysbench -y

echo -e "${YELLOW}Packages complete...${NC}"
echo -e

if [ -f ~/.zelcash/zelcash.conf ]; then
    echo -e "${CYAN}Existing conf file found, backing up to zelcash.old ...${NC}"
    sudo mv ~/.zelcash/zelcash.conf ~/.zelcash/zelcash.old;
fi

RPCUSER=`pwgen -1 8 -n`
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi
    echo -e "${GREEN}Creating MainNet Conf File...${NC}"
    sleep 3
    mkdir ~/.zelcash
    touch ~/.zelcash/$CONFIG_FILE
    echo "rpcuser=$RPCUSER" >> ~/.zelcash/$CONFIG_FILE
    echo "rpcpassword=$PASSWORD" >> ~/.zelcash/$CONFIG_FILE
    echo "rpcallowip=127.0.0.1" >> ~/.zelcash/$CONFIG_FILE
    echo "zelnode=1" >> ~/.zelcash/$CONFIG_FILE
    echo zelnodeprivkey=$zelnodeprivkey >> ~/.zelcash/$CONFIG_FILE
    echo "server=1" >> ~/.zelcash/$CONFIG_FILE
    echo "daemon=1" >> ~/.zelcash/$CONFIG_FILE
    echo "txindex=1" >> ~/.zelcash/$CONFIG_FILE
    echo "listen=1" >> ~/.zelcash/$CONFIG_FILE
    echo "logtimestamps=1" >> ~/.zelcash/$CONFIG_FILE
    echo "externalip=$WANIP" >> ~/.zelcash/$CONFIG_FILE
    echo "bind=$WANIP" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=explorer.zel.cash" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=explorer.zel.zelcore.io" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=explorer2.zel.cash" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=explorer.zelcash.online" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=node-eu.zelcash.com" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=node-uk.zelcash.com" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=node-asia.zelcash.com" >> ~/.zelcash/$CONFIG_FILE
    echo "maxconnections=256" >> ~/.zelcash/$CONFIG_FILE

sleep 2

#Setup zelcash debug.log log file rotation
echo -e "${YELLOW}Configuring log rotate function...${NC}"
sleep 1
if [ -f /etc/logrotate.d/zeldebuglog ]; then
    echo -e "${CYAN}Existing log rotate conf found, backing up to ~/zeldebuglogrotate.old ...${NC}"
    sudo mv /etc/logrotate.d/zeldebuglog ~/zeldebuglogrotate.old;
    sleep 2
fi
touch /home/$USERNAME/zeldebuglog
cat <<EOM > /home/$USERNAME/zeldebuglog
/home/$USERNAME/.zelcash/debug.log {
    compress
    copytruncate
    missingok
    daily
    rotate 7
}
EOM
cat /home/$USERNAME/zeldebuglog | sudo tee -a /etc/logrotate.d/zeldebuglog > /dev/null
rm /home/$USERNAME/zeldebuglog
echo -e "${GREEN}Log rotate configuration complete.\n~/.zelcash/debug.log file will be backed up daily for 7 days then rotated.${NC}"
sleep 5

#begin downloading wallet binaries
echo -e "${GREEN}Killing and removing any old instances of $COIN_NAME."
echo -e "Installing ZelCash daemon...${NC}"

#Closing zelcash daemon if running
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 3
sudo zelcash-cli stop > /dev/null 2>&1 && sleep 5
sudo killall $COIN_DAEMON > /dev/null 2>&1
#delete any existing zelcash form /usr/local/bin and /usr/bin
sudo rm /usr/local/bin/zelcash* > /dev/null 2>&1 && sleep 2
sudo rm /usr/bin/zelcash* > /dev/null 2>&1 && sleep 2

#Install zelcash files using APT
wget -U Mozilla/5.0 $WALLET_DOWNLOAD
unzip $WALLET_ZIP_FILE -d $COIN_PATH  
sudo chmod 755 /usr/local/bin/zelcash*
rm -rf $WALLET_ZIP_FILE

# Download and extract the bootstrap chainstate and blocks files to ~/.zelcash
echo -e "${GREEN}Downloading wallet bootstrap please be patient...${NC}"
wget -U Mozilla/5.0 $WALLET_BOOTSTRAP
unzip -o $BOOTSTRAP_ZIP_FILE -d /home/$USERNAME/.zelcash
rm -rf $BOOTSTRAP_ZIP_FILE
#end download/extract bootstrap file

#Downloading chain params
echo ""
echo -e "${GREEN}Downloading chain params...${NC}"
wget -q $FETCHPARAMS
chmod 770 fetch-params.sh &> /dev/null
bash fetch-params.sh
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
rm fetch-params.sh
echo -e "${YELLOW}Done fetching chain params.${NC}"

#Downloading update script
echo -e "${GREEN}Downloading update script for future updates...${NC}"
wget https://raw.githubusercontent.com/ZelScripts/ZelNodeInstallv3/master/zelnodeupdate.sh && chmod +x zelnodeupdate.sh

#Downloading chown script and create cron job to run it every minute
echo -e "${GREEN}Installing chown script to make sure working directory is owned by User...${NC}"
wget https://raw.githubusercontent.com/ZelScripts/ZelNodeInstallv3/master/chown.sh && chmod +x chown.sh
echo -e "${GREEN}Creating cron job to run the chown script...${NC}"
crontab -l > tempcron
echo "* * * * * /home/$USERNAME/chown.sh >/dev/null 2>&1" >> tempcron
crontab tempcron
rm tempcron

# setup zelcash daemon to run as a service 
echo -e "${GREEN}Creating system service file...${NC}"
sudo touch /etc/systemd/system/$COIN_NAME.service
sudo chown $USERNAME:$USERNAME /etc/systemd/system/$COIN_NAME.service
cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/.zelcash/
ExecStart=$COIN_PATH/$COIN_DAEMON -datadir=/home/$USERNAME/.zelcash/ -conf=/home/$USERNAME/.zelcash/$CONFIG_FILE -daemon
ExecStop=-$COIN_PATH/$COIN_CLI stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
sudo chown root:root /etc/systemd/system/$COIN_NAME.service
sudo systemctl daemon-reload
sleep 3
sudo systemctl enable $COIN_NAME.service &> /dev/null

echo -e "${YELLOW}Systemctl Complete....${NC}"

echo ""
echo -e "${YELLOW}=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT UNTIL YOU SEE THE RESTARTING WALLET MESSAGE"
echo -e "==================================================================${NC}"
echo ""

echo -e "${GREEN}Configuring firewall and enabling fail2ban...${NC}"
sudo ufw allow $SSHPORT/tcp
sudo ufw allow $PORT/tcp
sudo ufw logging on
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "y" | sudo ufw enable >/dev/null 2>&1
sudo systemctl enable fail2ban >/dev/null 2>&1
sudo systemctl start fail2ban >/dev/null 2>&1
echo -e "${YELLOW}Basic security completed...${NC}"

echo -e "${GREEN}Benchmarking node & syncing $COIN_NAME wallet with blockchain, please be patient...${NC}"
$COIN_DAEMON -daemon &> /dev/null
countdown "00:10:00"
$COIN_CLI stop &> /dev/null
sleep 15
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
echo -e "${GREEN}Restarting ZelNode Daemon...${NC}"
$COIN_DAEMON -daemon &> /dev/null
for (( counter=30; counter>0; counter-- ))
do
echo -n ". "
sleep 1
done
printf "\n"

sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
echo -e "${GREEN}Finalizing ZelNode Setup...${NC}"
sleep 5

printf "${BLUE}"
figlet -t -k "WELCOME   TO   ZELNODES" 
printf "${STOP}"

echo -e "${YELLOW}==================================================================="
echo -e "${GREEN}PLEASE COMPLETE THE ZELNODE SETUP IN YOUR ZELCORE/ZELMATE WALLET${NC}"
echo -e "COURTESY OF ${BLUE}ALTTANK FAM${NC}, ${BLUE}DK808${NC}, ${BLUE}GOOSE-TECH${NC}, ${BLUE}SKYSLAYER${NC}, & ${BLUE}PACKETFLOW"
echo -e "${YELLOW}===================================================================${NC}"
echo -e
read -n1 -r -p "Press any key to continue..." key
for (( countera=120; countera>0; countera-- ))
do
clear
echo -e "${YELLOW}==========================================================="
echo -e "${GREEN}ZELNODE SYNC STATUS"
echo -e "THIS SCREEN REFRESHES EVERY 30 SECONDS"
echo -e "TO VIEW THE CURRENT BLOCK GO TO https://explorer.zel.cash/ "
echo -e "${YELLOW}===========================================================${NC}"
echo ""
$COIN_CLI getinfo
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
echo -e '${GREEN}Press [CTRL-C] when correct blockheight has been reached to exit.${NC}'
    countdown "00:00:30"
done
printf "\n"
