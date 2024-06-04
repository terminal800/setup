#!/bin/bash

#volume:[mysql_backup:/home/backup]
BACKUP_BASE_DIR=/home/backup/mysql
BACKUP_PREFIX="full_"

CONFIG_FILE="/tmp/backup_config.txt"


get_latest_full_backup() {
    local latest_backup=$(ls -1d $BACKUP_BASE_DIR/${BACKUP_PREFIX}* 2>/dev/null | sort -r | head -n 1)
    if [ -n "$latest_backup" ]; then
        echo "$latest_backup"
    else
        return 1
    fi
}

setup_database_password() {
    if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
        if [ -n "$DATABASE_PASSWORD" ]; then
            echo "Current DATABASE_PASSWORD: $DATABASE_PASSWORD"
            echo "Do you want to use the current password? (y/n)"
            read USE_CURRENT_PW_CHOICE
            USE_CURRENT_PW_CHOICE=$(echo $USE_CURRENT_PW_CHOICE | xargs)

            if [ "$USE_CURRENT_PW_CHOICE" != "y" ]; then
                echo "Enter new DATABASE_PASSWORD:"
                read -s DATABASE_PASSWORD
                DATABASE_PASSWORD=$(echo $DATABASE_PASSWORD | xargs)
                echo "DATABASE_PASSWORD=$DATABASE_PASSWORD" > $CONFIG_FILE
            fi
        else
            echo "Enter DATABASE_PASSWORD:"
            read -s DATABASE_PASSWORD
            DATABASE_PASSWORD=$(echo $DATABASE_PASSWORD | xargs)
            echo "DATABASE_PASSWORD=$DATABASE_PASSWORD" > $CONFIG_FILE
        fi
    else
        echo "Enter DATABASE_PASSWORD:"
        read -s DATABASE_PASSWORD
        DATABASE_PASSWORD=$(echo $DATABASE_PASSWORD | xargs)
        echo "DATABASE_PASSWORD=$DATABASE_PASSWORD" > $CONFIG_FILE
    fi
}

setup_database_password

echo "Do you want to perform a mini backup? (y/n): "
read MINI_BACKUP_CHOICE
MINI_BACKUP_CHOICE=$(echo $MINI_BACKUP_CHOICE | xargs)

if [ "$MINI_BACKUP_CHOICE" = "y" ]; then
    BACKUP_PREFIX="mini_"
fi

CURRENT_DATETIME=$(date +"%Y-%m-%d-%H-%M")

BACKUP_DIR="${BACKUP_PREFIX}${CURRENT_DATETIME}"


mkdir -p $BACKUP_BASE_DIR/$BACKUP_DIR

XTRABACKUP_CMD="xtrabackup --backup --user=root --password=$DATABASE_PASSWORD --target-dir=$BACKUP_BASE_DIR/$BACKUP_DIR"


if [ "$MINI_BACKUP_CHOICE" = "y" ]; then
    XTRABACKUP_CMD+=" --tables-exclude='command_control.data_ebay_search2|command_control.logs_command_control_request_log|command_control.data_ebay_product'"
else
    XTRABACKUP_CMD+=" --tables-exclude='command_control.data_ebay_search2|command_control.logs_command_control_request_log'"
fi

echo "DOCKER INNER - Final XTRABACKUP_CMD - $XTRABACKUP_CMD"

read -p "Are you sure you want to proceed with the backup? (y/n): " CONFIRM_BACKUP
CONFIRM_BACKUP=$(echo $CONFIRM_BACKUP | xargs)

if [ "$CONFIRM_BACKUP" = "y" ]; then
    docker exec -it mysql bash -c "mkdir -p $BACKUP_BASE_DIR"
    docker exec -it mysql bash -c "apt-get update && apt-get install -y wget curl sudo lsb-release && wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb && sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb && sudo percona-release setup ps80 && sudo apt-get update && sudo apt-get install -y percona-xtrabackup-80"
    docker exec -it mysql bash -c "$XTRABACKUP_CMD"
    docker exec -it mysql bash -c "ls -al $BACKUP_BASE_DIR/$BACKUP_DIR"

    docker exec -it mysql bash -c "echo 'Docker Inner Backup Directory: $BACKUP_BASE_DIR/$BACKUP_DIR'"

else
    echo "Backup aborted."
    exit 1
fi
