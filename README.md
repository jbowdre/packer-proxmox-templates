# Packer

Build Linux server templates on Proxmox with Packer ([proxmox-iso](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso))

### Requirements
- [Packer](https://developer.hashicorp.com/packer/install) (duh)
- [Vault](https://developer.hashicorp.com/vault/install) (for storing environment secrets)

#### Vault layout
To minimize the effort required to tailor deployments to your environment, this Packer setup assumes that you're storing all of your environment-specific information (not just sensitive credentials!) in Vault. You shouldn't really need to modify any of the variables stored in the `.hcl` files to get a functional build.

You should use a `kv_v2` secrets engine mounted at `packer`. It should contain two secrets with the following key/value pairs:

##### `proxmox` contains values related to the Proxmox environment:
| Key                   | Example value                                 | Description                                                                                                              |
|-----------------------|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `api_url`             | `https://proxmox1.example.com:8006/api2/json` | URL to the Proxmox API                                                                                                   |
| `insecure_connection` | `true`                                        | set to `false` if your Proxmox host has a valid certificate                                                              |
| `iso_path`            | `local:iso`                                   | path for (existing) ISO storage                                                                                          |
| `iso_storage_pool`    | `local`                                       | pool for storing created/uploaded ISOs                                                                                   |
| `network_bridge`      | `vmbr0`                                       | bridge the VM's NIC will be attached to                                                                                  |
| `node`                | `proxmox1`                                    | node name where the VM will be built                                                                                     |
| `token_id`            | `packer@pve!packer`                           | ID for an [API token](https://pve.proxmox.com/wiki/User_Management#pveum_tokens), in the form `USERNAME@REALM!TOKENNAME` |
| `token_secret`        | `3fc69f[...]d2077eda`                         | secret key for the token                                                                                                 |
| `vm_storage_pool`     | `zfs-pool`                                    | storage pool where the VM will be created                                                                                |

##### `linux` holds values for the created VM template(s)
| Key                   | Example value                                             | Description                                                                                     |
|-----------------------|-----------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| `bootloader_password` | `bootplease`                                              | Grub bootloader password to set                                                                 |
| `password_hash`       | `$6$rounds=4096$NltiNLKi[...]a7Shax41`                    | hash of the build account's password (example generated with `mkpasswd -m sha512crypt -R 4096`) |
| `public_key`          | `ssh-ed25519 AAAAC3NzaC1[...]lXLUI5I40 admin@example.com` | SSH public key for the user                                                                     |
| `username`            | `admin`                                                   | build account username                                                                          |

### Currently supported builds
#### Linux
- [Ubuntu Server 22.04 LTS](builds/linux/ubuntu/22-04-lts/) (`ubuntu2204`)
- [Ubuntu Server 24.04 LTS](builds/linux/ubuntu/24-04-lts/) (`ubuntu2404`)

To run a build locally, you'll need to first export a few Vault-related environment variables:
```shell
export VAULT_ADDR="https://vault.example.com/"    # your Vault server
export VAULT_NAMESPACE=""                         # (only need if using namespaces in Vault Enterprise)
export VAULT_TOKEN="hvs.abcdefg"                  # insert a Vault token ID
```

Alternatively, put those same `export` commands into a script called `vault-env.sh` which will be sourced automatically as needed.

Then just run `./build.sh [BUILD]`, where `[BUILD]` is one of the descriptors listed above. For example, to build Ubuntu 22.04:
```shell
./build.sh ubuntu2204
```