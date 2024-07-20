#!/usr/bin/env bash
# cleans up cloud-init state
set -eu

echo '>> Cleaning up cloud-init state...'
sudo cloud-init clean -l
