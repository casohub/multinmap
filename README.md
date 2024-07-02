# MultiNmap

MultiNmap is a Bash script designed to perform comprehensive network scans on a list of IP addresses. It first performs an initial scan to identify open ports and then runs detailed protocol-specific scans on the detected open ports. The script also includes an option to perform brute force attacks on certain protocols.

## Features

- Initial scan to determine open ports on target IP addresses.
- Detailed scans for various protocols including SSH, FTP, SMTP, DNS, POP3, IMAP, MySQL, RDP, VNC, HTTP Proxy, and SMB/Samba.
- Option to include brute force attacks on SSH, FTP, and HTTP Proxy protocols.
- ASCII art banner with author credit.

## Usage

### Command Line Arguments

- `-t, --target`: Path to the input file containing a list of IP addresses.
- `-b, --brute-force`: Optional flag to include brute force attacks on SSH, FTP, and HTTP Proxy protocols.

### Example Usage

To run the script without brute force attacks:
```sh
./multi_nmap.sh -t path_to_ip_list.txt

To run the script with brute force attacks:

./multi_nmap.sh -t path_to_ip_list.txt -b

Input File Format
The input file should contain one IP address per line. Example:

192.168.0.1
192.168.0.2
192.168.0.3

##Detailed Protocol Scans
The script runs detailed scans based on open ports detected in the initial scan. The following sections describe the scripts used for each protocol.

###SSH
Port: 22
Scripts:
ssh-auth-methods
ssh-brute (only if -b flag is set)
ssh-hostkey
ssh-publickey-acceptance

###FTP
Port: 21
Scripts:
ftp-anon
ftp-bounce
ftp-brute (only if -b flag is set)
ftp-proftpd-backdoor
ftp-vsftpd-backdoor

###SMTP
Port: 25
Scripts:
smtp-enum-users
smtp-commands
smtp-open-relay

###DNS
Port: 53
Scripts:
dns-brute
dns-cache-snoop
dns-zone-transfer

###POP3
Port: 110
Scripts:
pop3-capabilities
pop3-ntlm-info

###IMAP
Port: 143
Scripts:
imap-capabilities
imap-ntlm-info

###MySQL
Port: 3306
Scripts:
mysql-enum
mysql-info
mysql-databases

###RDP
Port: 3389
Scripts:
rdp-enum-encryption
rdp-vuln-ms12-020

###VNC
Port: 5900
Scripts:
vnc-info
vnc-title

###HTTP Proxy
Port: 8080
Scripts:
http-open-proxy
http-proxy-brute (only if -b flag is set)

###SMB/Samba
Ports: 137 (UDP), 139, 445
Scripts:
smb-enum-shares
smb-enum-users
smb-os-discovery
smb-protocols
smb-security-mode
smb-vuln-cve-2017-7494
samba-vuln-cve-2012-1182

##Author
MultiNmap was created by Tommaso Casoni.

##License
This script is licensed under the MIT License.
