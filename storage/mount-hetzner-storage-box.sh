#!/bin/bash

# ANSI color codes
GREEN="\033[0;32m"
BOLD_GREEN="\033[1;32m"
RED="\033[0;31m"
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

# Function to check if remote directory exists
check_remote_directory() {
  local username=$1
  local host=$2
  local remote_dir=$3
  local password=$4

  echo "$password" | ssh -p 23 -o StrictHostKeyChecking=no "$username@$host" "if [ -d $remote_dir ]; then echo 'exists'; else echo 'not found'; fi"
}

# Function to create remote directory
create_remote_directory() {
  local username=$1
  local host=$2
  local remote_dir=$3
  local password=$4

  echo "$password" | ssh -p 23 -o StrictHostKeyChecking=no "$username@$host" "mkdir -p $remote_dir" 2>&1
}

# Ensure sshfs is installed
if ! command -v sshfs &>/dev/null; then
  echo -e "${BOLD_GREEN}Installing sshfs...${RESET}"
  sudo apt-get update
  sudo apt-get install -y sshfs
fi

# Check if there are existing SSHFS mounts
EXISTING_MOUNTS=$(mount | grep sshfs)
if [ -n "$EXISTING_MOUNTS" ]; then
  echo -e "${BOLD_GREEN}Existing SSHFS mounts found:${RESET}"
  echo "***{Existing Mounts}**************************************"
  echo "$EXISTING_MOUNTS"
  echo "*********************************************"
  while true; do
    read -r -p "$(echo -e "${BOLD_GREEN}Do you want to continue? (y/n)${RESET}: ")" CONTINUE
    if [[ "$CONTINUE" == "y" || "$CONTINUE" == "n" ]]; then
      break
    else
      echo -e "${RED}Please enter 'y' or 'n'.${RESET}"
    fi
  done

  if [ "$CONTINUE" != "y" ]; then
    echo -e "${BOLD_GREEN}Aborted by user.${RESET}"
    exit 0
  fi
else
  CONTINUE="y"
fi

if [ "$CONTINUE" == "y" ]; then
  # Collect user inputs
  while true; do
    USERNAME=$(ask "Enter your Storage Box username" "uXXXXXX")
    if validate_username "$USERNAME"; then
      break
    else
      echo -e "${RED}Invalid username format.${RESET} The username must start with 'u' followed by 6 to 7 digits."
    fi
  done

  while true; do
    PASSWORD=$(ask "Enter your Storage Box password" "")
    PASSWORD=$(echo "$PASSWORD" | xargs)
    if [ -n "$PASSWORD" ]; then
      break
    else
      echo -e "${RED}Password cannot be empty.${RESET} Please enter a valid password."
    fi
  done

  # Get the current server's hostname
  SERVER_HOSTNAME=$(hostname)

  # Set the default local mount directory
  DEFAULT_LOCAL_MOUNT_DIR="/home/storage"

  # Set the default remote directory
  DEFAULT_REMOTE_DIR="/$USERNAME/$SERVER_HOSTNAME"

  # Ask for the local mount directory with the default value
  LOCAL_MOUNT_DIR=$(ask "Enter the local directory to mount the Storage Box" "$DEFAULT_LOCAL_MOUNT_DIR")

  # Ask for the remote directory with the default value
  REMOTE_DIR=$(ask "Enter the remote directory on the Storage Box" "$DEFAULT_REMOTE_DIR")
  STORAGEBOX_HOST="${USERNAME}.your-storagebox.de"

  # Check remote directory and create if not exists
  REMOTE_DIR_CHECK=$(echo "$PASSWORD" | ssh -p 23 -o StrictHostKeyChecking=no "$USERNAME@$STORAGEBOX_HOST" "if [ -d $REMOTE_DIR ]; then echo 'exists'; else echo 'not found'; fi")
  if [[ "$REMOTE_DIR_CHECK" == "not found" ]]; then
    CREATE_OUTPUT=$(echo "$PASSWORD" | ssh -p 23 -o StrictHostKeyChecking=no "$USERNAME@$STORAGEBOX_HOST" "mkdir -p $REMOTE_DIR" 2>&1)
    REMOTE_DIR_CHECK=$(echo "$PASSWORD" | ssh -p 23 -o StrictHostKeyChecking=no "$USERNAME@$STORAGEBOX_HOST" "if [ -d $REMOTE_DIR ]; then echo 'exists'; else echo 'not found'; fi")
    if [[ "$REMOTE_DIR_CHECK" == "exists" ]]; then
      echo -e "${BOLD_GREEN}Remote directory created successfully.${RESET}"
    else
      echo -e "${RED}Failed to create remote directory. Error details:${RESET}"
      echo "$CREATE_OUTPUT"
    fi
  else
    echo -e "${BOLD_GREEN}Remote directory exists.${RESET}"
  fi

  # Confirm the information with the user
  while true; do
    echo ""
    echo -e "${BOLD_GREEN}Please confirm the following information:${RESET}"
    echo -e "${BOLD_GREEN}Storage Box username:${RESET} $USERNAME"
    echo -e "${BOLD_GREEN}Storage Box password:${RESET} $PASSWORD"
    echo -e "${BOLD_GREEN}Storage Box host:${RESET} $STORAGEBOX_HOST"
    echo -e "${BOLD_GREEN}Local mount directory:${RESET} $LOCAL_MOUNT_DIR"
    echo -e "${BOLD_GREEN}Remote directory:${RESET} $REMOTE_DIR"
    echo ""

    read -r -p "$(echo -e "${BOLD_GREEN}Is this information correct? (y/n)${RESET}: ")" CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "n" ]]; then
      break
    else
      echo -e "${RED}Please enter 'y' or 'n'.${RESET}"
    fi
  done

  if [ "$CONFIRM" == "y" ]; then

    # Ensure the local mount directory exists
    mkdir -p "$LOCAL_MOUNT_DIR"

    # Check if the mount point already exists
    MOUNT_EXISTS=$(mount | grep "$LOCAL_MOUNT_DIR")

    if [ -z "$MOUNT_EXISTS" ]; then
      # Mount the Storage Box using SSHFS with provided command line format
      echo -e "${BOLD_GREEN}Mounting Storage Box...${RESET}"
      echo "$PASSWORD" | sshfs "$USERNAME@$STORAGEBOX_HOST:$REMOTE_DIR" "$LOCAL_MOUNT_DIR" -o password_stdin -o StrictHostKeyChecking=no

      if mountpoint -q "$LOCAL_MOUNT_DIR"; then
        echo -e "${BOLD_GREEN}Storage Box has been mounted successfully to $LOCAL_MOUNT_DIR.${RESET}"

        # Display SSHFS mounts
        echo "***{New Created}**************************************"
        mount | grep sshfs
        echo "*********************************************"
      else
        echo -e "${RED}Failed to mount Storage Box.${RESET}"
      fi
    else
      echo -e "${BOLD_GREEN}Storage Box already mounted at $LOCAL_MOUNT_DIR.${RESET}"
      echo "***{Already Exist}**************************************"
      mount | grep sshfs
      echo "*********************************************"
    fi

    echo -e "${BOLD_GREEN}Setup completed.${RESET}"

    # Wait for user input to exit
    read -r -p "Press Enter to exit the script."
  else
    echo -e "${BOLD_GREEN}Aborted by user.${RESET}"
  fi
fi
