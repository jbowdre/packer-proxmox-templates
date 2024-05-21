/*
  Ubuntu Server 24.04 LTS  variables used by the Packer Builder for Proxmox.
*/

// Guest Operating System Metadata
vm_guest_os_keyboard    = "us"
vm_guest_os_language    = "en_US"
vm_guest_os_timezone    = "America/Chicago"

// Virtual Machine Guest Operating System Setting
vm_guest_os_type        = "l26"

//Virtual Machine Guest Partition Sizes (in MB)
vm_guest_part_audit     = 4096
vm_guest_part_boot      = 512
vm_guest_part_efi       = 512
vm_guest_part_home      = 8192
vm_guest_part_log       = 4096
vm_guest_part_root      = 0
vm_guest_part_swap      = 1024
vm_guest_part_tmp       = 4096
vm_guest_part_var       = 8192
vm_guest_part_vartmp    = 1024

// Virtual Machine Hardware Settings
vm_cpu_cores            = 1
vm_cpu_count            = 2
vm_cpu_type             = "host"
vm_disk_size            = "60G"
vm_bios_type            = "ovmf"
vm_mem_size             = 2048
vm_name                 = "Ubuntu2404"
vm_network_card         = "virtio"
vm_scsi_controller      = "virtio-scsi-single"

// Removable Media Settings
iso_checksum_type       = "sha256"
iso_checksum_value      = "8762f7e74e4d64d72fceb5f70682e6b069932deedb4949c6975d0f0fe0a91be3"
iso_file                = "ubuntu-24.04-live-server-amd64.iso"
iso_url                 = "https://releases.ubuntu.com/noble/ubuntu-24.04-live-server-amd64.iso"
remove_cdrom            = true

// Boot Settings
boot_key_interval       = "250ms"
vm_boot_wait            = "4s"
vm_boot_command = [
    "<esc><wait>c",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
    "<enter><wait5s>",
    "initrd /casper/initrd",
    "<enter><wait5s>",
    "boot",
    "<enter>"
  ]

// Communicator Settings
communicator_port       = 22
communicator_timeout    = "25m"

// Provisioner Settings
cloud_init_apt_packages = [
  "cloud-guest-utils",
  "net-tools",
  "perl",
  "qemu-guest-agent",
  "vim",
  "wget"
]

post_install_scripts = [
  "scripts/linux/wait-for-cloud-init.sh",
  "scripts/linux/cleanup-subiquity.sh",
  "scripts/linux/install-ca-certs.sh",
  "scripts/linux/disable-multipathd.sh",
  "scripts/linux/prune-motd.sh",
  "scripts/linux/persist-cloud-init-net.sh",
  "scripts/linux/configure-pam_mkhomedir.sh",
  "scripts/linux/update-packages.sh"
]

pre_final_scripts = [
  "scripts/linux/cleanup-cloud-init.sh",
  "scripts/linux/cleanup-packages.sh",
  "builds/linux/ubuntu/24-04-lts/hardening.sh",
  "scripts/linux/zero-disk.sh",
  "scripts/linux/generalize.sh"
]
