# Packer

Build Linux server templates on Proxmox with Packer

### Currently supported builds:
#### Linux
- [Ubuntu Server 22.04 LTS](builds/linux/ubuntu/22-04-lts/) (`ubuntu2204`)
- [Ubuntu Server 24.04 LTS](builds/linux/ubuntu/24-04-lts/) (`ubuntu2404`)

To run a build locally, you'll need to first export a few Vault-related environment variables:
```shell
export VAULT_ADDR="https://vault.lab.example.com/"      # your Vault server
export VAULT_NAMESPACE="example/LAB"                    # (only if using namespaces in Vault Enterprise)
export VAULT_TOKEN="hvs.abcdefg"                        # insert a Vault token ID
```

Alternatively, put those same `export` commands into a script called `vault-env.sh`.

Then just run `./build.sh [BUILD]`, where `[BUILD]` is one of the descriptors listed above. For example, to build Ubuntu 22.04:
```shell
./build.sh ubuntu2204
```