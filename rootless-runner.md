# Self-hosted Runner with rootless Docker

Ubuntu 22.04

Create GitHub user
```shell
sudo useradd -m -G sudo -s $(which bash) github
sudo passwd github
```

Log in as `github`

Install prereqs
```shell
sudo apt install uidmap
```

Install Docker
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

Install rootless
```shell
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock

dockerd-rootless-setuptool.sh install

systemctl --user start docker
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
```

Remove `github` from sudo group
```shell
sudo userdel github sudo
```

Then follow GitHub's instructions on setting up the runner package.