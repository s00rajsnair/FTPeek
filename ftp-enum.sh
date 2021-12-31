#!/bin/bash

# FTP ENUMERATION TOOL FOR FINDING 
# COMMON MISCONFIGURATIONS AND VULNERABILITIES

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
WHITE="\e[97m"
BOLDRED="\e[1;${RED}m"
BOLDYELLOW="\e[1;33m"
BOLDGREEN="\e[1;32m"
BOLDWHITE="\e[1;97m"
RESET="\e[0m"

echo -e "${BOLDWHITE}[[ FTP ENUMERATION TOOL ]] ${RESET}"
IP_ADDR=$1

# BANNER ENUMERATION 
function get_banner(){
echo -e "Grabbing FTP Banner ..."
bash -c "ftp -vn $IP_ADDR<< END
bye 
END" > banner.txt
}

get_banner



