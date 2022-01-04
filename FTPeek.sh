#!/bin/bash

# FTPeek
# FTP ENUMERATION TOOL FOR FINDING 
# COMMON MISCONFIGURATIONS AND VULNERABILITIES

# MAKE SURE THE LATEST VERSION OF NMAP AND WGET IS INSTALLED

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
ANONYMOUS_LOGIN_ENABLED=false
ANONYMOUS_LOGIN_SUCCESSFUL=false

# PRINT A LINE AFTER EACH CHECK
function print_line(){
	for i in {1..25}; do echo -n "-"; done
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
echo "Getting all the files and directories, including the hidden ones ..."
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
echo "Hidden Files"
echo "------------"
cat /tmp/hidden_files.txt
fi
if [ $HIDDEN_DIRECTORY_COUNT -gt 0 ]
then
echo "Hidden Directories"
echo "------------------"
cat /tmp/hidden_directories.txt
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
UPLOAD_ENABLED=true
else
UPLOAD_ENABLED=false
fi
rm /tmp/check_upload_permissions.txt /tmp/check_upload.txt
}

################### DRIVER CODE ###################
echo -e "[FTPeek]"
echo

check_host
if $HOST_UP
then
echo "$IP_ADDR is UP"
else
echo "$IP_ADDR is DOWN"
fi
echo

knock_port
if $PORT_OPEN 
then
echo "The FTP port $FTP_PORT is OPEN on $IP_ADDR"
else
echo "The FTP port $FTP_PORT is CLOSED on $IP_ADDR"
fi
echo

get_banner
echo ""

check_anonymous
if $ANONYMOUS_LOGIN_ENABLED
then
echo -e "Anonymous login is enabled!"
else
echo -e "Anonymous login is not enabled on this host"
fi
echo

login_anonymous
if $ANONYMOUS_LOGIN_SUCCESSFUL
then
echo -e "Anonymous Login Successful!"
else
echo -e "Anonymous Login Failed"
fi
echo

list_files_directories
echo

check_upload_permissions
if $UPLOAD_ENABLED
then
echo -e "File upload Successful!"
else
echo -e "File upload Failed"
fi
echo