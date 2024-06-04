#!/bin/bash

#REMOTE_SERVER_IP=
#rsync -avz --progress /home/temp_transfer/ root@$REMOTE_SERVER_IP:/home/temp_transfer/

read -p "Please enter the full path of the backup directory (e.g., /home/temp_transfer/full_2023-12-27-05-00): " input
BACKUP_DIR=$(echo $input | xargs)

docker rm -f mysql
apt-get update && apt-get install -y wget curl sudo lsb-release && wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb && sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb && sudo percona-release setup ps80 && sudo apt-get update && sudo apt-get install -y percona-xtrabackup-80

xtrabackup --prepare --target-dir=$BACKUP_DIR
rm -rf /var/lib/docker/volumes/mysql_data/_data/*
rm -rf /data/mysql_data/*

#Copy files To Real Path, Not Docker Volume Path
#xtrabackup --copy-back --target-dir=$BACKUP_DIR --datadir=/var/lib/docker/volumes/mysql_data/_data

echo "Please enter the full path of the mysql_data directory (e.g., /data/mysql_data):"
read input
DATA_DIR=$(echo $input | xargs)
xtrabackup --copy-back --target-dir=$BACKUP_DIR --datadir=$DATA_DIR


