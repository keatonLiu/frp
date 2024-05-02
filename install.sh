#!/bin/sh

ghproxy="https://gh-proxy.com/"

# If argument is not provided, then exit
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# check uid
if [ $(id -u) -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# If argument is frpc or frps
if [ $1 = "frpc" ] || [ $1 = "frps" ]; then
    apt update && apt install -y wget
    # Get latest release of frp
    latest_release=$(get_latest_release "fatedier/frp")
    # Remove leading "v" from version
    latest_release=$(printf "%s" "$latest_release" | sed 's/v//')
    # Download frp from GitHub
    wget -O - "${ghproxy}https://github.com/fatedier/frp/releases/download/v${latest_release}/frp_${latest_release}_linux_amd64.tar.gz" | tar -xz
    # Rename frp directory
    mv "frp_${latest_release}_linux_amd64" "frp"
    # Move frp to /usr/local/
    mv frp /usr/local/
else 
    echo "Invalid argument"
    exit 1
fi

# If argument is frpc
if [ $1 = "frpc" ]; then
    name="frpc"
else 
    name="frps"
fi

# Install service
wget "${ghproxy}https://raw.githubusercontent.com/keatonLiu/frp/master/${name}/${name}.service" -O /etc/systemd/system/${name}.service
# Reload systemd
systemctl daemon-reload
# Enable frp service
systemctl enable ${name}

echo "Installed ${name} successfully"
echo "Set up ${name} configuration in /usr/local/frp/${name}.toml"
echo "Start ${name} service using 'sudo systemctl start ${name}'"