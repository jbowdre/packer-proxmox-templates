# Self-hosted Runner with rootless Docker

These are the steps I used to configure an Ubuntu 22.04 VM to function as a GitHub Runner with rootless Docker.

1. Create GitHub user
```shell
sudo useradd -m -G sudo -s $(which bash) github
sudo passwd github
```

2. Log in as `github`

3. Install `uidmap`
```shell
sudo apt install uidmap
```

4. Install Docker
```shell
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

5. Enable rootless Docker
```shell
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock

dockerd-rootless-setuptool.sh install

systemctl --user start docker
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
```

6. Follow [GitHub's instructions](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners) on installing the runner package.

7. Configure it to start at boot
```shell
sudo ./svc.sh install
```

8. Remove `github` from sudo group as it won't need any further elevation
```shell
sudo deluser github sudo
```

9. Reboot for good measure. The runner should show as "idle" on the GitHub side.