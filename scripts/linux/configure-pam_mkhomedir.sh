#!/bin/bash -eu
sudo sed -i 's/optional.*pam_mkhomedir.so/required\t\tpam_mkhomedir.so umask=0027/' /usr/share/pam-configs/mkhomedir
