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
FTP_PORT=21

# CHECK IF THE HOST IS UP 
function check_host(){
echo -e "Checking if the host is up ..."
nmap $IP_ADDR -p $FTP_PORT &> check_host.txt
if grep -q "Host is up" check_host.txt; 
then
HOST_UP=true
fi
}

# CHECK IF THE FTP PORT $FTP_PORT IS OPEN 
function  knock_port(){
echo -e "Knocking the FTP port ..."
if grep -q "$FTP_PORT/tcp open  ftp" check_host.txt
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
nmap --script=banner $IP_ADDR -p $FTP_PORT > banner.txt
BANNER=$(grep "banner" banner.txt)
REMOVE_STRING="|_banner: "
echo ${BANNER//$REMOVE_STRING}
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
echo "The FTP port $FTP_PORT is OPEN on $IP_ADDR"
else
echo "The FTP port $FTP_PORT is CLOSED on $IP_ADDR"
fi
print_line

get_banner
print_line

