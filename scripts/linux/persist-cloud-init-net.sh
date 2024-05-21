#!/bin/sh -eu
echo '>> Preserving network settings...'
if grep -q 'manual_cache_clean' /etc/cloud/cloud.cfg; then
  sudo sed -i 's/^manual_cache_clean.*$/manual_cache_clean: True/' /etc/cloud/cloud.cfg
else
  echo 'manual_cache_clean: True' | sudo tee -a /etc/cloud/cloud.cfg
fi
