#!/usr/bin/env -S bash -eu
# waits for cloud-init to finish before proceeding

echo '>> Waiting for cloud-init...'
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  sleep 1
done
