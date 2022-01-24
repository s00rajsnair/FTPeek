#!/bin/bash

# FTPeek on a Single Target
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
TARGET=$1
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
LOGIN_SUCCESSFUL=false
UPLOAD_SUCCESSFUL=false
CREDENTIALS_FOUND=false
FOUND_USERNAME=''
FOUND_PASSWORD=''
GREEN_BUTTON=$(echo -e "${BOLDGREEN}[+]${RESET}")
RED_BUTTON=$(echo -e "${BOLDRED}[-]${RESET}")
COMMON_USERNAMES=(ADMIN Admin Guest Root USER a guest User admin default ftpuser httpadmin localadmin none root supervisor test user user1 webserver)
COMMON_PASSWORDS=(1111 1234 12345 123456 9999 USER admin admin12345 default ftp guest localadmin none password rootpasswd supervisor system testingpw user webpages)

# PRINT A LINE AFTER EACH CHECK
function print_line(){
	for i in {1..50}; do echo -n "-"; done
	echo
}

# CHECK IF THE HOST IS UP 
function check_host(){
echo -e "Checking if the host is up ..."
nmap $TARGET -Pn &> /tmp/check_host.txt
if grep -q "Host is up" /tmp/check_host.txt; 
then
HOST_UP=true
fi
rm  /tmp/check_host.txt
}

# CHECK IF THE FTP PORT $FTP_PORT IS OPEN 
function  knock_port(){
echo -e "Knocking the FTP port ..."
nmap $TARGET -p $FTP_PORT -Pn &> /tmp/knock_port.txt
if grep -q "$FTP_PORT/tcp open  ftp" /tmp/knock_port.txt;
then
PORT_OPEN=true
fi 
rm /tmp/knock_port.txt
}

# RETREIVING THE BANNER 
function get_banner(){
echo -e "Grabbing FTP Banner ..."
nmap --script=banner $TARGET -p $FTP_PORT -Pn &> /tmp/get_banner.txt
BANNER=$(grep "banner" /tmp/get_banner.txt)
REMOVE_STRING="|_banner: "
echo -e ${BOLDWHITE}${BANNER//$REMOVE_STRING}${RESET}
rm /tmp/get_banner.txt
}

# CHECK IF ANONYMOUS LOGIN IS ENABLED
function check_anonymous(){
nmap $TARGET -p $FTP_PORT -A -Pn &> /tmp/check_anonymous.txt
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
login anonymous anonymous
if $LOGIN_SUCCESSFUL
then
ANONYMOUS_LOGIN_SUCCESSFUL=true
fi
}

# LOGIN ATTEMPT ON FTP
function login(){
LOGIN_SUCCESSFUL=false
bash -c "ftp -nvp $TARGET <<END
user $1 $2
bye
END" &> /tmp/login.txt
if egrep -q "Login successful|User logged in." /tmp/login.txt 
then
LOGIN_SUCCESSFUL=true
fi
rm /tmp/login.txt

}

# ATTEMPT BRUTEFORCE
function bruteforce_credentials(){
	echo -ne "Conducting Bruteforce "
	for i in {0..19}
	do
		login ${COMMON_USERNAMES[$i]}  ${COMMON_PASSWORDS[$i]}   
		echo -ne ■ 
		if $LOGIN_SUCCESSFUL
		then
			CREDENTIALS_FOUND=true
			echo
			echo -e "${GREEN_BUTTON} Credentials Found!"
			echo -e "${BOLDRED} ${COMMON_USERNAMES[$i]}:${COMMON_PASSWORDS[$i]} ${RESET}"
			FOUND_USERNAME=${COMMON_USERNAMES[$i]}
			FOUND_PASSWORD=${COMMON_PASSWORDS[$i]}
			break
		fi
	done
	echo
}

# LISING ALL THE FILES AND  DIRECTORIES
function list_files_directories(){
echo "Listing the contents of the server ..."
wget -r ftp://$TARGET &> /dev/null --user $1 --password $2

echo
tree $TARGET -a
find $TARGET -type f -name '.*' > /tmp/hidden_files.txt
find $TARGET -type d -name '.*' > /tmp/hidden_directories.txt
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
rm -rf $TARGET
rm /tmp/hidden_files.txt /tmp/hidden_directories.txt 
}

# CHECK IF A FILE CAN BE UPLOADED TO THE HOST 
function check_upload_permissions(){
echo "Checking if anonymous upload is enabled ..."
touch /tmp/check_upload.txt
bash -c "ftp -nvp $TARGET <<END
user $1 $2
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
echo -e ${BOLDWHITE}
echo "
 	   _____________          __  
	  / __/_  __/ _ \___ ___ / /__
	 / _/  / / / ___/ -_) -_)  '_/
	/_/   /_/ /_/   \__/\__/_/\_\ 
"
echo -e ${RESET}

print_line
if [ -z $TARGET  ] || [ $TARGET == "-h" ] || [ $TARGET == "--help" ] || [ $TARGET == "-help" ]
then
	echo "Please enter a target IP address OR the first 3 octets of the /24 network OR the hostname"
	echo "Usage:  ./FTPeek.sh Target [Desired Port]"
	echo "The desired port is optional. By default this script scans port 21"
	echo "Examples:  "
	echo "     ./FTPeek.sh 192.168.1.2"
	echo "     ./FTPeek.sh 192.168.1 2211"
	echo "     ./FTPeek.sh localhost 2121"
	echo "     ./FTPeek.sh google.com"

	exit
else
	echo -e "Target: ${BOLDWHITE}$TARGET${RESET}"
	check_host
	if $HOST_UP
	then
		echo -e "$GREEN_BUTTON $TARGET is UP"
		knock_port
		if $PORT_OPEN 
		then
			echo -e "$GREEN_BUTTON The FTP port $FTP_PORT is OPEN on $TARGET"
			get_banner
			check_anonymous
			if $ANONYMOUS_LOGIN_ENABLED
			then
				echo -e "$GREEN_BUTTON Anonymous login is enabled!"
				login_anonymous
				if $ANONYMOUS_LOGIN_SUCCESSFUL
				then
					echo -e "$GREEN_BUTTON Anonymous Login Successful!"
					list_files_directories anonymous anonymous
					check_upload_permissions anonymous anonymous
					if $UPLOAD_SUCCESSFUL
					then
						echo -e "$GREEN_BUTTON File Upload is Enabled for anonymous!"
					else
						echo -e "$RED_BUTTON File Upload is Disabled for anonymous"
					fi
				else
					echo -e "$RED_BUTTON Anonymous Login Failed"
				fi
			else
				echo -e "$RED_BUTTON Anonymous login is not enabled"
				bruteforce_credentials
				if $CREDENTIALS_FOUND
				then
					list_files_directories $FOUND_USERNAME $FOUND_PASSWORD
					check_upload_permissions $FOUND_USERNAME $FOUND_PASSWORD
					if $UPLOAD_SUCCESSFUL
					then
						echo -e "$GREEN_BUTTON File Upload is Enabled for $FOUND_USERNAME!"
					else
						echo -e "$RED_BUTTON File Upload is Disabled for $FOUND_USERNAME"
					fi
				else 
					echo -e "$RED_BUTTON Could not find any common credentials"
				fi
			fi
		else
			echo -e "$RED_BUTTON The FTP port $FTP_PORT is CLOSED on $TARGET"
		fi
	else
		echo -e "$RED_BUTTON $TARGET is DOWN"
	fi
fi
print_line
echo "Done with peeking. Thank You for using FTPeek!"