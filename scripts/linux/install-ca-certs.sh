#!/usr/bin/env -S bash -eu
# installs trusted CA certs from /tmp/certs/

if awk -F= '/^ID/{print $2}' /etc/os-release | grep -q debian; then
  echo '>> Installing certificates...'
  if ls /tmp/certs/*.cer >/dev/null 2>&1; then
    sudo cp /tmp/certs/* /usr/local/share/ca-certificates/
    cd /usr/local/share/ca-certificates/
    for file in *.cer; do
      sudo mv -- "$file" "${file%.cer}.crt"
    done
    sudo /usr/sbin/update-ca-certificates
  else
    echo 'No certs to install.'
  fi
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q rhel; then
  echo '>> Installing certificates...'
  if ls /tmp/certs/*.cer >/dev/null 2>&1; then
    sudo cp /tmp/certs/* /etc/pki/ca-trust/source/anchors/
    cd /etc/pki/ca-trust/source/anchors/
    for file in *.cer; do
      sudo mv -- "$file" "${file%.cer}.crt"
    done
    sudo /bin/update-ca-trust
  else
    echo 'No certs to install.'
  fi
fi
