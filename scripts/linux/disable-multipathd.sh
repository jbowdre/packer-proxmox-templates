#!/usr/bin/env bash
# disables multipathd
set -eu

echo '>> Disabling multipathd...'
sudo systemctl disable multipathd
