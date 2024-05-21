#!/bin/bash -eu
# Performs steps to harden Ubuntu 22.04 LTS toward the CIS Level 2 benchmark

echo ">>> Beginning hardening tasks..."

function current_task() {
  #$1 = Rule Name
  echo "-> $1..."
}

rule_name="Install AIDE"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y aide

rule_name="Ensure Only Users Logged In To Real tty Can Execute Sudo - sudo use_pty"
current_task "$rule_name"
if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
  sudo cp /etc/sudoers /etc/sudoers.bak
  echo "Defaults use_pty" | sudo tee -a /etc/sudoers
  if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
    sudo rm -f /etc/sudoers.bak
  else
    echo "Fail to validate remediated /etc/sudoers, reverting to original file."
    sudo mv /etc/sudoers.bak /etc/sudoers
    false
  fi
else
  echo "Skipping remediation, /etc/sudoers failed to validate"
  false
fi

rule_name="Ensure Sudo Logfile Exists - sudo logfile"
current_task "$rule_name"
sudo_logfile="/var/log/sudo.log"
if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
  sudo cp /etc/sudoers /etc/sudoers.bak
  echo "Defaults logfile=${sudo_logfile}" | sudo tee -a /etc/sudoers
  if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
    sudo rm -f /etc/sudoers.bak
  else
    echo "Fail to validate remediated /etc/sudoers, reverting to original file."
    sudo mv /etc/sudoers.bak /etc/sudoers
    false
  fi
else
  echo "Skipping remediation, /etc/sudoers failed to validate"
  false
fi

rule_name="Ensure Users Re-Authenticate for Privilege Escalation - sudo"
current_task "$rule_name"
sudo sed -i 's/NOPASSWD://g' /etc/cloud/cloud.cfg

rule_name="The operating system must require Re-Authentication when using the sudo command. Ensure sudo timestamp_timeout is appropriate - sudo timestamp_timeout"
current_task "$rule_name"
sudo_timestamp_timeout='15'
if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
  sudo cp /etc/sudoers /etc/sudoers.bak
  echo "Defaults timestamp_timeout=${sudo_timestamp_timeout}" | sudo tee -a /etc/sudoers
  if sudo /usr/sbin/visudo -qcf /etc/sudoers; then
    sudo rm -f /etc/sudoers.bak
  else
    echo "Fail to validate remediated /etc/sudoers, reverting to original file."
    sudo mv /etc/sudoers.bak /etc/sudoers
    false
  fi
else
  echo "Skipping remediation, /etc/sudoers failed to validate"
  false
fi

rule_name="Modify the System Login Banner | Modify the System Login Banner for Remote Connections"
current_task "$rule_name"
login_banner_text="\
I've read & consent to terms in IS user agreem't."
cat << EOF | sudo tee /etc/issue
\S
Kernel \r on an \m

$login_banner_text

EOF
cat << EOF | sudo tee /etc/issue.net

$login_banner_text

EOF

rule_name="Limit Password Reuse"
current_task "$rule_name"
password_pam_history='5'
cat << EOF | sudo tee /usr/share/pam-configs/pwhistory
Name: pwhistory
Default: yes
Priority: 0
Password-Type: Additional
Password:
    requisite                       pam_pwhistory.so use_authtok remember=$password_pam_history
EOF
sudo pam-auth-update --package

rule_name="Lock Accounts After Failed Password Attempts"
current_task "$rule_name"
cat << EOF | sudo tee /usr/share/pam-configs/faillock_preauth
Name: faillock preauth
Default: yes
Priority: 1024
Auth-Type: Primary
Auth:
    required                        pam_faillock.so preauth
Account-Type: Primary
Account:
    required                        pam_faillock.so
EOF
cat << EOF | sudo tee /usr/share/pam-configs/faillock_fail
Name: faillock fail
Default: yes
Priority: 0
Auth-Type: Primary
Auth:
    [default=die]                   pam_faillock.so authfail
    sufficient                      pam_faillock.so authsucc
EOF
sudo pam-auth-update --package
password_pam_faillock_deny='4'
FAILLOCK_CONF="/etc/security/faillock.conf"
regex="^\s*deny\s*="
line="deny = $password_pam_faillock_deny"
if ! grep -q "$regex" "$FAILLOCK_CONF"; then
  echo "$line" | sudo tee -a "$FAILLOCK_CONF"
else
  sudo sed -i --follow-symlinks 's|^\s*\(deny\s*=\s*\)\(\S\+\)|\1'"$password_pam_faillock_deny"'|g' "$FAILLOCK_CONF"
fi

rule_name="Set Interval For Counting Failed Password Attempts"
current_task "$rule_name"
password_pam_faillock_interval='900'
FAILLOCK_CONF="/etc/security/faillock.conf"
regex="^\s*fail_interval\s*="
line="fail_interval = $password_pam_faillock_interval"
if ! grep -q "$regex" $FAILLOCK_CONF; then
  echo "$line" | sudo tee -a "$FAILLOCK_CONF"
else
  sudo sed -i --follow-symlinks 's|^\s*\(fail_interval\s*=\s*\)\(\S\+\)|\1'"$password_pam_faillock_interval"'|g' "$FAILLOCK_CONF"
fi

rule_name="Set Lockout Time For Failed Password Attempts"
current_task "$rule_name"
password_pam_faillock_time='600'
FAILLOCK_CONF="/etc/security/faillock.conf"
regex="^\s*unlock_time\s*="
line="unlock_time = $password_pam_faillock_time"
if ! grep -q "$regex" "$FAILLOCK_CONF"; then
  echo "$line" | sudo tee -a "$FAILLOCK_CONF"
else
  sudo sed -i --follow-symlinks 's|^\s*\(unlock_time\s*=\s*\)\(\S\+\)|\1'"$password_pam_faillock_time"'|g' "$FAILLOCK_CONF"
fi

rule_name="Install pam_pwquality Package"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-pwquality

rule_name="Enable pam_pwquality"
current_task "$rule_name"
sudo sed -i --follow-symlinks "s/^# enforcing.*$/enforcing = 1/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Digit Characters"
current_task "$rule_name"
password_pam_dcredit='-1'
sudo sed -i --follow-symlinks "s/^# dcredit.*$/dcredit = $password_pam_dcredit/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Lowercase Characters"
current_task "$rule_name"
password_pam_lcredit='-1'
sudo sed -i --follow-symlinks "s/^# lcredit.*$/lcredit = $password_pam_lcredit/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Different Categories"
current_task "$rule_name"
password_pam_minclass='4'
sudo sed -i --follow-symlinks "s/^# minclass.*$/minclass = $password_pam_minclass/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Length"
current_task "$rule_name"
password_pam_minlen='14'
sudo sed -i --follow-symlinks "s/^# minlen.*$/minlen = $password_pam_minlen/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Special Characters"
current_task "$rule_name"
password_pam_ocredit='-1'
sudo sed -i --follow-symlinks "s/^# ocredit.*$/ocredit = $password_pam_ocredit/" /etc/security/pwquality.conf

rule_name="Ensure PAM Enforces Password Requirements - Minimum Uppercase Characters"
current_task "$rule_name"
password_pam_ucredit='-1'
sudo sed -i --follow-symlinks "s/^# ucredit.*$/ucredit = $password_pam_ucredit/" /etc/security/pwquality.conf

rule_name="Set Account Expiration Following Inactivity"
current_task "$rule_name"
password_inactive_days='30'
sudo sed -i --follow-symlinks "s/^.*INACTIVE=.*/INACTIVE=$password_inactive_days/" /etc/default/useradd

rule_name="Set Password Maximum Age"
current_task "$rule_name"
password_max_days='365'
sudo sed -i "s/PASS_MAX_DAYS.*/PASS_MAX_DAYS\t$password_max_days/g" /etc/login.defs

rule_name="Set Password Minimum Age"
current_task "$rule_name"
password_min_days='1'
sudo sed -i "s/PASS_MIN_DAYS.*/PASS_MIN_DAYS\t$password_min_days/g" /etc/login.defs

rule_name="Enforce usage of pam_wheel for su authentication"
current_task "$rule_name"
echo -e "auth\trequired\tpam_wheel.so use_uid" | sudo tee -a /etc/pam.d/su

rule_name="Ensure the Default Bash Umask is Set Correctly | Ensure the Default C Shell Umask is Set Correctly | Ensure the Default Umask is Set Correctly in login.defs | Ensure the Default Umask is Set Correctly in /etc/profile"
current_task "$rule_name"
account_user_umask='027'
if ! grep -q "^umask" /etc/bash.bashrc; then
  if [ ! -e /etc/bash.bashrc ]; then
    sudo touch /etc/bash.bashrc
    sudo chmod 644 /etc/bash.bashrc
  fi
  echo "umask $account_user_umask" | sudo tee -a /etc/bash.bashrc
else
  sudo sed -i -E -e "s/^(\s*umask).*/\1 $account_user_umask/g" /etc/bash.bashrc
fi
if ! grep -q "^umask" /etc/csh.cshrc; then
  if [ ! -e /etc/csh.cshrc ]; then
    sudo touch /etc/csh.cshrc
    sudo chmod 644 /etc/csh.cshrc
  fi
  echo "umask $account_user_umask" | sudo tee -a /etc/csh.cshrc
else
  sudo sed -i -E -e "s/^(\s*umask).*/\1 $account_user_umask/g" /etc/csh.cshrc
fi
if ! grep -q "^UMASK" /etc/login.defs; then
  printf 'UMASK\t\t%s\n' $account_user_umask | sudo tee -a /etc/login.defs
else
  sudo sed -i "s/^UMASK.*$/UMASK\t\t$account_user_umask/g" /etc/login.defs
fi
if ! grep -q "^umask" /etc/profile; then
  echo "umask $account_user_umask" | sudo tee -a /etc/profile
else
  sudo sed -i -E -e "s/^(\s*umask).*/\1 $account_user_umask/g" /etc/profile
fi

rule_name="Set Interactive Session Timeout"
current_task "$rule_name"
account_timeout='600'
echo -e "TMOUT=$account_timeout\nreadonly TMOUT\nexport TMOUT" | sudo tee -a /etc/profile.d/tmout.sh
sudo chmod 644 /etc/profile.d/tmout.sh

rule_name="Ensure the audit Subsystem is Installed"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y auditd

rule_name="Enable Auditing for Processes Which Start Prior to the Audit Daemon"
current_task "$rule_name"
sudo sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 audit=1\"/" '/etc/default/grub'
sudo update-grub

rule_name="Extend Audit Backlog Limit for the Audit Daemon"
current_task "$rule_name"
sudo sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 audit_backlog_limit=8192\"/" '/etc/default/grub'
sudo update-grub

rule_name="Record Events that Modify the System's Discretionary Access Controls"
current_task "$rule_name"
audit_key="perm_mod"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "chmod"
  "chown"
  "fchmod"
  "fchmodat"
  "fchown"
  "fchownat"
  "fremovexattr"
  "fsetxattr"
  "lchown"
  "lremovexattr"
  "lsetxattr"
  "removexattr"
  "setxattr"
)
for audit_item in "${audit_list[@]}"; do
  if grep -q "xattr" <<< "$audit_item"; then
    audit_commands=(
      "-a always,exit -F arch=b32 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
      "-a always,exit -F arch=b32 -S $audit_item -F auid=0 -F key=$audit_key"
      "-a always,exit -F arch=b64 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
      "-a always,exit -F arch=b64 -S $audit_item -F audi=0 -F key=$audit_key"
    )
  else
    audit_commands=(
      "-a always,exit -F arch=b32 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
      "-a always,exit -F arch=b64 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
    )
  fi
  for audit_command in "${audit_commands[@]}"; do
    echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
  done
done

rule_name="Ensure auditd Collects File Deletion Events by User"
current_task "$rule_name"
audit_key="delete"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "rename"
  "renameat"
  "unlink"
  "unlinkat"
)
for audit_item in "${audit_list[@]}"; do
  audit_commands=(
    "-a always,exit -F arch=b32 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
    "-a always,exit -F arch=b64 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
  )
  for audit_command in "${audit_commands[@]}"; do
    echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
  done
done

rule_name="Record Unauthorized Access Attempts Events to Files (unsuccessful)"
current_task "$rule_name"
audit_key="access"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "creat"
  "ftruncate"
  "open"
  "openat"
  "truncate"
)
for audit_item in "${audit_list[@]}"; do
  audit_commands=(
    "-a always,exit -F arch=b32 -S $audit_item -F exit=-EACCES -F auid>=1000 -F auid!=unset -F key=$audit_key"
    "-a always,exit -F arch=b32 -S $audit_item -F exit=-EPERM -F auid>=1000 -F auid!=unset -F key=$audit_key"
    "-a always,exit -F arch=b64 -S $audit_item -F exit=-EACCES -F auid>=1000 -F auid!=unset -F key=$audit_key"
    "-a always,exit -F arch=b64 -S $audit_item -F exit=-EPERM -F auid>=1000 -F auid!=unset -F key=$audit_key"
  )
  for audit_command in "${audit_commands[@]}"; do
    echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
  done
done

rule_name="Ensure auditd Collects Information on Kernel Module Loading and Unloading"
current_task "$rule_name"
audit_key="modules"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "init_module"
  "delete_module"
)
for audit_item in "${audit_list[@]}"; do
  audit_commands=(
    "-a always,exit -F arch=b32 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
    "-a always,exit -F arch=b64 -S $audit_item -F auid>=1000 -F auid!=unset -F key=$audit_key"
  )
  for audit_command in "${audit_commands[@]}"; do
    echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
  done
done

rule_name="Record Attempts to Alter Logon and Logout Events"
current_task "$rule_name"
audit_key="logins"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "/var/log/faillog"
  "/var/log/lastlog"
  "/var/log/tallylog"
)
for audit_item in "${audit_list[@]}"; do
  audit_commands=(
    "-w $audit_item -p wa -k $audit_key"
  )
  for audit_command in "${audit_commands[@]}"; do
    echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
  done
done

rule_name="Ensure auditd Collects Information on the Use of Privileged Commands"
current_task "$rule_name"
audit_key="privileged"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_list=(
  "/usr/bin/at"
  "/usr/bin/chacl"
  "/usr/bin/chage"
  "/usr/bin/chcon"
  "/usr/bin/chfn"
  "/usr/bin/chsh"
  "/usr/bin/crontab"
  "/usr/bin/gpasswd"
  "/usr/bin/mount"
  "/usr/bin/newgidmap"
  "/usr/bin/newgrp"
  "/usr/bin/newuidmap"
  "/usr/bin/setfacl"
  "/usr/bin/ssh-agent"
  "/usr/bin/su"
  "/usr/bin/sudo"
  "/usr/bin/sudoedit"
  "/usr/bin/umount"
  "/usr/libexec/openssh/ssh-keysign"
  "/usr/sbin/postdrop"
  "/usr/sbin/postqueue"
  "/usr/sbin/unix_chkpwd"
  "/usr/sbin/usermod"
)
for audit_item in "${audit_list[@]}"; do
  audit_command="-a always,exit -F path=$audit_item -F perm=x -F auid>=1000 -F auid!=unset -F key=$audit_key"
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done
audit_list=(
  "/sbin/insmod"
  "/sbin/modprobe"
  "/sbin/rmmod"
)
for audit_item in "${audit_list[@]}"; do
  audit_command="-w $audit_item -p x -k $audit_key"
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record Events that Modify the System's Mandatory Access Controls"
current_task "$rule_name"
audit_key="mac-policy"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_command="-w /etc/selinux/ -p wa -k $audit_key"
echo "${audit_command}" | sudo tee -a "${audit_rule_file}"

rule_name="Ensure auditd Collects Information on Exporting to Media (successful)"
current_task "$rule_name"
audit_key="export"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=unset -F key=$audit_key"
  "-a always,exit -F arch=b64 -S mount -F audi>=1000 -F auid!=unset -F key=$audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record attempts to alter time"
current_task "$rule_name"
audit_key="time"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-a always,exit -F arch=b32 -S adjtimex -F key=$audit_key"
  "-a always,exit -F arch=b64 -S adjtimex -F key=$audit_key"
  "-a always,exit -F arch=b32 -S clock_settime -F a0=0x0 -F key=$audit_key"
  "-a always,exit -F arch=b64 -S clock_settime -F a0=0x0 -F key=$audit_key"
  "-a always,exit -F arch=b32 -S settimeofday -F key=$audit_key"
  "-a always,exit -F arch=b64 -S settimeofday -F key=$audit_key"
  "-a always,exit -F arch=b32 -S stime -F key=$audit_key"
  "-w /etc/localtime -p wa -k $audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Configure auditd admin_space_left Action on Low Disk Space"
current_task "$rule_name"
auditd_option_name="admin_space_left_action"
auditd_option_value="single"
auditd_config_file="/etc/audit/auditd.conf"
sudo sed -i "s/^${auditd_option_name}.*$/${auditd_option_name} = ${auditd_option_value}/" "${auditd_config_file}"

rule_name="Configure auditd space_left Action on Low Disk Space"
current_task "$rule_name"
auditd_option_name="space_left_action"
auditd_option_value="email"
auditd_config_file="/etc/audit/auditd.conf"
sudo sed -i "s/^${auditd_option_name}.*$/${auditd_option_name} = ${auditd_option_value}/" "${auditd_config_file}"

rule_name="Make the auditd Configuration Immutable"
current_task "$rule_name"
audit_key="immutable"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-e 2"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record Events that Modify the System's Network Environment"
current_task "$rule_name"
audit_key="network"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k $audit_key"
  "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k $audit_key"
  "-w /etc/issue -p wa -k $audit_key"
  "-w /etc/issue.net -p wa -k $audit_key"
  "-w /etc/hosts -p wa -k $audit_key"
  "-w /etc/sysconfig/network -p wa -k $audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record Attempts to Alter Process and Session Initiation Information"
current_task "$rule_name"
audit_key="session"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-w /var/run/utmp -p wa -k $audit_key"
  "-w /var/log/btmp -p wa -k $audit_key"
  "-w /var/log/wtmp -p wa -k $audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record Events When Privileged Executables are Run"
current_task "$rule_name"
audit_key="privileged"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k setuid"
  "-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k setuid"
  "-a always,exit -F arch=b32 -S execve -C gid!=egid -F egid=0 -k setgid"
  "-a always,exit -F arch=b64 -S execve -C gid!=egid -F egid=0 -k setgid"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Ensure auditd Collects System Administrator Actions"
current_task "$rule_name"
audit_key="actions"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-w /etc/sudoers -p wa -k $audit_key"
  "-w /etc/sudoers.d/ -p wa -k $audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Record Events that Modify User/Group Information"
current_task "$rule_name"
audit_key="identity"
audit_rule_file="/etc/audit/rules.d/${audit_key}.rules"
sudo touch "${audit_rule_file}"
sudo chmod 0640 "${audit_rule_file}"
audit_commands=(
  "-w /etc/group -p wa -k $audit_key"
  "-w /etc/gshadow -p wa -k $audit_key"
  "-w /etc/passwd -p wa -k $audit_key"
  "-w /etc/security/opasswd -p wa -k $audit_key"
  "-w /etc/shadow -p wa -k $audit_key"
)
for audit_command in "${audit_commands[@]}"; do
  echo "${audit_command}" | sudo tee -a "${audit_rule_file}"
done

rule_name="Ensure AppArmor is enabled in the bootloader configuration"
current_task "$rule_name"
sudo sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 apparmor=1 security=apparmor\"/" '/etc/default/grub'
sudo update-grub

rule_name="Set the UEFI Boot Loader Password"
current_task "$rule_name"
encrypted_grub_password=$(echo -e "$BOOTLOADER_PASSWORD\n$BOOTLOADER_PASSWORD" | grub-mkpasswd-pbkdf2 | awk '/grub.pbkdf2/ { print $NF }')
echo -e "set superusers=\"root\"\npassword_pbkdf2 root ${encrypted_grub_password}" | sudo tee -a /etc/grub.d/40_custom
# Allow booting without password
sudo sed -i "s/\(^CLASS=\".*\)\"/\1 --unrestricted\"/" '/etc/grub.d/10_linux'
sudo update-grub

rule_name="Ensure journald is configured to compress large log files"
current_task "$rule_name"
journald_option_name="Compress"
journald_option_value="yes"
journald_config_file="/etc/systemd/journald.conf"
sudo sed -i "s/#${journald_option_name}=.*/${journald_option_name}=${journald_option_value}/" "${journald_config_file}"

rule_name="Ensure journald is configured to write logfiles to persistent disk"
current_task "$rule_name"
journald_option_name="Storage"
journald_option_value="persistent"
journald_config_file="/etc/systemd/journald.conf"
sudo sed -i "s/#${journald_option_name}=.*/${journald_option_name}=${journald_option_value}/" "${journald_config_file}"

rule_name="Configure Firewall"
current_task "$rule_name"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
sudo systemctl enable ufw.service
sudo systemctl start ufw.service
# avoid clobbering desired sysctl config
sudo sed -i 's|net/ipv4/conf/all/log_martians=|#net/ipv4/conf/all/log_martians=|' /etc/ufw/sysctl.conf
sudo sed -i 's|net/ipv4/conf/default/log_martians=|#net/ipv4/conf/default/log_martians=|' /etc/ufw/sysctl.conf
# force enable on boot
sudo sed -i 's/ENABLED=no/ENABLED=yes/' /etc/ufw/ufw.conf

rule_name="Configure Kernel Parameters"
current_task "$rule_name"
sysctl_config_file="/etc/sysctl.d/99-hardening.conf"
sysctl_params=(
  "Configure Accepting Routing Advertisements on All IPv6 Interfaces,net.ipv6.conf.all.accept_ra,0"
  "Disable Accepting ICMP Redirects for All IPv6 Interfaces,net.ipv6.conf.all.accept_redirects,0"
  "Disable Kernel Parameter for Accepting Source-Routed Packets on all IPv6 Interfaces,net.ipv6.conf.all.accept_source_route,0"
  "Disable Kernel Parameter for IPv6 Forwarding,net.ipv6.conf.all.forwarding,0"
  "Disable Accepting Router Advertisements on all IPv6 Interfaces by Default,net.ipv6.conf.default.accept_ra,0"
  "Disable Kernel Parameter for Accepting ICMP Redirects by Default on All IPv6 Interfaces,net.ipv6.conf.default.accept_redirects,0"
  "Disable Kernel Parameter for Accepting Source-Routed Packets on IPv6 Interfaces by Default,net.ipv6.conf.default.accept_source_route,0"
  "Disable Accepting ICMP Redirects for All IPv4 Interfaces,net.ipv4.conf.all.accept_redirects,0"
  "Disable Kernel Parameter for Accepting Source-Routed Packets on All IPv4 Interfaces,net.ipv4.conf.all.accept_source_route,0"
  "Enable Kernel Parameter to Log Martian Packets,net.ipv4.conf.all.log_martians,1"
  "Enable Kernel Parameter to Use Reverse Path Filtering on All IPv4 Interfaces,net.ipv4.conf.all.rp_filter,1"
  "Disable Kernel Parameter for Accepting Secure ICMP Redirects on All IPv4 Interfaces,net.ipv4.conf.all.secure_redirects,0"
  "Disable Kernel Parameter for Accepting ICMP Redirects by Default on All IPv4 Interfaces,net.ipv4.conf.default.accept_redirects,0"
  "Disable Kernel Parameter for Accepting Source-Routed Packets on IPv4 Interfaces by Default,net.ipv4.conf.default.accept_source_route,0"
  "Enable Kernel Parameter to Log Martian Packets on all IPv4 Interfaces by Default,net.ipv4.conf.default.log_martians,1"
  "Enable Kernel Parameter to Use Reverse Path Filtering on IPv4 Interfaces by Default,net.ipv4.conf.default.rp_filter,1"
  "Configure Kernel Parameter for Accepting Secure Redirects by Default,net.ipv4.conf.default.secure_redirects,0"
  "Enable Kernel Parameter to Ignore ICMP Broadcast Requests,net.ipv4.icmp_echo_ignore_broadcasts,1"
  "Enable Kernel Parameter to Ignore Bogus ICMP Error Responses on IPv4 Interfaces,net.ipv4.icmp_ignore_bogus_error_responses,1"
  "Enable Kernel Parameter to Use TCP Syncookies on Network Interfaces,net.ipv4.tcp_syncookies,1"
  "Disable Kernel Parameter for Sending ICMP Redirects on all IPv4 Interfaces,net.ipv4.conf.all.send_redirects,0"
  "Disable Kernel Parameter for Sending ICMP Redirects on IPv4 Interfaces by Default,net.ipv4.conf.default.send_redirects,0"
  "Disable Kernel Parameter for IP Forwarding on IPv4 Interfaces,net.ipv4.ip_forward,0"
  "Disable Core Dumps for SUID programs,fs.suid_dumpable,0"
  "Enable Randomized Layout of Virtual Address Space,kernel.randomize_va_space,2"
)
for sysctl_param in "${sysctl_params[@]}"; do
  sysctl_param_name=$(echo "$sysctl_param" | cut -d',' -f1)
  sysctl_param_key=$(echo "$sysctl_param" | cut -d',' -f2)
  sysctl_param_value=$(echo "$sysctl_param" | cut -d',' -f3)
  sudo sed -i -s "s/^${sysctl_param_key}/#${sysctl_param_key}/" /etc/sysctl.d/*.conf
  echo -e "# $sysctl_param_name\n${sysctl_param_key} = ${sysctl_param_value}\n" | sudo tee -a "$sysctl_config_file"
done
sudo chmod a+r "$sysctl_config_file"

rule_name="Disable Modules: DCCP, RDS, SCTP, TIPC, cramfs, freevxfs, jffs2, hfs, hfsplus, squashfs, udf, usb-storage"
current_task "$rule_name"
modules=(
  "cramfs"
  "dccp"
  "freevxfs"
  "hfs"
  "hfsplus"
  "jffs2"
  "rds"
  "sctp"
  "squashfs"
  "tipc"
  "udf"
  "usb-storage"
)
for module in "${modules[@]}"; do
  module_file="/etc/modprobe.d/${module}-blacklist.conf"
  if LC_ALL=C grep -q -m 1 "^install ${module}" "${module_file}" 2>/dev/null; then
    sudo sed -i "s#^install ${module}.*#install ${module} /bin/true#g" "${module_file}"
  else
    echo -e "install ${module} /bin/true" | sudo tee -a "${module_file}"
  fi
  if ! LC_ALL=C grep -q -m 1 "^blacklist ${module}" "${module_file}" 2>/dev/null; then
    echo -e "blacklist ${module}" | sudo tee -a "${module_file}"
  fi
done

rule_name="Add noexec Option to /dev/shm"
current_task "$rule_name"
mount_point_match_regexp="$(printf "[[:space:]]%s[[:space:]]" /dev/shm)"
if [ "$(grep -c "$mount_point_match_regexp" /etc/fstab)" -eq 0 ]; then
  previous_mount_opts=$(grep "$mount_point_match_regexp" /etc/mtab | head -1 |  awk '{print $4}' \
    | sed -E "s/(rw|defaults|seclabel|noexec)(,|$)//g;s/,$//")
  [ "$previous_mount_opts" ] && previous_mount_opts+=","
  echo "tmpfs /dev/shm tmpfs defaults,${previous_mount_opts}noexec 0 0" | sudo tee -a /etc/fstab
elif [ "$(grep "$mount_point_match_regexp" /etc/fstab | grep -c "noexec")" -eq 0 ]; then
  previous_mount_opts=$(grep "$mount_point_match_regexp" /etc/fstab | awk '{print $4}')
  sudo sed -i "s|\(${mount_point_match_regexp}.*${previous_mount_opts}\)|\1,noexec|" /etc/fstab
fi

rule_name="Add mount options to fstab"
current_task "$rule_name"
mountpoint_list=(
  "/home"
  "/tmp"
  "/var"
  "/var/log"
  "/var/log/audit"
  "/var/tmp"
)
mountpoint_noexec_list=(
  "/tmp"
  "/var/log"
  "/var/log/audit"
  "/var/tmp"
)
mountopts=(
  "nodev"
  "nosuid"
)
for mountpoint in "${mountpoint_list[@]}"; do
  mountpoint_regex="$(printf "/dev/.*[[:space:]]%s[[:space:]]" "$mountpoint")"
  for mountopt in "${mountopts[@]}"; do
    if [ "$(grep "$mountpoint_regex" /etc/fstab | grep -c "$mountopt")" -eq 0 ]; then
      previous_mount_opts=$(grep "$mountpoint_regex" /etc/fstab | awk '{print $4}')
      sudo sed -i "s|\(${mountpoint_regex}.*${previous_mount_opts}\)|\1,$mountopt|" /etc/fstab
    fi
  done
done
for mountpoint in "${mountpoint_noexec_list[@]}"; do
  mountpoint_regex="$(printf "/dev/.*[[:space:]]%s[[:space:]]" "$mountpoint")"
  if [ "$(grep "$mountpoint_regex" /etc/fstab | grep -c "noexec")" -eq 0 ]; then
    previous_mount_opts=$(grep "$mountpoint_regex" /etc/fstab | awk '{print $4}')
    sudo sed -i "s|\(${mountpoint_regex}.*${previous_mount_opts}\)|\1,noexec|" /etc/fstab
  fi
done

rule_name="Disable Apport Service"
current_task "$rule_name"
sudo systemctl mask --now apport.service

rule_name="Disable Core Dumps for All Users"
current_task "$rule_name"
SECURITY_LIMITS_FILE="/etc/security/limits.conf"
if grep -qE '^\s*\*\s+hard\s+core' $SECURITY_LIMITS_FILE; then
  sudo sed -ri 's/(hard\s+core\s+)[[:digit:]]+/\1 0/' $SECURITY_LIMITS_FILE
else
  echo "*     hard   core    0" | sudo tee -a $SECURITY_LIMITS_FILE
fi

rule_name="Verify Permissions (0700): cron.d, cron.daily, cron.hourly, cron.monthly, cron.weekly"
current_task "$rule_name"
var_paths=(
  "/etc/cron.d"
  "/etc/cron.daily"
  "/etc/cron.hourly"
  "/etc/cron.monthly"
  "/etc/cron.weekly"
)
for path in "${var_paths[@]}"; do
  sudo find -H "${path}" -maxdepth 1 -perm /u+s,g+xwrs,o+xwrt -type d -exec chmod u-s,g-xwrs,o-xwrt {} \;
done

rule_name="Verify Permissions (0600): /etc/crontab"
current_task "$rule_name"
sudo chmod u-xs,g-xwrs,o-xwrt /etc/crontab

rule_name="Disable Postfix Network Listening"
current_task "$rule_name"
sudo sed -i 's/inet_interfaces = all/inet_interfaces = loopback-only/' /etc/postfix/main.cf

rule_name="The Chrony package is installed"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y chrony

rule_name="Enable the NTP Daemon (chrony)"
current_task "$rule_name"
sudo systemctl enable chrony.service

rule_name="Configure time servers for the NTP Daemon (chrony)"
current_task "$rule_name"
time_servers=(
  "time.nist.gov"
  "0.us.pool.ntp.org"
  "1.us.pool.ntp.org"
  "2.us.pool.ntp.org"
  "3.us.pool.ntp.org"
)
sudo sed -i 's/^pool/#pool/' /etc/chrony/chrony.conf
for time_server in "${time_servers[@]}"; do
  echo "server $time_server iburst" | sudo tee -a /etc/chrony/chrony.conf
done

rule_name="Remove telnet Clients"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y telnet

rule_name="Remove rsync Package"
current_task "$rule_name"
sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y rsync

rule_name="Configure SSH Server"
current_task "$rule_name"
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
SSH_CONFIG_FILE_BACKUP="/etc/ssh/sshd_config.bak"
sshd_options=(
  "AllowTcpForwarding no"
  "Banner /etc/issue.net"
  "Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc"
  "ClientAliveCountMax 3"
  "ClientAliveInterval 300"
  "HostbasedAuthentication no"
  "IgnoreRhosts yes"
  "LoginGraceTime 60"
  "LogLevel VERBOSE"
  "MACs hmac-sha2-512,hmac-sha2-256,hmac-sha1"
  "MaxAuthTries 4"
  "MaxSessions 10"
  "MaxStartups 10:30:60"
  "PasswordAuthentication yes"
  "PermitEmptyPasswords no"
  "PermitRootLogin no"
  "PermitUserEnvironment no"
  "PubkeyAuthentication yes"
  "X11Forwarding no"
)
for sshd_option in "${sshd_options[@]}"; do
  sshd_option_base=$(echo "${sshd_option}" | cut -d ' ' -f 1)
  sudo LC_ALL=C sed -i "/^\s*${sshd_option_base}\s\+/Id" "${SSH_CONFIG_FILE}"
  sudo cp "${SSH_CONFIG_FILE}" "${SSH_CONFIG_FILE_BACKUP}"
  line_number="$(sudo LC_ALL=C grep -n "^${sshd_option_base}" "${SSH_CONFIG_FILE_BACKUP}" | LC_ALL=C sed 's/:.*//g')"
  if [ -z "${line_number}" ]; then
    printf '%s\n' "${sshd_option}" | sudo tee -a "${SSH_CONFIG_FILE}"
  else
    head -n "$(( line_number - 1 ))" "${SSH_CONFIG_FILE_BACKUP}" | sudo tee "${SSH_CONFIG_FILE}"
    printf '%s\n' "${sshd_option}" | sudo tee -a "${SSH_CONFIG_FILE}"
    tail -n "$(( line_number ))" "${SSH_CONFIG_FILE_BACKUP}" | sudo tee -a "${SSH_CONFIG_FILE}}"
  fi
  sudo rm "${SSH_CONFIG_FILE_BACKUP}"
done

rule_name="Verify Permissions on SSH Server Config File"
current_task "$rule_name"
sudo chmod 0600 /etc/ssh/sshd_config

rule_name="Configure AIDE to Verify the Audit Tools"
current_task "$rule_name"
audit_tools=(
  "/usr/sbin/auditctl"
  "/usr/sbin/auditd"
  "/usr/sbin/ausearch"
  "/usr/sbin/aureport"
  "/usr/sbin/autrace"
  "/usr/sbin/augenrules"
  "/usr/sbin/audispd"
)
for audit_tool in "${audit_tools[@]}"; do
  if grep -i "${audit_tool}" /etc/aide/aide.conf; then
    sudo sed -i "s#.*${audit_tool}.*#${audit_tool} p+i+n+u+g+s+b+acl+xattrs+sha512#" /etc/aide/aide.conf
  else
    echo "${audit_tool} p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a /etc/aide/aide.conf
  fi
done

rule_name="Build and Test AIDE Database"
AIDE_CONFIG=/etc/aide/aide.conf
AIDE_DB=/var/lib/aide/aide.db
if ! grep -q '^database_in=file:' ${AIDE_CONFIG}; then
  echo "database_in=file:${AIDE_DB}" | sudo tee -a ${AIDE_CONFIG}
else
  sudo sed -i "s|^database_in=file:.*$|database_in=file:${AIDE_DB}|" ${AIDE_CONFIG}
fi
if ! grep -q '^database_out=file:' ${AIDE_CONFIG}; then
  echo "database_out=file:${AIDE_DB}\.new" | sudo tee -a ${AIDE_CONFIG}
else
  sudo sed -i "s|^database_out=file:.*$|database_out=file:${AIDE_DB}\.new|" ${AIDE_CONFIG}
fi
sudo /usr/sbin/aideinit -y -f
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

echo ">>> Hardening script complete!"
