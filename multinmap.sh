#!/bin/bash

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

# Function to scan for open ports and run SSH, FTP, and SMB/Samba scripts if ports 22, 21, 445, 139, or 137 (UDP) are open
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
