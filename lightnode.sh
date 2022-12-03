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
