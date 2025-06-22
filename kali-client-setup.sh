#!/bin/bash

# prevent running as root or via sudo
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run this script as root or via sudo. Run as a normal user."
  exit 1
fi

grey='\033[90m'
green='\033[32m'
teal='\033[36m'
red='\033[31m'
blue='\033[34m'
reset='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/ssltls"
mkdir -p "$SSL_DIR"

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 FRAMEWORK CLIENT SETUP SCRIPT${reset}"
echo -e "${grey}[${grey}~${grey}] ${grey}kali edition${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring dependencies...${reset}"
sudo apt update
sudo apt install -y --fix-missing golang-1.24 mingw-w64 make cmake libssl-dev qt6-base-dev qt6-websockets-dev
if [[ ! -e /usr/local/bin/go ]]; then
  sudo ln -s /usr/lib/go-1.24/bin/go /usr/local/bin/go
fi

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling client...${reset}"
make client

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}USAGE:${reset}"
echo -e "${grey}./dist/AdaptixClient${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 CLIENT SETUP complete.${reset}"
echo " "
