#!/bin/bash

# FTP ENUMERATION TOOL FOR FINDING 
# COMMON MISCONFIGURATIONS AND VULNERABILITIES

# COLORS FOR BETTER VIEWING EXPERIENCE OF THE REPORT
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
WHITE="\e[97m"
BOLDRED="\e[1;31m"
BOLDYELLOW="\e[1;33m"
BOLDGREEN="\e[1;32m"
BOLDWHITE="\e[1;97m"
RESET="\e[0m"

# VARIABLES
IP_ADDR=$1
HOST_UP=false
PORT_OPEN=false

# CHECK IF THE HOST IS UP OR NOT
function check_host(){
echo -e "Checking if the host is up ..."
nmap -sn $IP_ADDR  &> check_host.txt
HOST_MESSAGE=$(awk '{if(NR==3) print $0}' check_host.txt)
if [[ $HOST_MESSAGE =~ ^(Host is up.*)$ ]];
then
HOST_UP=true
fi
}

# CHECK IF THE FTP PORT 21 IS OPEN OR NOT
function  knock_port(){
echo -e "Knocking the FTP port on $IP_ADDR ..."
bash -c "ftp -nv $IP_ADDR <<END
bye
END" &> knock_port.txt
PORT_MESSAGE=$(awk '{if(NR==1) print $0}' knock_port.txt)
if [[ $PORT_MESSAGE =~ "Connected to $IP_ADDR." ]]
then
PORT_OPEN=true
fi
}

function print_line(){
	for i in {1..40}; do echo -n "-"; done
	echo
}

# BANNER ENUMERATION
function get_banner(){
echo -e "Grabbing FTP Banner ..."
}

# DRIVER CODE
echo -e "${BOLDWHITE}[ FTP ENUMERATION TOOL ]${RESET}"
echo -e "========================================"

check_host
if $HOST_UP
then
echo "$IP_ADDR is UP"
else
echo "$IP_ADDR is DOWN"
fi
print_line

knock_port
if $PORT_OPEN
then
echo "The FTP port 21 is OPEN on $IP_ADDR"
else
echo "The FTP port 21 is CLOSED on $IP_ADDR"
fi
print_line

