#!/bin/bash

PS3='Select an action: '
options=(
"Install Node"
"Update Peers"
"Quick Sync"
"Exit")

select opt in "${options[@]}"
do
case $opt in

"Install Node")

echo -e "\e[1m\e[32m	Enter monkier:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read moniker
echo "_|-_|-_|-_|-_|-_|-_|"

if [[ -z "$moniker" ]]
then
  echo "monkier is not set";
  exit 1;
fi


# Install Dependencies
echo "================ Install Dependencies ====================="
sudo apt update && sudo apt upgrade -y >/dev/null
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y >/dev/null

# Install Go
echo "================ Install Go ====================="
ver="1.18.2"
sudo rm -rf /usr/local/go
cd $HOME
curl https://dl.google.com/go/go$ver.linux-amd64.tar.gz | sudo tar -C /usr/local -zxvf - >/dev/null 2>&1;
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile

go version

# Install Celestia-app
echo "================ Install Celestia-app ====================="
cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
APP_VERSION=v0.11.0
git checkout tags/$APP_VERSION -b $APP_VERSION
make install

celestia-appd version

# Setup P2P network
echo "================ Setup P2P ====================="
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git

echo "monkier is $moniker"
celestia-appd init "$moniker" --chain-id mocha

cp $HOME/networks/mocha/genesis.json $HOME/.celestia-app/config

SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/seeds.txt | tr -d '\n')
echo $SEEDS

PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/peers.txt | tr -d '\n')

SEED_MODE="true"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml
sed -i -e "s/^seed_mode *=.*/seed_mode = \"$SEED_MODE\"/" $HOME/.celestia-app/config/config.toml

# Config Pruning
echo "================ Config Pruning ====================="
PRUNING="custom"
PRUNING_KEEP_RECENT="100"
PRUNING_INTERVAL="10"

sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \
\"$PRUNING_KEEP_RECENT\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \
\"$PRUNING_INTERVAL\"/" $HOME/.celestia-app/config/app.toml


echo "================ Setup Client ====================="
celestia-appd config keyring-backend test

# Start Node
echo "================ Start Node ====================="
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-appd.service
[Unit]
Description=celestia-appd Cosmos daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/celestia-appd start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd
sudo systemctl status celestia-appd

break
;;

"Update Peers")

break
;;

"Quick Sync")
sudo systemctl stop celestia-appd
cd $HOME
rm -rf ~/.celestia-app/data
mkdir -p ~/.celestia-app/data
SNAP_NAME=$(curl -s https://snaps.qubelabs.io/celestia/ | \
    egrep -o ">mocha.*tar" | tr -d ">")
wget -O - https://snaps.qubelabs.io/celestia/${SNAP_NAME} | tar xf - \
    -C ~/.celestia-app/data/
sudo systemctl restart celestia-appd && journalctl -u celestia-appd -f -o cat

break
;;

"Exit")
exit

esac
done
