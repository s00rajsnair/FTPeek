#!/bin/bash

# FTPeek on a Single Target
# FTP ENUMERATION TOOL FOR FINDING 
# COMMON MISCONFIGURATIONS AND VULNERABILITIES

# MAKE SURE THE LATEST VERSION OF NMAP, WGET IS INSTALLED

# PRINT A LINE AFTER EACH CHECK

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

function print_line(){
	for i in {1..50}; 
	do 
		echo -n "-"; 
	done
	echo
}


TARGET=$1
echo -e "${BOLDWHITE}
 	   _____________          __  
	  / __/_  __/ _ \___ ___ / /__
	 / _/  / / / ___/ -_) -_)  '_/
	/_/   /_/ /_/   \__/\__/_/\_\ 
    ${RESET}
"
echo -e 

if [ -z $TARGET  ] || [ $TARGET == "-h" ] || [ $TARGET == "--help" ] || [ $TARGET == "-help" ]
then
	echo "Please enter an IP OR /24 Network Address"
    echo "Please do not enter any hostname"
	echo "Usage: ./FTPeek.sh IP OR Network Address"
	echo "Examples:  "
	echo "     ./FTPeek.sh 192.168.1.2 to can that single machine only"
	echo "     ./FTPeek.sh 192.168.1.0 to scan all machines on the network"
	exit

elif [[ $TARGET =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.0$ ]]
then
    NETWORK_ADDRESS=${TARGET%.*}
    for i in {1..254} ;do (ping -c 1 $NETWORK_ADDRESS.$i | grep "bytes from" &) ; done > /tmp/check_alive_FTPeek.txt
    echo "Alive Machines in the Subnet"
    for i in {1..254} 
    do
        if grep -q "$NETWORK_ADDRESS.$i" /tmp/check_alive_FTPeek.txt 
        then   
            echo -ne "${BOLDWHITE}$NETWORK_ADDRESS.$i${RESET} "
        fi
    done
    echo

    for i in {1..254} 
    do
        if grep -q "$NETWORK_ADDRESS.$i" /tmp/check_alive_FTPeek.txt 
        then   
            ./FTPeek_Single_Target.sh $NETWORK_ADDRESS.$i
        fi
    done
    rm /tmp/check_alive_FTPeek.txt

elif [[ $TARGET =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
    echo "Single Target"
    ./FTPeek_Single_Target.sh $TARGET

else
    echo "Please enter a valid IP Address"
fi

print_line
echo "Done with peeking. Thank You for using FTPeek!"
