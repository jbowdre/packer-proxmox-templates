#!/usr/bin/env bash
# zeroes out free space to reduce disk size

set -eu

echo '>> Zeroing free space to reduce disk size'
sudo sh -c 'dd if=/dev/zero of=/EMPTY bs=1M || true; sync; sleep 1; sync'
sudo sh -c 'rm -f /EMPTY; sync; sleep 1; sync'
