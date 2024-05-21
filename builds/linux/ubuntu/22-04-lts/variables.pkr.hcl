/*
  Ubuntu Server 22.04 LTS variables using the Packer Builder for Proxmox.
*/

//  BLOCK: variable
//  Defines the input variables.

// Virtual Machine Settings

variable "remove_cdrom" {
  type          = bool
  description   = "Remove the virtual CD-ROM(s)."
  default       = true
}

variable "vm_name" {
  type          = string
  description   = "Name of the new template to create."
}

variable "vm_cpu_cores" {
  type          = number
  description   = "The number of virtual CPUs cores per socket. (e.g. '1')"
}

variable "vm_cpu_count" {
  type          = number
  description   = "The number of virtual CPUs. (e.g. '2')"
}

variable "vm_cpu_type" {
  type          = string
  description   = "The virtual machine CPU type. (e.g. 'host')"
}

variable "vm_disk_size" {
  type          = string
  description   = "The size for the virtual disk (e.g. '60G')"
  default       = "60G"
}

variable "vm_bios_type" {
  type          = string
  description   = "The virtual machine BIOS type (e.g. 'ovmf' or 'seabios')"
  default       = "ovmf"
}

variable "vm_guest_os_keyboard" {
  type          = string
  description   = "The guest operating system keyboard input."
  default       = "us"
}

variable "vm_guest_os_language" {
  type          = string
  description   = "The guest operating system lanugage."
  default       = "en_US"
}

variable "vm_guest_os_timezone" {
  type          = string
  description   = "The guest operating system timezone."
  default       = "UTC"
}

variable "vm_guest_os_type" {
  type          = string
  description   = "The guest operating system type. (e.g. 'l26' for Linux 2.6+)"
}

variable "vm_mem_size" {
  type          = number
  description   = "The size for the virtual memory in MB. (e.g. '2048')"
}

variable "vm_network_model" {
  type          = string
  description   = "The virtual network adapter type. (e.g. 'e1000', 'vmxnet3', or 'virtio')"
  default       = "virtio"
}

variable "vm_scsi_controller" {
  type          = string
  description   = "The virtual SCSI controller type. (e.g. 'virtio-scsi-single')"
  default       = "virtio-scsi-single"
}

// VM Guest Partition Sizes
variable "vm_guest_part_audit" {
  type          = number
  description   = "Size of the /var/log/audit partition in MB."
}

variable "vm_guest_part_boot" {
  type          = number
  description   = "Size of the /boot partition in MB."
}

variable "vm_guest_part_efi" {
  type          = number
  description   = "Size of the /boot/efi partition in MB."
}

variable "vm_guest_part_home" {
  type          = number
  description   = "Size of the /home partition in MB."
}

variable "vm_guest_part_log" {
  type          = number
  description   = "Size of the /var/log partition in MB."
}

variable "vm_guest_part_root" {
  type          = number
  description   = "Size of the /var partition in MB. Set to 0 to consume all remaining free space."
  default       = 0
}

variable "vm_guest_part_swap" {
  type          = number
  description   = "Size of the swap partition in MB."
}

variable "vm_guest_part_tmp" {
  type          = number
  description   = "Size of the /tmp partition in MB."
}

variable "vm_guest_part_var" {
  type          = number
  description   = "Size of the /var partition in MB."
}

variable "vm_guest_part_vartmp" {
  type          = number
  description   = "Size of the /var/tmp partition in MB."
}

// Removable Media Settings

variable "cd_label" {
  type          = string
  description   = "CD Label"
  default       = "cidata"
}

variable "iso_checksum_type" {
  type          = string
  description   = "The checksum algorithm used by the vendor. (e.g. 'sha256')"
}

variable "iso_checksum_value" {
  type          = string
  description   = "The checksum value provided by the vendor."
}

variable "iso_file" {
  type          = string
  description   = "The file name of the ISO image used by the vendor. (e.g. 'ubuntu-<version>-live-server-amd64.iso')"
}

variable "iso_url" {
  type          = string
  description   = "The URL source of the ISO image. (e.g. 'https://mirror.example.com/.../os.iso')"
}

// Boot Settings

variable "vm_boot_command" {
  type          = list(string)
  description   = "The virtual machine boot command."
  default       = []
}

variable "vm_boot_wait" {
  type          = string
  description   = "The time to wait before boot."
}

// Communicator Settings and Credentials

variable "build_remove_keys" {
  type          = bool
  description   = "If true, Packer will attempt to remove its temporary key from ~/.ssh/authorized_keys and /root/.ssh/authorized_keys"
  default       = true
}

variable "communicator_insecure" {
  type          = bool
  description   = "If true, do not check server certificate chain and host name"
  default       = true
}

variable "communicator_port" {
  type          = string
  description   = "The port for the communicator protocol."
}

variable "communicator_ssl" {
  type          = bool
  description   = "If true, use SSL"
  default       = true
}

variable "communicator_timeout" {
  type          = string
  description   = "The timeout for the communicator protocol."
}

// Provisioner Settings

variable "cloud_init_apt_packages" {
  type          = list(string)
  description   = "A list of apt packages to install during the subiquity cloud-init installer."
  default       = []
}

variable "cloud_init_apt_mirror" {
  type          = string
  description   = "Sets the default apt mirror during the subiquity cloud-init installer."
  default       = ""
}

variable "post_install_scripts" {
  type          = list(string)
  description   = "A list of scripts and their relative paths to transfer and run after OS install."
  default       = []
}

variable "pre_final_scripts" {
  type          = list(string)
  description   = "A list of scripts and their relative paths to transfer and run before finalization."
  default       = []
}
