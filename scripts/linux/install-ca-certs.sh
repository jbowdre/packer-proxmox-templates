#!/bin/bash -eu
if awk -F= '/^ID/{print $2}' /etc/os-release | grep -q debian; then
  echo '>> Installing certificates...'
  sudo cp /tmp/certs/* /usr/local/share/ca-certificates/
  cd /usr/local/share/ca-certificates/
  for file in *.cer; do
    sudo mv -- "$file" "${file%.cer}.crt"
  done
  sudo /usr/sbin/update-ca-certificates
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q rhel; then
  echo '>> Installing certificates...'
  sudo cp /tmp/certs/* /etc/pki/ca-trust/source/anchors/
  cd /etc/pki/ca-trust/source/anchors/
  for file in *.cer; do
    sudo mv -- "$file" "${file%.cer}.crt"
  done
  sudo /bin/update-ca-trust
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q photon; then
  echo '>> Installing certificates...'
  sudo cp /tmp/certs/* /etc/ssl/certs/
  cd /etc/ssl/certs/
  for file in *.cer; do
    sudo mv -- "$file" "${file%.cer}.pem"
  done
  sudo /usr/bin/rehash_ca_certificates.sh
fi
