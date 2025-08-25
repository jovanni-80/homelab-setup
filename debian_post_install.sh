#!/bin/bash
# refer to: https://wiki.debian.org/DontBreakDebian
# when deciding what to install/uninstall
# Debian post-installation script to be run on Jos homeserver after fresh debian install
# This script installs necessary packages, and additionally
# Note: sudo should be setup before this ideally
#

error_prefix='\033[41m ERROR \033[0m'
info_prefix='\033[42m INFO  \033[0m'
warn_prefix='\033[43m WARN  \033[0m'

set expected_user="whitakeradm"
set expected_hostname="homelab"
set WIREGUARD_PORT="51820"

# script should not be executable by non-sudo user
if [[ "$USER" != "$expected_user" ]]; then
  echo -e "$error_prefix User $expected_user needs to run this script with sudo!"
  exit 1
elif [ "$EUID" -ne 0 ]; then
  echo -e "$error_prefix Please run with 'sudo'"
  echo "If you have not, first run: "
  echo "$ sudo apt update && sudo apt install sudo -y"
  echo "$ su"
  echo "(as root)$ sudo adduser $expected_user sudo"
  exit 1
fi

# PACKAGE INSTALLATIONS:
echo -e "$info_prefix Installing apt packages"
sleep 1

sudo apt update -y
sudo apt install timeshift -y
sudo apt install openssh-server -y
sudo apt install neovim vim -y
sudo apt install ufw -y
sudo apt install git -y
sudo apt install tmux -y
sudo apt install build-essential -y
sudo apt install unzip -y
sudo apt install fish -y
sudo apt install zoxide -y
sudo apt install fd-find -y
sudo apt install ripgrep -y
sudo apt install btop -y
sudo apt install curl -y
sudo apt install network-manager -y
sudo apt install gdb -y
sudo apt install nodejs -y
sudo apt install npm -y
sudo apt install python3 -y

echo -e "$info_prefix Adding Docker GPG key and installing"
sleep 1
# docker install
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world

# @TODO: add dockerfile emplacement gitea, wireguard, dns/pihole maybe, minecraft server
#

echo -e "$info_prefix Installing nerdfont"
sleep 1
# install nerdfonts - don't do this as root probably?
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip &&
  cd ~/.local/share/fonts &&
  unzip JetBrainsMono.zip &&
  rm JetBrainsMono.zip &&
  fc-cache -fv

echo -e "$info_prefix installing oh-my-fish"
sleep 1
# install oh my fish - also don't do this as root probably
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

echo -e "$info_prefix installing uv"
sleep 1
# install 'uv' for python projects
curl -LsSf https://astral.sh/uv/install.sh | sh

echo -e "$info_prefix configuring timeshift to backup weekly"
sleep 1
# configure timeshift backups, sudo
# @FIXME: /etc/timeshift/timeshift.json not found
sed -i 's/"schedule_weekly": false/"schedule_weekly": true/' /etc/timeshift/timeshift.json

echo -e "$info_prefix configuring uncomplicated firewall"
sleep 1

# configure (uncomplicated) firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ssh

sudo ufw allow $WIREGUARD_PORT/udp

sudo echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
# If using IPv6:
sudo echo 'net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# need to make sure this exists in /etc/ufw/before.rules
# NOTE: replace 'wg0' with wireguard interface name if it's different:

# @TODO: echo this into /etc/ufw/before.rules
## START WIREGUARD RULES
## NAT table rules
#*nat
#:POSTROUTING ACCEPT [0:0]
## Allow traffic from WireGuard clients to the internet
#-A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
#COMMIT
## END WIREGUARD RULES
## Allow forwarding for WireGuard
#-A ufw-before-forward -i wg0 -j ACCEPT
#-A ufw-before-forward -o wg0 -j ACCEPT

sudo ufw enable

echo -e "$info_prefix Configuring fish"
sleep 1
# configure some aliases
echo 'alias reboot "/sbin/reboot"' > ~/.config/fish/config.fish
echo 'alias src "source /home/$expected_user/.config/fish/config.fish"' > ~/.config/fish/config.fish
echo 'alias f "nvim /home/$expected_user/.config/fish/config.fish"' > ~/.config/fish/config.fish

# @TODO: add fish configuration emplacement

# set fish as default shell
chsh -s $(which fish)

# @TODO: add tmux configuration emplacement
