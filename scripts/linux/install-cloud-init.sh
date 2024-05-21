#!/bin/bash -eu
if which dnf &>/dev/null; then
  echo '>> Installing cloud-init...'
  sudo dnf -y install cloud-init
else
  echo '>> Installing cloud-init...'
  sudo yum -y install cloud-init
fi
