#!/usr/bin/env bash

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root" >&2
  exit 1
fi

#OS check
if command -v lsb_release >/dev/null 2>&1; then
  distro=$(lsb_release -d | cut -f2-)
elif [ -f /etc/os-release ]; then
  distro=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
elif ls /etc/*-release >/dev/null 2>&1; then
  distro=$(head -n1 /etc/*-release)
else
  distro="unknown"
fi



if [ -z "$distro" ]; then
  distro="unknown"
fi

#Kernel check
Kernel=$(uname -r)

#Hardware check
virt_type=$(systemd-detect-virt)

if [ "$virt_type" = "none" ]; then
  hardware="hardware"
else
  hardware="$virt_type"
fi

#NTP-check

ntp=$(if systemctl is-active --quiet ntp.service; then
  echo "ntpd"
elif systemctl is-active --quiet chronyd.service; then
  echo "chrony"
elif systemctl is-active --quiet systemd-timesyncd.service; then
  echo "systemd-timesyncd"
else
  echo "none"
fi)

#clar terminal
clear

#info
cat << "EOF"

  _    ___      ___   _                 _               
 | |  | \ \    / / \ | |               | |              
 | |  | |\ \  / /|  \| |______ ___  ___| |_ _   _ _ __  
 | |  | | \ \/ / | . ` |______/ __|/ _ \ __| | | | '_ \ 
 | |__| |  \  /  | |\  |      \__ \  __/ |_| |_| | |_) |
  \____/    \/   |_| \_|      |___/\___|\__|\__,_| .__/ 
                                                 | |    
                                                 |_|    

EOF

#Answer questions
#New user
# Username request
read -p "Enter new user name: " NEW_USER

#Password request

# Password input with confirmation
  while true; do
    read -s -p "Enter password for $NEW_USER: " PASSWORD
    echo
    read -s -p "Confirm password: " PASSWORD_CONFIRM
    echo
    if [ "$PASSWORD" == "$PASSWORD_CONFIRM" ]; then
      break
    else
      echo "Passwords do not match. Please try again."
    fi
  done

#Wazuh
read -p "Enter Wazuh-server adress: " Wazuh_srv_adr


echo "Distro: $distro"

echo "Kernel: $Kernel"

echo "hardware: $hardware"

echo "ntp: $ntp"

echo "Wazuh-server adress: $Wazuh_srv_adr"

echo "Username for new user: $NEW_USER"
#Script confirmation 
read -p "Are you want to continue ? [y/N]: " answer

case "$answer" in
  [Yy]* )
    ;;  
  [Nn]* )  
    echo "script canceled"
    exit 1
    ;;
  * )
    echo "[Y/N]"
    exit 1
    ;;
esac


# Update and upgrade system
apt-get update
apt-get upgrade -y



#installing software
apt-get install sudo -y
apt-get install curl -y
apt-get install git -y
apt-get install wget -y
apt-get install gnupg2 -y

#wazuh
#adding repositories
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt-get update

#installing wazuh-agent
WAZUH_MANAGER="$Wazuh_srv_adr" apt-get install wazuh-agent

#Creating new user
# Check if user exists
if id "$NEW_USER" &>/dev/null; then
  echo "User $NEW_USER already exists"
else
  # Create user with home directory and bash shell
  useradd -m -s /bin/bash "$NEW_USER"

# Set password for the user
  echo "$NEW_USER:$PASSWORD" | chpasswd

  # Add user to sudo group
  usermod -aG sudo "$NEW_USER"
fi 