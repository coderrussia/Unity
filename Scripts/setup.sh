#!/usr/bin/env bash

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root" >&2
  exit 1
fi

echo

# Update and upgrade system
apt-get update
apt-get upgrade -y

# Installing ranger (fixed typo)
apt-get install -y ranger

# Installing sudo if not already installed
apt-get install -y sudo

# Username request
read -p "Enter new user name: " NEW_USER

# Check if user exists
if id "$NEW_USER" &>/dev/null; then
  echo "User $NEW_USER already exists"
else
  # Create user with home directory and bash shell
  useradd -m -s /bin/bash "$NEW_USER"

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

  # Set password for the user
  echo "$NEW_USER:$PASSWORD" | chpasswd

  # Add user to sudo group
  usermod -aG sudo "$NEW_USER"

  echo "User $NEW_USER created and added to sudo group."
  echo "System is ready."

  # Autologin
  #mkdir -p /etc/systemd/system/getty@tty1.service.d/
  #cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
  #[Service]
  #ExecStart=
  #ExecStart=-/sbin/agetty --noclear --autologin $NEW_USER %I \$TERM
  #EOF

  # services reboot
  #systemctl daemon-reload

  #echo "Autologin setup completed"
fi
