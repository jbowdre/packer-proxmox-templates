#!/usr/bin/env bash
# prunes default noisy MOTD

set -eu

echo '>> Pruning default MOTD...'

if awk -F= '/^ID/{print $2}' /etc/os-release | grep -q rhel; then
  if [ -L "/etc/motd.d/insights-client" ]; then
    sudo unlink /etc/motd.d/insights-client
  fi
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q debian; then
  sudo chmod -x /etc/update-motd.d/91-release-upgrade
fi