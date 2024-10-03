/*
  Ubuntu Server 24.04 LTS template using the Packer Builder for Proxmox.
*/

//  BLOCK: packer
//  The Packer configuration.

packer {
  required_version              = "= 1.10.3"
  required_plugins {
    proxmox = {
      version                   = "= 1.1.8"
      source                    = "github.com/hashicorp/proxmox"
    }
    ssh-key = {
      version                   = "= 1.0.3"
      source                    = "github.com/ivoronin/sshkey"
    }
  }
}

//  BLOCK: locals
//  Defines the local variables.

// Dynamically-generated SSH key
data "sshkey" "install" {
  type                          = "ed25519"
  name                          = "packer_key"
}

////////////////// Vault Locals //////////////////
// To retrieve secrets from Vault, the following environment variables MUST be defined:
//  - VAULT_ADDR        : base URL of the Vault server ('https://vault.example.com/')
//  - VAULT_NAMESPACE   : namespace path to where the secrets live ('organization/sub-org')
//  - VAULT_TOKEN       : token ID with rights to read/list
//
// Syntax for the vault() call:
//    vault("SECRET_ENGINE/data/SECRET_NAME", "KEY")
//
// Standard configuration values:
locals {
  build_public_key              = vault("packer/data/linux",      "public_key")           // SSH public key for the default admin account
  build_username                = vault("packer/data/linux",      "username")             // Username for the default admin account
  proxmox_url                   = vault("packer/data/proxmox",    "api_url")              // Proxmox API URL
  proxmox_insecure_connection   = vault("packer/data/proxmox",    "insecure_connection")  // Allow insecure connections to Proxmox
  proxmox_node                  = vault("packer/data/proxmox",    "node")                 // Proxmox node to use for the build
  proxmox_token_id              = vault("packer/data/proxmox",    "token_id")             // Proxmox token ID
  proxmox_iso_path              = vault("packer/data/proxmox",    "iso_path")             // Path to the ISO storage
  proxmox_vm_storage_pool       = vault("packer/data/proxmox",    "vm_storage_pool")         // Proxmox storage pool to use for the build
  proxmox_iso_storage_pool      = vault("packer/data/proxmox",    "iso_storage_pool")     // Proxmox storage pool to use for the ISO
  proxmox_network_bridge        = vault("packer/data/proxmox",    "network_bridge")       // Proxmox network bridge to use for the build
}
// Sensitive values:
local "bootloader_password"{
  expression                    = vault("packer/data/linux",            "bootloader_password")  // Password to set for the bootloader
  sensitive                     = true
}
local "build_password_hash" {
  expression                    = vault("packer/data/linux",            "password_hash")             // Password hash for the default admin account
  sensitive                     = true
}
local "proxmox_token_secret" {
  expression                    = vault("packer/data/proxmox",          "token_secret")             // Token secret for authenticating to Proxmox
  sensitive                     = true
}

////////////////// End Vault Locals //////////////////

locals {
  build_date                    = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_description             = "Ubuntu Server 24.04 LTS template\nBuild date: ${local.build_date}\nBuild tool: ${local.build_tool}"
  build_tool                    = "HashiCorp Packer ${packer.version}"
  iso_checksum                  = "${var.iso_checksum_type}:${var.iso_checksum_value}"
  iso_path                      = "${local.proxmox_iso_path}/${var.iso_file}"
  ssh_private_key_file          = data.sshkey.install.private_key_path
  ssh_public_key                = data.sshkey.install.public_key
  data_source_content = {
    "/meta-data"                = file("${abspath(path.root)}/data/meta-data")
    "/user-data"                = templatefile("${abspath(path.root)}/data/user-data.pkrtpl.hcl", {
      apt_mirror                = var.cloud_init_apt_mirror
      apt_packages              = var.cloud_init_apt_packages
      build_password_hash       = local.build_password_hash
      build_username            = local.build_username
      ssh_keys                  = concat([local.ssh_public_key], [local.build_public_key])
      vm_guest_os_hostname      = var.vm_name
      vm_guest_os_keyboard      = var.vm_guest_os_keyboard
      vm_guest_os_language      = var.vm_guest_os_language
      vm_guest_os_timezone      = var.vm_guest_os_timezone
      vm_guest_part_audit       = var.vm_guest_part_audit
      vm_guest_part_boot        = var.vm_guest_part_boot
      vm_guest_part_efi         = var.vm_guest_part_efi
      vm_guest_part_home        = var.vm_guest_part_home
      vm_guest_part_log         = var.vm_guest_part_log
      vm_guest_part_root        = var.vm_guest_part_root
      vm_guest_part_swap        = var.vm_guest_part_swap
      vm_guest_part_tmp         = var.vm_guest_part_tmp
      vm_guest_part_var         = var.vm_guest_part_var
      vm_guest_part_vartmp      = var.vm_guest_part_vartmp
    })
  }
}

//  BLOCK: source
//  Defines the builder configuration blocks.

source "proxmox-iso" "linux-server" {

  // Proxmox Endpoint Settings and Credentials
  insecure_skip_tls_verify      = local.proxmox_insecure_connection
  proxmox_url                   = local.proxmox_url
  token                         = local.proxmox_token_secret
  username                      = local.proxmox_token_id

  // Node Settings
  node                          = local.proxmox_node

  // Virtual Machine Settings
  bios                          = "ovmf"
  cores                         = var.vm_cpu_cores
  cpu_type                      = var.vm_cpu_type
  memory                        = var.vm_mem_size
  os                            = var.vm_guest_os_type
  scsi_controller               = var.vm_scsi_controller
  sockets                       = var.vm_cpu_count
  template_description          = local.build_description
  template_name                 = var.vm_name
  vm_name                       = var.vm_name
  disks {
    disk_size                   = var.vm_disk_size
    storage_pool                = local.proxmox_vm_storage_pool
  }
  efi_config {
    efi_storage_pool            = local.proxmox_vm_storage_pool
    efi_type                    = "4m"
    pre_enrolled_keys           = true
  }
  network_adapters {
    bridge                      = local.proxmox_network_bridge
    model                       = var.vm_network_model
  }

  // Removable Media Settings
  additional_iso_files {
    cd_content                  = local.data_source_content
    cd_label                    = var.cd_label
    iso_storage_pool            = local.proxmox_iso_storage_pool
    unmount                     = var.remove_cdrom
  }
  iso_checksum                  = local.iso_checksum
  // iso_file                      = local.iso_path
  iso_url                       = var.iso_url
  iso_download_pve              = true
  iso_storage_pool              = local.proxmox_iso_storage_pool
  unmount_iso                   = var.remove_cdrom


  // Boot and Provisioning Settings
  boot_command                  = var.vm_boot_command
  boot_wait                     = var.vm_boot_wait

  // Communicator Settings and Credentials
  communicator                  = "ssh"
  ssh_clear_authorized_keys     = var.build_remove_keys
  ssh_port                      = var.communicator_port
  ssh_private_key_file          = local.ssh_private_key_file
  ssh_timeout                   = var.communicator_timeout
  ssh_username                  = local.build_username

}

//  BLOCK: build
//  Defines the builders to run, provisioners, and post-processors.

build {
  sources = [
    "source.proxmox-iso.linux-server"
  ]

  provisioner "file" {
    source                      = "certs"
    destination                 = "/tmp"
  }

  provisioner "file" {
    source                      = "scripts/linux/join-domain.sh"
    destination                 = "/home/${local.build_username}/join-domain.sh"
  }

  provisioner "shell" {
    execute_command             = "bash {{ .Path }}"
    expect_disconnect           = true
    scripts                     = formatlist("${path.cwd}/%s", var.post_install_scripts)
  }

  provisioner "shell" {
    env                         = {
      "BOOTLOADER_PASSWORD"     = local.bootloader_password
    }
    execute_command             = "{{ .Vars }} bash {{ .Path }}"
    expect_disconnect           = true
    pause_before                = "30s"
    scripts                     = formatlist("${path.cwd}/%s", var.pre_final_scripts)
  }
}
