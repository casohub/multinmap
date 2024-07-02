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

# Function to scan for open ports and run SSH and FTP scripts if ports 22 or 21 are open
scan_and_run_scripts() {
    local ip=$1
    local ports=$2

    echo "Scanning $ip on ports $ports with -Pn and -n"
    # Perform the initial scan with -Pn and -n
    scan_result=$(nmap -Pn -n -p "$ports" "$ip")
    echo "$scan_result"

    # Check if port 22 is open
    if echo "$scan_result" | grep -q '22/tcp[[:space:]]\+open'; then
        echo "Port 22 is open on $ip. Running SSH scripts..."
        if $brute_force; then
            echo "Including ssh-brute in the scan..."
            nmap -Pn -n --script "ssh-*" -p 22 "$ip"
        else
            echo "Excluding ssh-brute from the scan..."
            all_ssh_scripts=$(ls /usr/share/nmap/scripts/ssh-* | grep -v 'ssh-brute' | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
            nmap -Pn -n --script "$all_ssh_scripts" -p 22 "$ip"
        fi
    else
        echo "Port 22 is not open on $ip."
    fi

    # Check if port 21 is open
    if echo "$scan_result" | grep -q '21/tcp[[:space:]]\+open'; then
        echo "Port 21 is open on $ip. Running FTP scripts..."
        all_ftp_scripts=$(ls /usr/share/nmap/scripts/ftp-* | xargs -n1 basename | sed 's/.nse//' | tr '\n' ',' | sed 's/,$//')
        nmap -Pn -n --script "$all_ftp_scripts" -p 21 "$ip"
    else
        echo "Port 21 is not open on $ip."
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
