#!/bin/bash -eu

domain='lab.example.com'
defAdminGroup='linuxadministrators'
ou=
username=


getInputs() {
  read -rp "OU in which to create the computer object [empty to accept domain default]: " ou
  read -rp "Domain group of Linux administrators who will be granted sudo privileges [${defAdminGroup}]: " adminGroup
  read -rp 'Domain account with privileges to join computers to the domain: ' username
}

helpText() {
  echo -e "\nUsage: $0 [-o OU] [-a ADMIN_GROUP] -u DOMAIN_JOIN_USERNAME"
  echo -e "\nMandatory parameter:"
  echo -e "\t-u, --username DOMAIN_JOIN_USERNAME \tDomain account with privileges to join computers"
  echo -e "\nOptional flags:"
  echo -e "\t-o, --ou ORGANIZATIONAL_UNIT \t\tDN of the OU in which to create the computer object (if not set, use the default for the domain)"
  echo -e "\t-a, --adminGroup ADMIN_GROUP \t\tDomain group of Linux administrators who will be granted sudo privileges (default: ${defAdminGroup})"
  exit 0
}

installRhel() {
  sudo yum install -y \
  adcli \
  krb5-workstation \
  oddjob \
  oddjob-mkhomedir \
  realmd \
  samba-common-tools \
  sssd \
  sssd-tools
}

installDebian() {
  sudo apt-get update
  sudo apt-get -y install \
  adcli \
  krb5-user \
  libnss-sss \
  libpam-sss \
  oddjob \
  oddjob-mkhomedir \
  packagekit \
  realmd \
  samba-common-bin \
  sssd \
  sssd-tools
}

joinDomain() {
  if sudo realm discover "${domain}"; then
    read -rp "Proceed with joining the above domain [y/N]? " confirm
    if [ "${confirm,,}" == "y" ]; then
      if [ -n "${ou}" ]; then
        if sudo realm join -v -U "${username}" "${domain}" "--computer-ou=${ou}"; then
          echo "Successfully joined ${domain}!"
        else
          echo "[ERROR] Domain join unsuccessful."
          exit 1
        fi
      else
        if sudo realm join -v -U "${username}" "${domain}"; then
          echo "Successfully joined ${domain}!"
        else
          echo "[ERROR] Domain join unsuccessful."
          exit 1
        fi
      fi
    else
      echo "[Abort] Domain join aborted."
      exit 1
    fi
  fi
}

configRhel() {
  echo "Creating SSSD config for RHEL-like systems..."
  sudo cp /etc/sssd/sssd.conf{,.bak}
  sudo bash -c "cat << EOF > /etc/sssd/sssd.conf
[sssd]
domains = lab.example.com
config_file_version = 2
services = nss, pam

[domain/lab.example.com]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = lab.example.com
realmd_tags = manages-system joined-with-adcli
id_provider = ad
fallback_homedir = /home/%u
ad_domain = lab.example.com
use_fully_qualified_names = False
ad_gpo_ignore_unreadable = True
auto_private_groups = True
ldap_id_mapping = True
EOF"

  echo "(Re)starting services..."
  sudo systemctl restart sssd
  sudo systemctl start oddjobd
  sudo realm deny --all
  sudo realm permit --groups "${adminGroup}"

  echo "Creating sudoers config..."
  sudo bash -c "cat << EOF > /etc/sudoers.d/admins
%${adminGroup} ALL=(ALL) ALL
EOF"
  echo "Config complete!"
}

configDebian() {
  echo "Creating SSSD config for Debian-like systems..."
  sudo cp /etc/sssd/sssd.conf{,.bak}
  sudo bash -c "cat << EOF > /etc/sssd/sssd.conf
[sssd]
domains = lab.example.com
config_file_version = 2

[domain/lab.example.com]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = lab.example.com
realmd_tags = manages-system joined-with-adcli
id_provider = ad
fallback_homedir = /home/%u
ad_domain = lab.example.com
use_fully_qualified_names = False
ad_gpo_ignore_unreadable = True
auto_private_groups = True
ldap_id_mapping = True
EOF"

  echo "(Re)starting services..."
  sudo systemctl restart sssd
  sudo pam-auth-update --enable mkhomedir --force
  sudo realm deny --all
  sudo realm permit --groups "${adminGroup}"

  echo "Creating sudoers config..."
  sudo bash -c "cat << EOF > /etc/sudoers.d/admins
%${adminGroup} ALL=(ALL) ALL
EOF"
  echo "Config complete!"
}

PARAMS=""
if [ "$#" = 0 ]; then
  getInputs
else
  while (( "$#" )); do
    case "$1" in
      -o|--ou)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          ou="$2"
          shift 2
        else
          echo "Error: Argument for $1 is missing" >&2
          exit 1
        fi
        ;;
      -a|--adminGroup)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          adminGroup="$2"
          shift 2
        else
          echo "Error: Argument for $1 is missing" >&2
          exit 1
        fi
        ;;
      -u|--username)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          username="$2"
          shift 2
        else
          echo "Error: Argument for $1 is missing" >&2
          exit 1
        fi
        ;;
      -\?|-h|--help)
        helpText
        ;;
      --*|-*)
        echo "Error: unsupported flag $1" >&2
        helpText
        ;;
      *)
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
  done
  eval set -- "$PARAMS"
fi

adminGroup="${adminGroup:-$defAdminGroup}"
if [ -z "${username}" ]; then
  echo "[ERROR] Username required!"
  helpText
fi

if awk -F= '/^ID/{print $2}' /etc/os-release | grep -q rhel; then
  flavor="rhel"
elif awk -F= '/^ID/{print $2}' /etc/os-release | grep -q debian; then
  flavor="debian"
else
  echo "Not a supported Linux flavor, aborting..."
  exit 1
fi

case "${flavor}" in
  rhel)
    echo "Preparing to install required packages..."
    installRhel
    joinDomain
    configRhel
    ;;
  debian)
    echo "Preparing to install required packages..."
    installDebian
    joinDomain
    configDebian
    ;;
esac
