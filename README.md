# Packer

> [!NOTE]
> This project has [moved](https://git.vim.wtf/wq/packer-proxmox-templates).

Build Linux server templates on Proxmox with Packer ([proxmox-iso](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso))

### Requirements
- [Packer](https://developer.hashicorp.com/packer/install) (duh)
- [Vault](https://developer.hashicorp.com/vault/install) (for storing environment secrets)


### Blog posts
- [Building Proxmox Templates with Packer](https://runtimeterror.dev/building-proxmox-templates-packer/)
- [Automate Packer Builds with GithHub Actions](https://runtimeterror.dev/automate-packer-builds-github-actions/)

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

### Building

Currently-supported OS flavors:
- [Ubuntu Server 22.04 LTS](builds/linux/ubuntu/22-04-lts/) (`ubuntu2204`)
- [Ubuntu Server 24.04 LTS](builds/linux/ubuntu/24-04-lts/) (`ubuntu2404`)

#### Local
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

#### GitHub Actions
This repo contains a sample GitHub Actions workflow for running automated builds on a self-hosted runner configured with rootless Docker. The runner will need to have connectivity to the Vault server to be able to retrieve secrets.

> **NOTE**
> Self-hosted runners [should *only* be used on private GitHub repos](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security). You don't want a PR from a fork to trigger arbitrary code execution on your infrastructure. This public repo is where I share my code with you, but I actually run the workflows from a private repo which is an otherwise exact copy of this one.
> So if you'd like to use this code for your own automated build process, clone it locally then push it to your own *private* GitHub repo.

Okay with that disclaimer out of the way, see my notes on runner configuration [here](rootless-runner.md).
