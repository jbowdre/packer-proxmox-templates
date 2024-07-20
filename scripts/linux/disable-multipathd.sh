#!/usr/bin/env bash
# disables multipathd

set -eu

sudo systemctl disable multipathd
echo 'Disabling multipathd'
