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

### Adding docker containers:
- make dir for docker-compose to live `mkdir image_name`
- edit `docker-compose.yml` 
  - port mapping is host->container, container ports can be the same, host ports cannot
  - for autostart, set `restart: always`
  - `docker ps`, `docker compose down`, `docker logs <IMAGE_NAME>`
  - Depending on image, may need to add additional configuration files
- start container: `docker compose up -d`

### Setting up a VM to run services in
- `sudo qemu-img create -f qcow2 /var/lib/libvirt/images/<VM_NAME>.qcow2 <STORAGE_SIZE_IN_GB>G`
- setup virsh default network: `sudo virsh net-start default && sudo virsh net-autostart default`
- Run `virt-install`:
```shell
sudo virt-install \
    --name <VM_NAME> \
    --ram <RAM_IN_MB> \
    --disk path=/var/lib/libvirt/images/<VM_NAME>.qcow2,size=<SIZE_IN_GB> \
    --vcpus <NUM_CORES> \
    --os-variant debian12 \
    --network bridge=virbr0 \
    --graphics none \
    --console pty,target_type=serial \
    --location http://deb.debian.org/debian/dists/trixie/main/installer-amd64/ \
    --extra-args 'console=tty50,1115200n8 serial'
```
- Make sure X11Forwarding is enabled in `/etc/ssh/sshd_config` (might need to remove ~/.Xauthority and reconnect to re-init it)
- to get ip of vm: `sudo virsh net-dhcp-leases default`
- to connect after vm is started run `virt-viewer --connect qemu:///system services-vm`
    - annoyingly on MacOS, do this through XQuartz terminal which sets `$DISPLAY` when you ssh 
- to make vm start automatically: `virsh autostart <VM_NAME>`
- Forwarding traffic from VM **ON HOST**:
- `sudo ufw allow in on virbr0 out on eth0`
- `sudo ufw allow in on eth0 out on virbr0`
- Allowing outgoing data from services **ON VM**:
- update `/etc/ufw/before.rules` with the following initial commands:
```bash
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# ADD CUSTOM IPS TO FORWARD HERE
-A PREROUTING -p tcp --dport <FORWARDED_IP> -j DNAT --to-destination <VM_IP>:<VM_PORT>
...

-A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE

COMMIT
```
- `sudo ufw allow <port>/<protocol>`
