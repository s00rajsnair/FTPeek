#!/bin/bash

# SINGLE MACHINE SCANNER

################### CONSTANTS ###################
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
FTP_PORT=21

ANONYMOUS_LOGIN_ENABLED=false
ANONYMOUS_LOGIN_SUCCESSFUL=false
LOGIN_SUCCESSFUL=false
UPLOAD_SUCCESSFUL=false
CREDENTIALS_FOUND=false
FOUND_USERNAME=''
FOUND_PASSWORD=''
UPLOAD_ENABLED_DIRECTORY=''
GREEN_BUTTON=$(echo -e "${BOLDGREEN}[+]${RESET}")
RED_BUTTON=$(echo -e "${BOLDRED}[-]${RESET}")
COMMON_USERNAMES=(root administrator admin ftpuser test)
COMMON_PASSWORDS=(1234 ftp password admin default)

################### FUNCTIONS ###################

# PRINT A LINE AFTER EACH CHECK
function print_line(){
	for i in {1..50}; 
	do 
		echo -n "-"; 
	done
	echo
}

# CHECK IF THE HOST IS UP 
function check_host(){
	echo -e "Checking if the host is up ..."
	ping -c 1 $TARGET  &> /tmp/check_host_FTPeek.txt
	if grep -q "bytes from" /tmp/check_host_FTPeek.txt; 
	then
		HOST_UP=true
	fi
		rm  /tmp/check_host_FTPeek.txt
}

# CHECK IF THE FTP PORT $FTP_PORT IS OPEN 
function  knock_port(){
	echo -e "Knocking the FTP port ..."
	nmap $TARGET -p $FTP_PORT -Pn &> /tmp/knock_port_FTPeek.txt
	if grep -q "$FTP_PORT/tcp open  ftp" /tmp/knock_port_FTPeek.txt;
	then
		PORT_OPEN=true
	fi 
		rm /tmp/knock_port_FTPeek.txt
}

# RETREIVING THE BANNER 
function get_banner(){
	echo -e "Grabbing FTP Banner ..."
	nmap --script=banner $TARGET -p $FTP_PORT -Pn &> /tmp/get_banner_FTPeek.txt
	BANNER=$(grep "banner" /tmp/get_banner_FTPeek.txt)
	REMOVE_STRING="|_banner: "
	echo -e ${BOLDWHITE}${BANNER//$REMOVE_STRING}${RESET}
	rm /tmp/get_banner_FTPeek.txt
}

# CHECK IF ANONYMOUS LOGIN IS ENABLED
function check_anonymous(){
	nmap $TARGET -p $FTP_PORT -A -Pn &> /tmp/check_anonymous_FTPeek.txt
	echo "Checking for Anonymous Login ..."
	if grep -q "Anonymous FTP login allowed" /tmp/check_anonymous_FTPeek.txt
	then
		ANONYMOUS_LOGIN_ENABLED=true
	fi
		rm /tmp/check_anonymous_FTPeek.txt
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
	END" &> /tmp/login_FTPeek.txt
	if egrep -q "Login successful|User logged in." /tmp/login_FTPeek.txt 
	then
	LOGIN_SUCCESSFUL=true
	fi
	rm /tmp/login_FTPeek.txt
}

# ATTEMPT BRUTEFORCE
function bruteforce_credentials(){
	COMMON_USERNAMES_LENGTH=${#COMMON_USERNAMES[@]}
	COMMON_USERNAMES_LENGTH=${#COMMON_USERNAMES[@]}

	echo -e "Conducting Bruteforce ..."
	PROGRESS_BAR_COUNT=0
	for username in ${COMMON_USERNAMES[@]}
	do
		for password in ${COMMON_PASSWORDS[@]}
		do 
			login $username $password 
			echo -ne "${BOLDWHITE}.${RESET}"
			if $LOGIN_SUCCESSFUL
			then
				CREDENTIALS_FOUND=true
				echo
				echo -e "${GREEN_BUTTON} Credentials Found!"
				echo -e "${BOLDRED}$username${RESET}:${BOLDRED}$password${RESET}"
				FOUND_USERNAME=$username
				FOUND_PASSWORD=$password
				break
			fi
		done
		if $CREDENTIALS_FOUND
		then
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
	find $TARGET -type f -name '.*' > /tmp/hidden_files_FTPeek.txt
	find $TARGET -type d -name '.*' > /tmp/hidden_directories_FTPeek.txt
	find $TARGET -type d  > /tmp/directories_FTPeek.txt
	HIDDEN_FILE_COUNT=$(cat /tmp/hidden_files_FTPeek.txt | wc -l)
	HIDDEN_DIRECTORY_COUNT=$(cat /tmp/hidden_directories_FTPeek.txt | wc -l)
	echo
	echo "Hidden Files : $HIDDEN_FILE_COUNT"
	echo "Hidden Directories : $HIDDEN_DIRECTORY_COUNT"  
	if [ $HIDDEN_FILE_COUNT -gt 0 ]
	then
		echo
		echo "Hidden Files"
		echo "------------"
		cat /tmp/hidden_files_FTPeek.txt
		echo
	fi
	if [ $HIDDEN_DIRECTORY_COUNT -gt 0 ]
	then
		echo "Hidden Directories"
		echo "------------------"
		cat /tmp/hidden_directories_FTPeek.txt
		echo
	fi
	rm -rf $TARGET
	rm /tmp/hidden_files_FTPeek.txt /tmp/hidden_directories_FTPeek.txt 
}

# CHECK IF A FILE CAN BE UPLOADED TO THE HOST 
function check_upload_permissions(){
	echo "Checking if anonymous upload is enabled ..."
	touch /tmp/check_upload_FTPeek.txt

	TARGET_NAME_LENGTH=${#TARGET}
	TARGET_NAME_LENGTH=`expr $TARGET_NAME_LENGTH + 1`

	cut -c$TARGET_NAME_LENGTH- /tmp/directories_FTPeek.txt > /tmp/directories_cut_FTPeek.txt
	sed -i '/^$/d'  /tmp/directories_cut_FTPeek.txt

	while IFS= read -r directory; do
		bash -c "ftp -nv $TARGET <<END
		user $1 $2
		cd $directory
		put /tmp/check_upload_FTPeek.txt $RANDOM_FTPeek.txt
		exit
		END" &> /tmp/check_upload_permissions_FTPeek.txt

		if grep -q "Transfer complete" /tmp/check_upload_permissions_FTPeek.txt
		then
			UPLOAD_SUCCESSFUL=true
			UPLOAD_ENABLED_DIRECTORY=$directory
			return 0
		else
			UPLOAD_SUCCESSFUL=false
		fi
	done < /tmp/directories_cut_FTPeek.txt

	rm /tmp/check_upload_permissions_FTPeek.txt /tmp/check_upload_FTPeek.txt
}

################### DRIVER CODE ###################

print_line
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
					echo -e "Go to the folder ${BOLDWHITE}$UPLOAD_ENABLED_DIRECTORY${RESET} and upload any payload you want to."
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
echo "Scan done for $TARGET"