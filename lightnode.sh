#!/bin/bash

# Install Dependencies
echo "================ Install Dependencies ====================="
sudo apt update && sudo apt upgrade -y >/dev/null
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y >/dev/null

# Install Go
echo "================ Install Go ====================="
ver="1.18.2"
sudo rm -rf /usr/local/go
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile

go version

# Install Celestia-node
echo "================ Install Celestia-node ====================="
cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/v0.3.0-rc2
make install
make cel-key

# Initialize Light Node
echo "=============== Initialize Light Node ==============="
celestia light init

# Generate key
echo "=============== Generate key ==============="
cd $HOME/celestia-node
./cel-key add celeKey --keyring-backend test --node.type light &> $HOME/keys.txt

# SystemD
echo "=============== SystemD ================"
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-lightd.service
[Unit]
Description=celestia-lightd Light Node
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/celestia light start --core.grpc https://rpc-mamaki.pops.one:9090 --keyring.accname celeKey
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-lightd
sudo systemctl start celestia-lightd
