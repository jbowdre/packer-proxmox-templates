#!/bin/bash -eu
if [ -f /etc/cloud/cloud.cfg.d/99-installer.cfg ]; then 
  sudo rm /etc/cloud/cloud.cfg.d/99-installer.cfg
  echo 'Deleting subiquity cloud-init config'
fi

if [ -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg ]; then 
  sudo rm /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
  echo 'Deleting subiquity cloud-init network config'
fi
