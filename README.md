# homelab-setup
Homelab admin user configuration and post-install setup scripts

### Post install manual commands:
- These commands setup `sudo` and `git`, so the script can be pulled from github and then ran with `sudo`
```shell
$ exec su
$ apt install sudo git -y
$ sudo adduser <USER> sudo
$ exec su <USER>
$ git clone https://github.com/jovanni-80/homelab-setup.git
```

### Usage Notes
- As of right now, the finishing of installing `oh-my-fish` pops the user into a fish terminal, in order to continue the install process after this, the script runner must exit that terminal
- Additionally the script is unable to configure `timeshift` to update weekly, that `sed` command should be run manually to enable timeshift