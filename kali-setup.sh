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
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 FRAMEWORK SETUP SCRIPT${reset}"
echo -e "${grey}[${grey}~${grey}] ${grey}kali edition${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring dependencies...${reset}"
sudo apt update
sudo apt install -y --fix-missing golang-1.24 mingw-w64 make cmake libssl-dev qt6-base-dev qt6-websockets-dev
if [[ ! -e /usr/local/bin/go ]]; then
  sudo ln -s /usr/lib/go-1.24/bin/go /usr/local/bin/go
fi

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling server...${reset}"
make server

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling and linking extenders...${reset}"

cd Extenders/agent_beacon || exit 1
make
sed -i '3s|"extender_file": "agent_beacon.so"|"extender_file": "dist/agent_beacon.so"|' config.json
cd - >/dev/null

cd Extenders/agent_gopher || exit 1
make
sed -i '3s|"extender_file": "agent_gopher.so"|"extender_file": "dist/agent_gopher.so"|' config.json
cd - >/dev/null

cd Extenders/listener_beacon_http || exit 1
make
sed -i '3s|"extender_file": "listener_beacon_http.so"|"extender_file": "dist/listener_beacon_http.so"|' config.json
cd - >/dev/null

cd Extenders/listener_beacon_smb || exit 1
make
sed -i '3s|"extender_file": "listener_beacon_smb.so"|"extender_file": "dist/listener_beacon_smb.so"|' config.json
cd - >/dev/null

cd Extenders/listener_beacon_tcp || exit 1
make
sed -i '3s|"extender_file": "listener_beacon_tcp.so"|"extender_file": "dist/listener_beacon_tcp.so"|' config.json
cd - >/dev/null

cd Extenders/listener_gopher_tcp || exit 1
make
sed -i '3s|"extender_file": "listener_gopher_tcp.so"|"extender_file": "dist/listener_gopher_tcp.so"|' config.json
cd - >/dev/null

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling client...${reset}"
make client

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring default server profile...${reset}"
cat > "$SCRIPT_DIR/default.json" << 'EOF'
{
  "Teamserver": {
    "port": 60666,
    "endpoint": "/endpoint",
    "password": "haxpass123!",
    "cert": "ssltls/ca-server.rsa.crt",
    "key": "ssltls/ca-server.rsa.key",
    "extenders": [
      "Extenders/listener_beacon_http/config.json",
      "Extenders/listener_beacon_smb/config.json",
      "Extenders/listener_beacon_tcp/config.json",
      "Extenders/agent_beacon/config.json",
      "Extenders/listener_gopher_tcp/config.json",
      "Extenders/agent_gopher/config.json"
    ]
  },

  "ServerResponse": {
    "status": 404,
    "headers": {
      "Content-Type": "text/html; charset=UTF-8",
      "Server": "Microsoft-IIS"
    },
    "page": "404.html"
  }
}
EOF

cat > "$SCRIPT_DIR/404.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Whoopsies</title>
  <meta charset="UTF-8">
</head>
<body>
  <h1>Whoops!</h1>
  <p>Query was not valid.</p>
</body>
</html>
EOF
echo -e "${grey}[${green}+${grey}] ${blue}Done!${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Teamserver SSL key & cert generation...${reset}"
read -p "Generate test SSL key & cert for server lab testing? [y/N]: " gen_server
if [[ "$gen_server" =~ ^[Yy]$ ]]; then
  openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -keyout "$SSL_DIR/ca-server.rsa.key" -out "$SSL_DIR/ca-server.rsa.crt" -subj '/CN=Test Server'
else
  echo -e "${grey}[${red}-${grey}] ${blue}Skipping test SSL key & cert generation for server.${reset}"
fi

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Gopher mTLS key & cert generation...${reset}"
read -p "Generate mTLS key & cert for Gopher agent lab testing? [y/N]: " gen_mtls
if [[ "$gen_mtls" =~ ^[Yy]$ ]]; then
  openssl genrsa -out "$SSL_DIR/mTLS-ca.key" 2048
  openssl req -x509 -new -nodes -key "$SSL_DIR/mTLS-ca.key" -sha256 -days 3650 \
    -out "$SSL_DIR/mTLS-ca.crt" -subj '/CN=Test CA'

  echo -e "${grey}[${green}+${grey}] ${blue}Generating mTLS server key, CSR, and signed cert...${reset}"
  openssl genrsa -out "$SSL_DIR/mTLS-server.key" 2048
  openssl req -new -key "$SSL_DIR/mTLS-server.key" -out "$SSL_DIR/mTLS-server.csr" -subj '/CN=localhost'
  openssl x509 -req -in "$SSL_DIR/mTLS-server.csr" -CA "$SSL_DIR/mTLS-ca.crt" -CAkey "$SSL_DIR/mTLS-ca.key" \
    -CAcreateserial -out "$SSL_DIR/mTLS-server.crt" -days 365 -sha256

  echo -e "${grey}[${green}+${grey}] ${blue}Generating mTLS client key, CSR, and signed cert...${reset}"
  openssl genrsa -out "$SSL_DIR/mTLS-client.key" 2048
  openssl req -new -key "$SSL_DIR/mTLS-client.key" -out "$SSL_DIR/mTLS-client.csr" -subj '/CN=client'
  openssl x509 -req -in "$SSL_DIR/mTLS-client.csr" -CA "$SSL_DIR/mTLS-ca.crt" -CAkey "$SSL_DIR/mTLS-ca.key" \
    -CAcreateserial -out "$SSL_DIR/mTLS-client.crt" -days 365 -sha256
else
  echo -e "${grey}[${red}-${grey}] ${blue}Skipping mTLS key & cert generation for Gopher agent.${reset}"
fi

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}USAGE:${reset}"
echo -e "${grey}./dist/adaptixserver -debug -profile default.json${reset}"
echo -e "${grey}./dist/AdaptixClient${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 FRAMEWORK SETUP complete.${reset}"
echo " "
