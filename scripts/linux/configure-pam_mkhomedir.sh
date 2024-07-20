#!/usr/bin/env bash
# configures pam_mkhomedir to create home directories with 750 permissions

set -eu

sudo sed -i 's/optional.*pam_mkhomedir.so/required\t\tpam_mkhomedir.so umask=0027/' /usr/share/pam-configs/mkhomedir
