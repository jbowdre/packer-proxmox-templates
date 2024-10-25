#!/usr/bin/env -S bash -eu
# installs cloud-init on RHEL-based systems

if which dnf &>/dev/null; then
  echo '>> Installing cloud-init...'
  sudo dnf -y install cloud-init
else
  echo '>> Installing cloud-init...'
  sudo yum -y install cloud-init
fi
