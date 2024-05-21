#!/bin/bash -eu
echo '>> Cleaning up cloud-init state...'
sudo cloud-init clean -l
