#!/bin/bash

# Function to print ASCII art
print_ascii_art() {
    cat << "EOF"
 __    __     __  __     __         ______   __     __   __     __    __     ______     ______  
/\ "-./  \   /\ \/\ \   /\ \       /\__  _\ /\ \   /\ "-.\ \   /\ "-./  \   /\  __ \   /\  == \ 
\ \ \-./\ \  \ \ \_\ \  \ \ \____  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \-./\ \  \ \  __ \  \ \  _-/ 
 \ \_\ \ \_\  \ \_____\  \ \_____\    \ \_\  \ \_\  \ \_\\"\_\  \ \_\ \ \_\  \ \_\ \_\  \ \_\   
  \/_/  \/_/   \/_____/   \/_____/     \/_/   \/_/   \/_/ \/_/   \/_/  \/_/   \/_/\/_/   \/_/   
EOF
    printf "\033[31m%80s\033[0m\n" "written by Tommaso Casoni"
}

# Function to print usage
usage() {
    echo "Usage: $0 -t|--target path_to_ip_port_list.txt [-b|--brute-force]"
    exit 1
}

# Initialize variables
input_file=""
brute_force=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--target)
            input_file=$2
            shift
            ;;
        --brute-force|-b)
            brute_force=true
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Check if the input file was provided
if [ -z "${input_file}" ]; then
    usage
fi

# Function to scan for open ports and run appropriate scripts if specific ports are open
scan_and_run_scripts() {
    local ip=$1
    local ports=$2
    local smb_open=false

    echo "Scanning $ip on ports $ports with -Pn and -n"
    # Perform the initial scan with -Pn and -n
    scan_result=$(timeout 300 nmap -Pn -n -p "$ports" "$ip")
    echo "$scan_result"

    # Check if port 22 is open
    if echo "$scan_result" | grep -q '22/tcp[[:space:]]\+open'; then
        echo "Port 22 is open on $ip. Running SSH scripts..."
        if $brute_force; then
            echo "Including ssh-brute in the scan..."
            timeout 300 nmap -Pn -n --script "ssh-*" -p 22 "$ip"
        else
            echo "Excluding ssh-brute from the scan..."
            all_ssh_scripts=$(ls /usr/share/nmap/scripts/ssh-* | grep -v 'ssh-brute' | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
            timeout 300 nmap -Pn -n --script "$all_ssh_scripts" -p 22 "$ip"
        fi
    else
        echo "Port 22 is not open on $ip."
    fi

    # Check if port 21 is open
    if echo "$scan_result" | grep -q '21/tcp[[:space:]]\+open'; then
        echo "Port 21 is open on $ip. Running FTP scripts..."
        if $brute_force; then
            echo "Including ftp-brute in the scan..."
            all_ftp_scripts=$(ls /usr/share/nmap/scripts/ftp-* | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
        else
            echo "Excluding ftp-brute from the scan..."
            all_ftp_scripts=$(ls /usr/share/nmap/scripts/ftp-* | grep -v 'ftp-brute' | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
        fi
        timeout 300 nmap -Pn -n --script "$all_ftp_scripts" -p 21 "$ip"
    else
        echo "Port 21 is not open on $ip."
    fi

    # Check if port 25 is open
    if echo "$scan_result" | grep -q '25/tcp[[:space:]]\+open'; then
        echo "Port 25 is open on $ip. Running SMTP scripts..."
        all_smtp_scripts="smtp-enum-users,smtp-commands,smtp-open-relay"
        timeout 300 nmap -Pn -n --script "$all_smtp_scripts" -p 25 "$ip"
    else
        echo "Port 25 is not open on $ip."
    fi

    # Check if port 53 is open
    if echo "$scan_result" | grep -q '53/tcp[[:space:]]\+open'; then
        echo "Port 53 is open on $ip. Running DNS scripts..."
        all_dns_scripts="dns-brute,dns-cache-snoop,dns-zone-transfer"
        timeout 300 nmap -Pn -n --script "$all_dns_scripts" -p 53 "$ip"
    else
        echo "Port 53 is not open on $ip."
    fi

    # Check if port 110 is open
    if echo "$scan_result" | grep -q '110/tcp[[:space:]]\+open'; then
        echo "Port 110 is open on $ip. Running POP3 scripts..."
        all_pop3_scripts="pop3-capabilities,pop3-ntlm-info"
        timeout 300 nmap -Pn -n --script "$all_pop3_scripts" -p 110 "$ip"
    else
        echo "Port 110 is not open on $ip."
    fi

    # Check if port 143 is open
    if echo "$scan_result" | grep -q '143/tcp[[:space:]]\+open'; then
        echo "Port 143 is open on $ip. Running IMAP scripts..."
        all_imap_scripts="imap-capabilities,imap-ntlm-info"
        timeout 300 nmap -Pn -n --script "$all_imap_scripts" -p 143 "$ip"
    else
        echo "Port 143 is not open on $ip."
    fi

    # Check if port 3306 is open
    if echo "$scan_result" | grep -q '3306/tcp[[:space:]]\+open'; then
        echo "Port 3306 is open on $ip. Running MySQL scripts..."
        all_mysql_scripts="mysql-enum,mysql-info,mysql-databases"
        timeout 300 nmap -Pn -n --script "$all_mysql_scripts" -p 3306 "$ip"
    else
        echo "Port 3306 is not open on $ip."
    fi

    # Check if port 3389 is open
    if echo "$scan_result" | grep -q '3389/tcp[[:space:]]\+open'; then
        echo "Port 3389 is open on $ip. Running RDP scripts..."
        all_rdp_scripts="rdp-enum-encryption,rdp-vuln-ms12-020"
        timeout 300 nmap -Pn -n --script "$all_rdp_scripts" -p 3389 "$ip"
    else
        echo "Port 3389 is not open on $ip."
    fi

    # Check if port 5900 is open
    if echo "$scan_result" | grep -q '5900/tcp[[:space:]]\+open'; then
        echo "Port 5900 is open on $ip. Running VNC scripts..."
        all_vnc_scripts="vnc-info,vnc-title"
        timeout 300 nmap -Pn -n --script "$all_vnc_scripts" -p 5900 "$ip"
    else
        echo "Port 5900 is not open on $ip."
    fi

    # Check if port 8080 is open
    if echo "$scan_result" | grep -q '8080/tcp[[:space:]]\+open'; then
        echo "Port 8080 is open on $ip. Running HTTP Proxy scripts..."
        if $brute_force; then
            echo "Including http-proxy-brute in the scan..."
            all_http_proxy_scripts="http-open-proxy,http-proxy-brute"
        else
            echo "Excluding http-proxy-brute from the scan..."
            all_http_proxy_scripts="http-open-proxy"
        fi
        timeout 300 nmap -Pn -n --script "$all_http_proxy_scripts" -p 8080 "$ip"
    else
        echo "Port 8080 is not open on $ip."
    fi

    # Check if port 445 is open
    if echo "$scan_result" | grep -q '445/tcp[[:space:]]\+open'; then
        echo "Port 445 is open on $ip."
        smb_open=true
    fi

    # Check if port 139 is open
    if echo "$scan_result" | grep -q '139/tcp[[:space:]]\+open'; then
        echo "Port 139 is open on $ip."
        smb_open=true
    fi

    # Check if port 137 (UDP) is open
    echo "Scanning $ip on port 137 UDP"
    scan_result_udp=$(sudo timeout 300 nmap -sU -p 137 "$ip")
    echo "$scan_result_udp"

    if echo "$scan_result_udp" | grep -q '137/udp[[:space:]]\+open'; then
        echo "Port 137 UDP is open on $ip."
        smb_open=true
    fi

    # Run SMB/Samba scripts if any of the SMB ports are open
    if [ "$smb_open" = true ]; then
        echo "Running SMB/Samba scripts on $ip..."
        all_smb_scripts=$(ls /usr/share/nmap/scripts/smb-* /usr/share/nmap/scripts/samba-* 2>/dev/null | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
        sudo timeout 300 nmap -sU -sS --script "$all_smb_scripts" -p U:137,T:139,445 "$ip"
    else
        echo "No SMB/Samba ports are open on $ip."
    fi
}

# Print ASCII art
print_ascii_art

# Read the input file line by line
while IFS= read -r line; do
    # Extract IP and port information
    ip=$(echo "$line" | cut -d':' -f1)
    ports=$(echo "$line" | cut -d':' -f2)

    # Check if IP and ports are not empty
    if [[ -n "$ip" && -n "$ports" ]]; then
        scan_and_run_scripts "$ip" "$ports"
    else
        echo "Invalid line: $line"
    fi
done < "$input_file"
