#cloud-config
autoinstall:
%{ if length( apt_mirror ) > 0 ~}
  apt:
    primary:
      - arches: [default]
        uri: "${ apt_mirror }"
%{ endif ~}
  early-commands:
    - sudo systemctl stop ssh
  identity:
    hostname: ${ vm_guest_os_hostname }
    password: '${ build_password_hash }'
    username: ${ build_username }
  keyboard:
    layout: ${ vm_guest_os_keyboard }
  late-commands:
    - echo "${ build_username } ALL=(ALL) NOPASSWD:ALL" > /target/etc/sudoers.d/${ build_username }
    - curtin in-target --target=/target -- chmod 400 /etc/sudoers.d/${ build_username }
  locale: ${ vm_guest_os_language }
  network:
    network:
      version: 2
      ethernets:
        mainif:
          match:
            name: e*
          critical: true
          dhcp4: true
          dhcp-identifier: mac
%{ if length( apt_packages ) > 0 ~}
  packages:
%{ for package in apt_packages ~}
    - ${ package }
%{ endfor ~}
%{ endif ~}
  ssh:
    install-server: true
    allow-pw: true
%{ if length( ssh_keys ) > 0 ~}
    authorized-keys:
%{ for ssh_key in ssh_keys ~}
      - ${ ssh_key }
%{ endfor ~}
%{ endif ~}
  storage:
    config:
      - ptable: gpt
        path: /dev/sda
        wipe: superblock
        type: disk
        id: disk-sda
      - device: disk-sda
        size: ${ vm_guest_part_efi }M
        wipe: superblock
        flag: boot
        number: 1
        grub_device: true
        type: partition
        id: partition-0
      - fstype: fat32
        volume: partition-0
        label: EFIFS
        type: format
        id: format-efi
      - device: disk-sda
        size: ${ vm_guest_part_boot }M
        wipe: superblock
        number: 2
        type: partition
        id: partition-1
      - fstype: xfs
        volume: partition-1
        label: BOOTFS
        type: format
        id: format-boot
      - device: disk-sda
        size: -1
        wipe: superblock
        number: 3
        type: partition
        id: partition-2
      - name: sysvg
        devices:
          - partition-2
        type: lvm_volgroup
        id: lvm_volgroup-0
      - name: home
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_home}M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-home
      - fstype: xfs
        volume: lvm_partition-home
        type: format
        label: HOMEFS
        id: format-home
      - name: tmp
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_tmp }M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-tmp
      - fstype: xfs
        volume: lvm_partition-tmp
        type: format
        label: TMPFS
        id: format-tmp
      - name: var
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_var }M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-var
      - fstype: xfs
        volume: lvm_partition-var
        type: format
        label: VARFS
        id: format-var
      - name: log
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_log }M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-log
      - fstype: xfs
        volume: lvm_partition-log
        type: format
        label: LOGFS
        id: format-log
      - name: audit
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_audit }M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-audit
      - fstype: xfs
        volume: lvm_partition-audit
        type: format
        label: AUDITFS
        id: format-audit
      - name: vartmp
        volgroup: lvm_volgroup-0
        size: ${ vm_guest_part_vartmp }M
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-vartmp
      - fstype: xfs
        volume: lvm_partition-vartmp
        type: format
        label: VARTMPFS
        id: format-vartmp
      - name: root
        volgroup: lvm_volgroup-0
%{ if vm_guest_part_root == 0 ~}
        size: -1
%{ else ~}
        size: ${ vm_guest_part_root }M
%{ endif ~}
        wipe: superblock
        type: lvm_partition
        id: lvm_partition-root
      - fstype: xfs
        volume: lvm_partition-root
        type: format
        label: ROOTFS
        id: format-root
      - path: /
        device: format-root
        type: mount
        id: mount-root
      - path: /boot
        device: format-boot
        type: mount
        id: mount-boot
      - path: /boot/efi
        device: format-efi
        type: mount
        id: mount-efi
      - path: /home
        device: format-home
        type: mount
        id: mount-home
      - path: /tmp
        device: format-tmp
        type: mount
        id: mount-tmp
      - path: /var
        device: format-var
        type: mount
        id: mount-var
      - path: /var/log
        device: format-log
        type: mount
        id: mount-log
      - path: /var/log/audit
        device: format-audit
        type: mount
        id: mount-audit
      - path: /var/tmp
        device: format-vartmp
        type: mount
        id: mount-vartmp
  user-data:
    package_upgrade: true
    disable_root: true
    timezone: ${ vm_guest_os_timezone }
  version: 1
