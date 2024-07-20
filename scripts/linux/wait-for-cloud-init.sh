#!/usr/bin/env bash
# waits for cloud-init to finish before proceeding

set -eu

echo '>> Waiting for cloud-init...'
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  sleep 1
done
