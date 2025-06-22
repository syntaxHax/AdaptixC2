#!/bin/bash

grey='\033[90m'
green='\033[32m'
teal='\033[36m'
red='\033[31m'
blue='\033[34m'
reset='\033[0m'

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 SERVER SETUP SCRIPT${reset}"
echo -e "${grey}[${grey}~${grey}] ${grey}digitalOcean (ubuntu 24.04 LTS) edition${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}Configuring dependencies...${reset}"

apt update && apt install --fix-missing -y golang-1.23 mingw-w64 make && ln -s /usr/lib/go-1.23/bin/go /usr/local/bin/go

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
echo -e "${grey}[${green}+${grey}] ${blue}Configuring default team server profile...${reset}"

cat > "$(dirname "$0")/default.json" << 'EOF'
{
  "Teamserver": {
    "port": 60666,
    "endpoint": "/fleuriste",
    "password": "haxpass123!",
    "cert": "/opt/AdaptixC2/ssl/team_https.crt",
    "key": "/opt/AdaptixC2/ssl/team_https.key",
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
      "Server": "Fleuriste Clarice",
      "X-Conf": "47329.4"
    },
    "page": "404.html"
  }
}
EOF

cat > "$(dirname "$0")/404.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Fleuriste Clarice - 404</title><meta charset="UTF-8"></head>
<body> </body>
</html>
EOF

mkdir -p /opt/AdaptixC2/ssl && chmod 700 /opt/AdaptixC2/ssl

echo " "
echo -e "${grey}[${green}+${grey}] ${blue}USAGE:${reset}"
echo -e "${grey}./dist/adaptixserver -debug -profile default.json${reset}"

echo " "
echo -e "${grey}[${green}+${grey}] ${teal}ADAPTIX C2 SERVER SETUP complete.${reset}"
echo " "
