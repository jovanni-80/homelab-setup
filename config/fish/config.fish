alias fd "fdfind"
alias get_vm_ip "sudo virsh net-dhcp-leases default"
alias e "nvim /home/$USER/.config/fish/config.fish"
alias src "source /home/$USER/.config/fish/config.fish"
alias l "lsd"
alias ll "lsd -lla"

# kawasaki theme options
set -g theme_display_group no
set -g theme_display_rw no
set -g theme_display_time yes

# kawasaki color overrides
set -g theme_color_host 00d9ff
set -g theme_color_user green
