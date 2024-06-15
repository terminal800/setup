#!/bin/bash

# Ensure the script is run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo privileges." 
   exit 1
fi

# Function to trim whitespace
trim() {
    echo "$1" | xargs
}

# Prompt for root user password and store it in a variable
while true; do
    read -p "Enter the new root user password (at least 10 characters): " root_password
    root_password=$(trim "$root_password")
    if [[ ${#root_password} -ge 10 ]]; then
        echo "You entered: $root_password"
        read -p "Do you want to proceed with this password? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            break
        elif [[ "$confirm" == "n" ]]; then
            echo "Please enter the password again."
        else
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    else
        echo "Password must be at least 10 characters long. Please try again."
    fi
done

if [[ "$confirm" == "y" ]]; then
    # Set root user password
    echo "Setting root user password"
    echo "root:$root_password" | chpasswd

    # Modify SSH configuration to allow root login and enable password authentication
    echo "Modifying /etc/ssh/sshd_config to allow root login and enable password authentication"
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    echo "Restarting SSH service"
    systemctl restart ssh

    echo "Operation completed. You can now log in as root using SSH with the new password."
fi
