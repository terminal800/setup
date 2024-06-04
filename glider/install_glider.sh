#!/bin/bash
#set -x

if [ -x "$(command -v apt-get)" ]; then
    PKG_MANAGER="apt-get"
elif [ -x "$(command -v yum)" ]; then
    PKG_MANAGER="yum"
else
    echo "Neither apt-get nor yum found. Exiting."
    exit 1
fi

for cmd in jq wget curl lsof; do
    if ! [ -x "$(command -v $cmd)" ]; then
        sudo $PKG_MANAGER update -y
        sudo $PKG_MANAGER install $cmd -y
    fi
done

generate_random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1
}

GLIDER_VERSION="0.16.3"
GLIDER_DIR="glider_${GLIDER_VERSION}_linux_amd64"
GLIDER_FILE="${GLIDER_DIR}.tar.gz"
GLIDER_URL="https://github.com/nadoo/glider/releases/download/v${GLIDER_VERSION}/${GLIDER_FILE}"
CONFIG_FILE="./glider_config.json"

if ! [ -f "${CONFIG_FILE}" ]; then
    kill $(lsof -t -i:10888)
fi

if [ -f "${GLIDER_FILE}" ]; then
    rm -f ${GLIDER_FILE}
fi

if ! [ -x "$(command -v ./glider)" ]; then
  wget --header="Cache-Control: no-cache" ${GLIDER_URL} || { echo "wget failed. Exiting."; exit 1; }

  tar -xvf ${GLIDER_FILE} || { echo "tar failed. Exiting."; exit 1; }

  cd ${GLIDER_DIR} || { echo "cd failed. Exiting."; exit 1; }
fi

PUBLIC_IP=$(curl -s https://checkip.amazonaws.com) || { echo "curl failed. Exiting."; exit 1; }

if [ -f "$CONFIG_FILE" ]; then
    cat ${CONFIG_FILE} | jq || { echo "jq failed. Exiting."; exit 1; }

    if ! lsof -i :10888 > /dev/null
    then
        echo "Glider is not running. Starting..."
        PASSWORD=$(jq -r '.password' ${CONFIG_FILE})
        nohup ./glider -listen socks5://admin:${PASSWORD}@:10888 >/dev/null 2>&1 &
    fi
else
    RANDOM_STRING=$(generate_random_string)
    nohup ./glider -listen socks5://admin:${RANDOM_STRING}@:10888 >/dev/null 2>&1 &

    echo -n "{\"type\":\"socks5\",\"IP\":\"${PUBLIC_IP}\",\"port\":10888,\"username\":\"admin\",\"password\":\"${RANDOM_STRING}\"}" > ${CONFIG_FILE}

    echo "========================================================================"

    cat ${CONFIG_FILE} | jq || { echo "jq failed. Exiting."; exit 1; }

    echo "========================================================================"
fi

if lsof -i :10888 > /dev/null
then
    echo "Glider is running."
else
    echo "Glider is not running."
fi

rm -f ${GLIDER_FILE}
