#!/bin/bash

# ANSI color codes
GREEN="\033[0;32m"
BOLD_GREEN="\033[1;32m"
RESET="\033[0m"

# Function to ask user for input with a default value and trim whitespace
ask() {
  local prompt default reply

  prompt="$1"
  default="$2"

  read -e -p "$(echo -e "${BOLD_GREEN}${prompt}${RESET}: ")" -i "$default" reply

  # Trim leading and trailing whitespace
  reply=$(echo "$reply" | xargs)

  if [ -z "$reply" ]; then
    reply="$default"
  fi

  echo "$reply"
}

# Function to validate username format
validate_username() {
  local username=$1
  if [[ $username =~ ^u[0-9]{6,7}$ ]]; then
    return 0
  else
    return 1
  fi
}

# Collect user inputs
while true; do
  USERNAME=$(ask "Enter your Storage Box username" "uXXXXXX")
  if validate_username "$USERNAME"; then
    break
  else
    echo -e "${BOLD_GREEN}Invalid username format.${RESET} The username must start with 'u' followed by 6 to 7 digits."
  fi
done

# Get the current server's hostname
SERVER_HOSTNAME=$(hostname)

# Set the default local mount directory
DEFAULT_LOCAL_MOUNT_DIR="/home/storage"

# Set the default remote directory
DEFAULT_REMOTE_DIR="/home/$USERNAME/$SERVER_HOSTNAME"

# Ask for the local mount directory with the default value
LOCAL_MOUNT_DIR=$(ask "Enter the local directory to mount the Storage Box" "$DEFAULT_LOCAL_MOUNT_DIR")

# Ask for the remote directory with the default value
REMOTE_DIR=$(ask "Enter the remote directory on the Storage Box" "$DEFAULT_REMOTE_DIR")

# Automatically generate the Storage Box host based on the username
STORAGEBOX_HOST="${USERNAME}.your-storagebox.de"

# Confirm the information with the user
echo ""
echo -e "${BOLD_GREEN}Please confirm the following information:${RESET}"
echo -e "${BOLD_GREEN}Storage Box username:${RESET} $USERNAME"
echo -e "${BOLD_GREEN}Storage Box host:${RESET} $STORAGEBOX_HOST"
echo -e "${BOLD_GREEN}Local mount directory:${RESET} $LOCAL_MOUNT_DIR"
echo -e "${BOLD_GREEN}Remote directory:${RESET} $REMOTE_DIR"
echo ""

read -r -p "$(echo -e "${BOLD_GREEN}Is this information correct? (y/n)${RESET}: ")" CONFIRM

if [ "$CONFIRM" == "y" ]; then

  # Ensure the local mount directory exists
  mkdir -p "$LOCAL_MOUNT_DIR"

  # Install sshfs if not already installed
  if ! command -v sshfs &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y sshfs
  fi

  # Mount the Storage Box using SSHFS
  sshfs -o allow_other,default_permissions "$USERNAME@$STORAGEBOX_HOST:$REMOTE_DIR" "$LOCAL_MOUNT_DIR"

  echo "Storage Box has been mounted successfully to $LOCAL_MOUNT_DIR."

  # Add the mount configuration to /etc/fstab for automatic mounting on boot
  FSTAB_ENTRY="$USERNAME@$STORAGEBOX_HOST:$REMOTE_DIR $LOCAL_MOUNT_DIR fuse.sshfs defaults,_netdev,allow_other,default_permissions 0 0"

  # Check if the entry already exists in /etc/fstab
  if ! grep -q "$FSTAB_ENTRY" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
    echo "Entry added to /etc/fstab for automatic mounting on boot."
  else
    echo "Entry already exists in /etc/fstab."
  fi

  echo -e "${BOLD_GREEN}Setup completed.${RESET}"

  # Wait for user input to exit
  read -r -p "Press Enter to exit the script."
else
  echo -e "${BOLD_GREEN}Aborted by user.${RESET}"

fi
