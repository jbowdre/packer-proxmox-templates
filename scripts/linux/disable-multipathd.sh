#!/usr/bin/env bash
set -eu
sudo systemctl disable multipathd
echo 'Disabling multipathd'
