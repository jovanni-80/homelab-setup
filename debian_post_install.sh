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

expected_user=$(whoami)
expected_hostname="$HOSTNAME"
WIREGUARD_PORT="51820"

if [ "$expected_user" == "" ]; then
  echo -e "$error_prefix Set expected_user variable in script before running."
  exit 1
elif [ "$expected_hostname" == "" ]; then
  echo -e "$error_prefix Set expected_hostname variable in script before running."
  exit 1
fi

echo -e "$info_prefix Proceeding with user: [$expected_user] and Hostname: [$expected_hostname], Ctrl+C now to cancel..."
sleep 4

# PACKAGE INSTALLATIONS:
echo -e "$info_prefix Installing apt packages"
sleep 1

sudo apt update -y
sudo apt install timeshift \
openssh-server \
neovim \
vim \
ufw \
fzf \
tmux \
build-essential \
unzip \
fish \
zoxide \
fd-find \
ripgrep \
btop \
curl \
network-manager \
gdb \
nodejs \
npm \
python3 -y

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

echo -e "$info_prefix installing uv"
sleep 1
# install 'uv' for python projects
curl -LsSf https://astral.sh/uv/install.sh | sh

echo -e "$info_prefix configuring timeshift to backup weekly"
sleep 1

# Ensure timeshift config file exists
if [ ! -f /etc/timeshift/timeshift.json ]; then
  echo -e "$warn_prefix timeshift.json not found, initializing timeshift..."
  sudo timeshift --check
fi

if [ -f /etc/timeshift/timeshift.json ]; then
  sudo sed -i 's/"schedule_weekly": false/"schedule_weekly": true/' /etc/timeshift/timeshift.json
else
  echo -e "$warn_prefix Could not configure timeshift: /etc/timeshift/timeshift.json still not found."
fi

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
chsh -s /usr/bin/fish

# @TODO: add tmux configuration emplacement

# install omf last...
# @TODO: figure out how to get oh my fish to exit itself after installing
echo -e "$info_prefix Installing oh-my-fish"
curl -L https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish -c "source /dev/stdin; exit"

sleep 3

echo -e "$info_prefix Configuring oh-my-fish"

# Install the gentoo theme
fish -c "omf install gentoo; exit" 2>/dev/null || echo -e "$info_prefix Theme installation will be attempted again..."

# Fallback: Try installing theme again if first attempt failed
sleep 2
fish -c "omf install gentoo; omf theme gentoo; exit" 2>/dev/null

echo -e "$info_prefix Finished Installation"
sleep 3
exec fish