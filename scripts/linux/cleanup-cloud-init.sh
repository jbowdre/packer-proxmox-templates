#!/usr/bin/env -S bash -eu
# cleans up cloud-init state

echo '>> Cleaning up cloud-init state...'
sudo cloud-init clean -l
