#!/usr/bin/env -S bash -eu
# disables multipathd

echo '>> Disabling multipathd...'
sudo systemctl disable multipathd
