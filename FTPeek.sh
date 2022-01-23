#!/bin/bash

# FTPeek
# FTP ENUMERATION TOOL FOR FINDING 
# COMMON MISCONFIGURATIONS AND VULNERABILITIES

# MAKE SURE THE LATEST VERSION OF NMAP, WGET IS INSTALLED

# COLORS
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

if [ -z $2 ] 
then
	FTP_PORT=21
else
	FTP_PORT=$2
fi

ANONYMOUS_LOGIN_ENABLED=false
ANONYMOUS_LOGIN_SUCCESSFUL=false
UPLOAD_SUCCESSFUL=false
green_button=$(echo -e "${BOLDGREEN}[+]${RESET}")
red_button=$(echo -e "${BOLDRED}[-]${RESET}")

# PRINT A LINE AFTER EACH CHECK
function print_line(){
	for i in {1..50}; do echo -n "-"; done
	echo
}

# CHECK IF THE HOST IS UP 
function check_host(){
echo -e "Checking if the host is up ..."
nmap $IP_ADDR -Pn &> /tmp/check_host.txt
if grep -q "Host is up" /tmp/check_host.txt; 
then
HOST_UP=true
fi
rm  /tmp/check_host.txt
}

# CHECK IF THE FTP PORT $FTP_PORT IS OPEN 
function  knock_port(){
echo -e "Knocking the FTP port ..."
nmap $IP_ADDR -p $FTP_PORT -Pn &> /tmp/knock_port.txt
if grep -q "$FTP_PORT/tcp open  ftp" /tmp/knock_port.txt;
then
PORT_OPEN=true
fi 
rm /tmp/knock_port.txt
}

# RETREIVING THE BANNER 
function get_banner(){
echo -e "Grabbing FTP Banner ..."
nmap --script=banner $IP_ADDR -p $FTP_PORT -Pn &> /tmp/get_banner.txt
BANNER=$(grep "banner" /tmp/get_banner.txt)
REMOVE_STRING="|_banner: "
echo ${BANNER//$REMOVE_STRING}
rm /tmp/get_banner.txt
}

# CHECK IF ANONYMOUS LOGIN IS ENABLED
function check_anonymous(){
nmap $IP_ADDR -p $FTP_PORT -A -Pn &> /tmp/check_anonymous.txt
echo "Checking for Anonymous Login ..."
if grep -q "Anonymous FTP login allowed" /tmp/check_anonymous.txt
then
ANONYMOUS_LOGIN_ENABLED=true
fi
rm /tmp/check_anonymous.txt
}

# TRYING TO LOGIN AS ANONYMOUS USER
function login_anonymous(){
echo "Attempting Anonymous Login ..."
bash -c "ftp -nvp $IP_ADDR <<END
user anonymous anonymous
bye
END" &> /tmp/login_anonymous.txt
if egrep -q "Login successful|User logged in." /tmp/login_anonymous.txt 
then
ANONYMOUS_LOGIN_SUCCESSFUL=true
fi
rm /tmp/login_anonymous.txt
}

# LISING ALL THE FILES AND  DIRECTORIES
function list_files_directories(){
echo "Listing the contents of the server ..."
wget -r ftp://$IP_ADDR &> /tmp/list_files_directories.txt 
echo
tree $IP_ADDR -a
find $IP_ADDR -type f -name '.*' > /tmp/hidden_files.txt
find $IP_ADDR -type d -name '.*' > /tmp/hidden_directories.txt
HIDDEN_FILE_COUNT=$(cat /tmp/hidden_files.txt | wc -l)
HIDDEN_DIRECTORY_COUNT=$(cat /tmp/hidden_directories.txt | wc -l)
echo
echo "Hidden Files : $HIDDEN_FILE_COUNT"
echo "Hidden Directories : $HIDDEN_DIRECTORY_COUNT"  
if [ $HIDDEN_FILE_COUNT -gt 0 ]
then
echo
echo "Hidden Files"
echo "------------"
cat /tmp/hidden_files.txt
echo
fi
if [ $HIDDEN_DIRECTORY_COUNT -gt 0 ]
then
echo "Hidden Directories"
echo "------------------"
cat /tmp/hidden_directories.txt
echo
fi
rm -rf $IP_ADDR
rm /tmp/hidden_files.txt /tmp/hidden_directories.txt /tmp/list_files_directories.txt
}

# CHECK IF A FILE CAN BE UPLOADED TO THE HOST 
function check_upload_permissions(){
echo "Checking if anonymous upload is enabled ..."
touch /tmp/check_upload.txt
bash -c "ftp -nvp $IP_ADDR <<END
user anonymous anonymous
put /tmp/check_upload.txt check_upload.txt
END" &> /tmp/check_upload_permissions.txt
if grep -q "Transfer complete" /tmp/check_upload_permissions.txt
then
UPLOAD_SUCCESSFUL=true
else
UPLOAD_SUCCESSFUL=false
fi
rm /tmp/check_upload_permissions.txt /tmp/check_upload.txt
}

################### DRIVER CODE ###################
echo '
	8888888888 88888888888 8888888b.                   888      
	888            888     888   Y88b                  888      
	888            888     888    888                  888      
	8888888        888     888   d88P .d88b.   .d88b.  888  888 
	888            888     8888888P" d8P  Y8b d8P  Y8b 888 88P 
	888            888     888       88888888 88888888 888888K  
	888            888     888       Y8b.     Y8b.     888  88b 
	888            888     888        "Y8888   "Y8888  888   888
'
print_line
if [ -z $IP_ADDR  ] || [ $IP_ADDR == "-h" ] || [ $IP_ADDR == "--help" ] || [ $IP_ADDR == "-help" ]
then
	echo "Please enter a target IP address or Subnet Address "
	echo "Usage:  ./FTPeek.sh <IP or Subnet> [Desired Port (21 by default)]"
	echo "Examples:  "
	echo "     ./FTPeek.sh 192.168.1.2"
	echo "     ./FTPeek.sh 192.168.1.0/24"
	echo "     ./FTPeek.sh localhost"
	exit
else
	echo "Target: $IP_ADDR"
	check_host
	if $HOST_UP
	then
		echo -e "$green_button $IP_ADDR is UP"
		knock_port
		if $PORT_OPEN 
		then
			echo -e "$green_button The FTP port $FTP_PORT is OPEN on $IP_ADDR"
			get_banner
			check_anonymous
			if $ANONYMOUS_LOGIN_ENABLED
			then
				echo -e "$green_button Anonymous login is enabled!"
				login_anonymous
				if $ANONYMOUS_LOGIN_SUCCESSFUL
				then
					echo -e "$green_button Anonymous Login Successful!"
					list_files_directories
					check_upload_permissions
					if $UPLOAD_SUCCESSFUL
					then
						echo -e "$green_button Anonymous Upload is Enabled!"
					else
						echo -e "$red_button Anonymous Upload is Disabled"
					fi
				else
					echo -e "$red_button Anonymous Login Failed"
				fi
			else
				echo -e "$red_button Anonymous login is not enabled on this host"
			fi
		else
			echo -e "$red_button The FTP port $FTP_PORT is CLOSED on $IP_ADDR"
		fi
	else
		echo -e "$red_button $IP_ADDR is DOWN"
	fi
fi
print_line
echo "Exiting ..."