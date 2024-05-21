#!/bin/bash -eu
if awk -F= '/^ID/{print $2}' /etc/os-release | grep -q debian; then
  echo '>> Cleaning up unneeded packages...'
  sudo apt-get -y autoremove --purge
  sudo apt-get -y clean
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q rhel; then
  if which dnf &>/dev/null; then
    echo '>> Cleaning up unneeded packages...'
    sudo dnf -y remove linux-firmware
    sudo dnf -y remove "$(dnf repoquery --installonly --latest-limit=-1 -q)"
    sudo dnf -y autoremove
    sudo dnf -y clean all --enablerepo=\*;
  else
    echo '>> Cleaning up unneeded packages...'
    sudo yum -y remove linux-firmware
    sudo package-cleanup --oldkernels --count=1
    sudo yum -y autoremove
    sudo yum -y clean all --enablerepo=\*;
  fi
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep photon; then
  sudo tdnf -y clean all --enablerepo=\*;
fi
