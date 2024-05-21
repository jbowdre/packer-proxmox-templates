#!/bin/bash -eu
echo '>> Waiting for cloud-init...'
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do 
  sleep 1
done
