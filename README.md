# Docker Install (Docker Compose & JDK)
```
rm -rf /root/setup/ && apt update && apt install -y git wget sudo \
&& cd /root && git clone https://github.com/terminal800/setup.git \
&& cd /root/setup/docker/ && chmod +x ./install.sh && ./install.sh && apt autoremove -y \
&& rm -rf /root/setup/ && cd /root && history -c
```

# Glider SOCKS5
```
apt update && apt install -y git wget sudo
wget https://raw.githubusercontent.com/terminal800/setup/master/glider/install_glider.sh
sudo chmod +x install_glider.sh && sudo ./install_glider.sh
rm -rf install_glider.sh && history -c
```


# Mount Hetzner StorageBox
```
wget https://raw.githubusercontent.com/terminal800/setup/master/storage/mount-hetzner-storage-box.sh
sudo chmod +x mount-hetzner-storage-box.sh && sudo ./mount-hetzner-storage-box.sh
rm -rf mount-hetzner-storage-box.sh && history -c
```



# Docker MySQL Backup(IN HOST)
```
wget https://raw.githubusercontent.com/terminal800/setup/master/mysql/backup.sh
sudo chmod +x backup.sh && sudo ./backup.sh
rm -rf backup.sh && history -c
```
```
wget https://raw.githubusercontent.com/terminal800/setup/master/mysql/restore.sh
sudo chmod +x restore.sh && sudo ./restore.sh
rm -rf restore.sh && history -c
```



# Enable ROOT Login
```
wget https://raw.githubusercontent.com/terminal800/setup/master/server/enable_root_login.sh
sudo chmod +x enable_root_login.sh && sudo ./enable_root_login.sh
rm -rf enable_root_login.sh && history -c
```


```
wget https://raw.githubusercontent.com/terminal800/setup/master/server/enable_root_login.sh
sudo chmod +x enable_root_login.sh && sudo ./enable_root_login.sh PASSWORD
rm -rf enable_root_login.sh && history -c
```

