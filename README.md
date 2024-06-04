# Docker Install (Docker Compose & JDK)
```
rm -rf setup && apt update && apt install -y git wget sudo \
&& cd /root && git clone https://github.com/terminal800/setup.git \
&& cd /root/setup/docker/ && chmod +x ./install.sh && ./install.sh && apt autoremove -y \
&& history -c
```

# Glider SOCKS5
```
apt update && apt install -y git wget sudo
wget https://raw.githubusercontent.com/terminal800/setup/master/glider/install_glider.sh
sudo chmod +x install_glider.sh && sudo ./install_glider.sh
```



# Docker MySQL Backup(IN HOST)
```
wget https://raw.githubusercontent.com/terminal800/setup/master/mysql/backup.sh
sudo chmod +x backup.sh && sudo ./backup.sh
```
```
wget https://raw.githubusercontent.com/terminal800/setup/master/mysql/restore.sh
sudo chmod +x restore.sh && sudo ./restore.sh
```
