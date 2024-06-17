# Self-hosted Runner with rootless Docker

These are the steps I used to configure an Ubuntu 22.04 VM to function as a GitHub Runner with rootless Docker.

1. Create GitHub user
```shell
sudo useradd -m -G sudo -s $(which bash) github
sudo passwd github
```

2. Log in as `github` using `machinectl` (the rootless setup script won't work correctly if you just `sudo su - $USER)
```shell
# install systemd-container if not already installed
sudo apt install systemd-container
# login as github
sudo machinectl shell github@
```

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

6. Create a directory for the runner (or one for each runner instance if you want parallel builds), set perms, and `cd` into the parent directory
```shell
sudo mkdir -p /opt/github/runner{1..4}
sudo chown -R github:github /opt/github
cd /opt/github
```

7. Download the runner softare
```shell
curl -O -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
```

9. For each runner:
>   - Extract runner software into the runner dir
> ```shell
> tar xzf ./actions-runner-linux-x64-2.317.0.tar.gz --directory=runner1
> ```
>   -  [Add a self-hosted runner to your repository](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository) and run the prescribed config command *making sure to give each runner a unique name*
> ```shell
> cd runner1
> ./config.sh --url https://github.com/USER/REPO --token TOKEN
> ```
>   - Configure it to run as a user service
> ```shell
> sudo ./svc.sh install $(whoami)
> sudo ./svc.sh start $(whoami)
> ```

10. Remove `github` from sudo group as it won't need any further elevation
```shell
sudo deluser github sudo
```