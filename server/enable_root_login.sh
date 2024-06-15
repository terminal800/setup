#!/bin/bash

# Ensure the script is run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "$(red "This script must be run as root or with sudo privileges.")"
   exit 1
fi

# Function to trim whitespace
trim() {
    echo "$1" | xargs
}

# Function to apply ANSI colors
red() {
    echo -e "\e[31m$1\e[0m"
}

green() {
    echo -e "\e[32m$1\e[0m"
}

blue() {
    echo -e "\e[34m$1\e[0m"
}

# Check if a password was provided as an argument
if [[ -n "$1" ]]; then
    root_password=$(trim "$1")
    if [[ ${#root_password} -ge 10 ]]; then
        echo -e "Using provided password: $(green "$root_password")"
        confirm="y"
    else
        echo "$(red "Provided password must be at least 10 characters long.")"
    fi
else
    # Prompt for root user password and store it in a variable
    while true; do
        read -p "$(blue "Enter the new root user password (at least 10 characters): ")" root_password
        root_password=$(trim "$root_password")
        if [[ ${#root_password} -ge 10 ]]; then
            echo -e "You entered: $(green "$root_password")"
            while true; do
                read -p "$(blue "Do you want to proceed with this password? (Y/n): ")" confirm
                confirm=$(trim "$confirm")
                if [[ -z "$confirm" || "$confirm" == "y" ]]; then
                    confirm="y"
                    break 2
                elif [[ "$confirm" == "n" ]]; then
                    echo "$(blue "Please enter the password again.")"
                    break
                else
                    echo "$(red "Invalid input. Please enter 'y' or 'n'.")"
                fi
            done
        else
            echo "$(red "Password must be at least 10 characters long. Please try again.")"
        fi
    done
fi

if [[ "$confirm" == "y" ]]; then
    # Set root user password
    echo "Setting root user password"
    echo "root:$root_password" | chpasswd

    # Modify SSH configuration to allow root login and enable password authentication
    echo "Modifying /etc/ssh/sshd_config to allow root login and enable password authentication"
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

    # AWS EC2 Ubuntu
    sed -i 's/^#KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    echo "Restarting SSH service"
    systemctl daemon-reload
    systemctl restart ssh

    echo "$(green "Operation completed. You can now log in as root using SSH with the new password.")"

    echo "=================================================================="
    cat /etc/ssh/sshd_config | grep PasswordAuthentication
    cat /etc/ssh/sshd_config | grep PermitRootLogin
    echo "=================================================================="
fi
