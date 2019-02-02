#!/usr/bin/env bash

COIN_NAME='ZELCASH' #no spaces

#wallet information
WALLET_DOWNLOAD='https://www.dropbox.com/s/raw/y4wxr5ok2a7ug65/zelnode-testnetv2.zip'
WALLET_TAR_FILE='zelnode-testnetv2-linux.zip'
ZIPTAR='unzip' #can be either unzip or tar -xfzg
EXTRACT_DIR='' #not always necessary, can be blank if zip/tar file has no subdirectories
CONFIG_FILE='zelcash.conf'
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
COIN_TX='zelcash-tx'
COIN_PATH='/usr/bin'
ADDNODE1='188.166.56.40'
ADDNODE2='165.227.163.183'
ADDNODE3='104.248.118.1'
ADDNODE4='167.99.82.56'
ADDNODE5='46.36.41.83'
ADDNODE6='165.227.156.125'
PORT='26125'
RPCPORT='26124'
echo "Enter su username"
username=$(whiptail --inputbox "Enter su username" 10 30 3>&1 1>&2 2>&3)
USERNAME=$username

FETCHPARAMS='https://raw.githubusercontent.com/dk808/zelnode_script/master/fetch-params.sh'


#end of required details
#
#
#

echo "=================================================================="
echo "$COIN_NAME ZELNODE DEPENDENCIES INSTALLER"
echo "=================================================================="
echo "Installing packages and updates..."
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install curl -y
sudo apt-get install nano -y
sudo apt-get install pwgen -y
sudo apt-get install ufw -y
sudo apt-get install dnsutils -y
sudo apt-get install build-essential libtool autotools-dev pkg-config libssl-dev -y
sudo apt-get install  libc6-dev m4 g++-multilib -y
sudo apt-get install autoconf libtool ncurses-dev unzip git python python-zmq -y
sudo apt-get install zlib1g-dev wget curl bsdmainutils automake -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install libevent-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install autoconf -y
sudo apt-get install automake -y
sudo apt-get install unzip -y
sudo apt-get install figlet toilet -y
sudo apt-get install lolcat -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev libzmq3-dev libevent-pthreads-2.0-5 -y
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev -y
sudo apt-get install libqrencode-dev bsdmainutils -y
echo "Packages complete..."

WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi

echo "Creating Conf File wallet"
sudo mkdir ~/.zelcash
sudo touch ~/.zelcash/$CONFIG_FILE
cat <<EOF > ~/.zelcash/$CONFIG_FILE
rpcuser=$COIN_NAME
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
txindex=1
listen=1
logtimestamps=1
rpcport=$RPCPORT
port=$PORT
externalip=$WANIP
bind=$WANIP
addnode=$ADDNODE1
addnode=$ADDNODE2
addnode=$ADDNODE3
addnode=$ADDNODE4
addnode=$ADDNODE5
addnode=$ADDNODE6
maxconnections=256
EOF

#begin downloading wallet
echo "Killing and removing all old instances of $COIN_NAME and Downloading new wallet..."
sudo killall $COIN_DAEMON > /dev/null 2>&1
cd /usr/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && sleep 2 && cd

rm -rf $EXTRACT_DIR
rm -rf $WALLET_TAR_FILE
sudo wget -U Mozilla/5.0 $WALLET_DOWNLOAD

$ZIPTAR $WALLET_TAR_FILE
cd $EXTRACT_DIR
sudo chmod +x $COIN_CLI $COIN_DAEMON $COIN_TX
cp $COIN_CLI $COIN_DAEMON $COIN_TX $COIN_PATH
sudo chmod +× /usr/bin/zelcash*
cd
rm -rf $EXTRACT_DIR
rm -rf $WALLET_TAR_FILE
#end downloading/cleaning up wallet

echo "downloading chain params"
wget $FETCHPARAMS
sudo chmod +x fetch-params.sh
sudo bash fetch-params.sh
echo "Done fetching chain params"

echo "Creating system service file...."
 cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=$USERNAME
Group=$USERNAME
Type=forking
#PIDFile=~/.zelcash/$COIN_NAME.pid
ExecStart=$COIN_PATH/$COIN_DAEMON -daemon -conf=~/.zelcash/$CONFIG_FILE -datadir=~/.zelcash/
ExecStop=-$COIN_PATH/$COIN_CLI -conf=~/.zelcash/$CONFIG_FILE -datadir=~/.zelcash stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
sleep 3
systemctl start $COIN_NAME.service
systemctl enable $COIN_NAME.service >/dev/null 2>&1

echo "Systemctl Complete...."

echo "If you see *error* message, do not worry we are killing wallet again to make sure its dead"
echo ""
echo "=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 2 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo "=================================================================="
echo ""

echo "Stopping daemon again and creating final config..."

echo "Configuring firewall..."
#add a firewall
sudo ufw allow $PORT/tcp
sudo ufw allow $RPCPORT/tcp
echo "Basic security completed..."

echo "Restarting $COIN_NAME wallet with new configs, 30 seconds..."
sudo chmod +x /usr/bin/zelcash*
$COIN_DAEMON -daemon
sleep 60

echo "Creating Zelnode privkey..."
GENKEY=$($COIN_CLI createzelnodekey)

echo "Getting info..."
$COIN_CLI getinfo
$COIN_CLI stop

echo "Stopping daemon again and creating final config..."
cat <<EOF > ~/.zelcash/$CONFIG_FILE
rpcuser=$COIN_NAME
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
txindex=1
listen=1
logtimestamps=1
rpcport=$RPCPORT
port=$PORT
externalip=$WANIP
bind=$WANIP
zelnode=1
zelnodeprivkey=$GENKEY
addnode=$ADDNODE1
addnode=$ADDNODE2
addnode=$ADDNODE3
addnode=$ADDNODE4
addnode=$ADDNODE5
addnode=$ADDNODE6
maxconnections=256
EOF

sleep 30

echo "Starting your ZELNODE with final details"

$COIN_DAEMON -daemon

figlet -t -k "WELCOME   TO   ZELNODES" 

echo "============================================================================="
echo "COPY THIS TO LOCAL WALLET CONFIG FILE AND REPLACE TxID and OUTPUT"
echo "WITH THE DETAILS FROM YOUR COLLATERAL TRANSACTION"
echo "ZN1 $WANIP:$PORT $GENKEY TxID OUTPUT"
echo "COURTESY OF ALTTANK FAM AND DK808"
echo "============================================================================="
sleep 1
