#!/usr/bin/env bash
# ensures home directories are private
set -eu

echo '>> Setting homedir permissions...'
sudo chmod 750 /home/*
sudo sed -i 's/DIR_MODE=0755/DIR_MODE=0750/' /etc/adduser.conf
echo "HOME_MODE 0750" | sudo tee -a /etc/login.defs
