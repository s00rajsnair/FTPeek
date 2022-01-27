# FTPeek
This tool can be used for enumerating common vulnerabilities and misconfigurations on FTP servers.

Key features : 
  1. Knocking the FTP Port
  2. Grabbing the FTP Banner
  3. Checking for Anonymous Authentication
  4. Bruteforcing Common Credentials
  5. Viewing the server content including all the hidden files/directories
  6. Checking if file upload permission is enabled for the currrently logged in user

FTPeek is a bash program, designed especially for CTF Players and Penetration Testers, to make their life easy by making the process of peeking to the FTP services on their target machines quick and hassle-free.

This tool can scan a single machine's FTP service, as well as sweep an entire network, and then scan the machines on which FTP service is open.

### Usage

For this tool to work properly, you need to install the latest version of `nmap`, `wget` and `tree` on your machine.\
Give `sudo apt install nmap wget tree`

Now enter the following commands on the terminal : 

```
git clone https://github.com/s00rajsnair/FTPeek
cd FTPeek
```

Now, enter `./FTPeek.sh <Target IP Address>`  OR  `./FTPeek.sh <Subnet Address>`\

Examples : \
`./FTPeek.sh 192.168.1.8` will scan only the machine 192.168.1.8\
While `./FTPeek.sh 192.168.1.0` will scan all machines in the 192.168.1.0/24 network i.e, from 192.168.1.1 to 192.168.1.254
