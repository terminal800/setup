#!/bin/bash

# Ensure the script is run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo privileges." 
   exit 1
fi

# Set root user password
echo "Setting root user password"
passwd root

# Modify SSH configuration to allow root login and enable password authentication
echo "Modifying /etc/ssh/sshd_config to allow root login and enable password authentication"
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service to apply changes
echo "Restarting SSH service"
systemctl restart ssh

echo "Operation completed. You can now log in as root using SSH with a password."

exit 0
