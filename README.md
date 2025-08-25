# homelab-setup
Homelab admin user configuration and post-install setup scripts

### Post install manual commands:
- These commands setup `sudo` and `git`, so the script can be pulled from github and then ran with `sudo`
```shell
$ su
$ apt install sudo git -y
$ sudo adduser <USER> sudo
$ su <USER>
$ git clone https://github.com/jovanni-80/homelab-setup.git
```