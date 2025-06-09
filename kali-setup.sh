#!/bin/bash

grey='\033[90m'
green='\033[32m'
teal='\033[36m'
red='\033[31m'
blue='\033[34m'
reset='\033[0m'

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 FRAMEWORK SETUP SCRIPT${reset}"
echo -e "${grey}[${grey}~${grey}] ${grey}kali edition${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring dependencies...${reset}"

sudo apt update
sudo apt install -y --fix-missing golang-1.24 mingw-w64 make cmake libssl-dev qt6-base-dev qt6-websockets-dev
sudo ln -s /usr/lib/go-1.24/bin/go /usr/local/bin/go

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling server...${reset}"

make server

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling and linking extenders...${reset}"

cd Extenders/agent_beacon
make
sed -i '3s|"extender_file": "agent_beacon.so"|"extender_file": "dist/agent_beacon.so"|' config.json
cd ../../

cd Extenders/agent_gopher
make
sed -i '3s|"extender_file": "agent_gopher.so"|"extender_file": "dist/agent_gopher.so"|' config.json
cd ../../

cd Extenders/listener_beacon_http
make
sed -i '3s|"extender_file": "listener_beacon_http.so"|"extender_file": "dist/listener_beacon_http.so"|' config.json
cd ../../

cd Extenders/listener_beacon_smb
make
sed -i '3s|"extender_file": "listener_beacon_smb.so"|"extender_file": "dist/listener_beacon_smb.so"|' config.json
cd ../../

cd Extenders/listener_beacon_tcp
make
sed -i '3s|"extender_file": "listener_beacon_tcp.so"|"extender_file": "dist/listener_beacon_tcp.so"|' config.json
cd ../../

cd Extenders/listener_gopher_tcp
make
sed -i '3s|"extender_file": "listener_gopher_tcp.so"|"extender_file": "dist/listener_gopher_tcp.so"|' config.json
cd ../../

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Compiling client...${reset}"

make client

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring default server profile...${reset}"

cat > "$(dirname "$0")/default.json" << 'EOF'
{
  "Teamserver": {
    "port": 60666,
    "endpoint": "/endpoint",
    "password": "haxpass123!",
    "cert": "server.rsa.crt",
    "key": "server.rsa.key",
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
      "Server": "Microsoft-IIS",
    },
    "page": "404.html"
  }
}
EOF

cat > "$(dirname "$0")/404.html" << 'EOF'
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

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Generate SSL keys for testing:${reset}"
echo -e "${grey}openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.rsa.key -out server.rsa.crt${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}USAGE:${reset}"
echo -e "${grey}./dist/adaptixserver -debug -profile default.json${reset}"
echo -e "${grey}./dist/AdaptixClient${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 FRAMEWORK SETUP complete.${reset}"
echo " "