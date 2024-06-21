#!/bin/bash

print_red() {
  local text="$1"
  echo -e "\033[31m${text}\033[0m"
}

print_green() {
  local text="$1"
  echo -e "\033[32m${text}\033[0m"
}

disable_swap() {
  print_red "Swap is enabled, disabling..."

  grep -q "vm.swappiness = 0" /etc/sysctl.conf || echo "vm.swappiness = 0" >> /etc/sysctl.conf
  swapoff -a && swapon -a
  sysctl -p
  print_green "Swap has been disabled and permanently turned off"
}

check_and_disable_swap() {
  if grep -q "vm.swappiness = 0" /etc/sysctl.conf; then
    print_green "vm.swappiness is already set to 0"
  else
    disable_swap
  fi

  ulimit_value=$(ulimit -n)
  print_green "Current ulimit -n value is ${ulimit_value}"

  if [ "$ulimit_value" -lt 1000000 ]; then
    print_red "ulimit -n less than 1000000, stopping script execution."
    exit 1
  fi
}

set_ulimit_max_permanently() {
  local ulimit_file="/etc/security/limits.d/ulimit.conf"

  if [ -f "$ulimit_file" ]; then
    local soft_limit=$(grep -m1 "soft nofile" $ulimit_file | awk '{ print $4 }')
    print_green "File $ulimit_file already exists, no modifications made. Current soft ulimit value is $soft_limit"
  else
    echo "root soft nofile 1048576" | sudo tee -a $ulimit_file
    echo "root hard nofile 1048576" | sudo tee -a $ulimit_file

    print_green "ulimit has been successfully set and stored in $ulimit_file"
  fi
}

set_ulimit_max_permanently
check_and_disable_swap


Ajust_Network() {
  echo "⏳ Adjusting host network buffer sizes..."
  sudo sysctl -w net.core.rmem_max=600000000
  sudo sysctl -w net.core.wmem_max=600000000
  
  if ! grep -q "^net.core.rmem_max=600000000$" /etc/sysctl.conf; then
    echo "net.core.rmem_max=600000000" | sudo tee -a /etc/sysctl.conf
  fi
  if ! grep -q "^net.core.wmem_max=600000000$" /etc/sysctl.conf; then
    echo "net.core.wmem_max=600000000" | sudo tee -a /etc/sysctl.conf
  fi
}

Install_JDK_DEBIAN() {
  wget https://cdn.azul.com/zulu/bin/zulu21.30.15-ca-jdk21.0.1-linux_x64.tar.gz
  mkdir -p /usr/java && tar -xzvf zulu21.30.15-ca-jdk21.0.1-linux_x64.tar.gz --strip-components 1 -C /usr/java
}

Install_Docker_Debian() {
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh ./get-docker.sh
}

Install_Docker_Compose_Debian() {
  COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || {
    echo "Unable to get the latest version of Docker Compose. Please install manually."
    return 1
  }

  sudo curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&
    sudo chmod +x /usr/local/bin/docker-compose || {
    echo "Docker Compose installation failed. Please install manually."
    return 1
  }

  docker-compose --version || {
    echo "Docker Compose installation verification failed. Please check manually."
    return 1
  }

  echo "Docker Compose $COMPOSE_VERSION installed successfully."
}

if [ ! -e "/usr/bin/docker" ]; then
  Install_Docker_Debian
fi

Ajust_Network

Install_Docker_Compose_Debian

sudo systemctl start docker
sudo systemctl enable docker

source ~/.bashrc
docker run hello-world
