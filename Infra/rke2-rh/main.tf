# Terraform configuration for provisioning 5 Debian 12 VMs with libvirt

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

# Configure the libvirt provider
provider "libvirt" {
  uri = "qemu:///system"
}

# Define variables for static IPs, hostnames, and admin password
variable "vm_configs" {
  type = list(object({
    hostname = string
    ip       = string
  }))
  default = [
    { hostname = "rke-master", ip = "192.168.122.101" },
    { hostname = "rke-worker1", ip = "192.168.122.102" },
    { hostname = "rke-worker2", ip = "192.168.122.103" },
    { hostname = "rke-worker3", ip = "192.168.122.104" },
    { hostname = "rke-worker4", ip = "192.168.122.105" }
  ]
}

variable "admin_password" {
  type        = string
  description = "Static password for the admin user"
  default     = "$y$j9T$8sS.1U8hzHlrkzmHQdO4L/$1bXNaA2JHBvIZQXjgbRkXSnDNFdcZhCjs2/iLbVjpb7" # Replace with your desired password
  sensitive   = true
}

# Define the storage pool
resource "libvirt_pool" "debian_pool" {
  name = "debian_pool"
  type = "dir"
  path = "/var/lib/libvirt/images/debian_pool"
}

# Define the base Debian 12 image volume
resource "libvirt_volume" "debian_base" {
  name   = "debian-12-base.qcow2"
  pool   = libvirt_pool.debian_pool.name
  source = "/opt/ISO/debian-12-generic-amd64.qcow2" # Update with actual path
  format = "qcow2"
}

# Define volumes for each VM (30 GB)
resource "libvirt_volume" "debian_disk" {
  count          = 5
  name           = "${var.vm_configs[count.index].hostname}-disk.qcow2"
  pool           = libvirt_pool.debian_pool.name
  base_volume_id = libvirt_volume.debian_base.id
  size           = 32212254720 # 30 GB
  format         = "qcow2"
}

# Define cloud-init configuration for each VM
resource "libvirt_cloudinit_disk" "cloudinit" {
  count = 5
  name  = "${var.vm_configs[count.index].hostname}-cloudinit.iso"
  pool  = libvirt_pool.debian_pool.name

  user_data = <<EOF
#cloud-config
hostname: ${var.vm_configs[count.index].hostname}
fqdn: ${var.vm_configs[count.index].hostname}.local
manage_etc_hosts: true
users:
  - name: sysadmin
    sudo: ALL=(ALL) NOPASSWD:ALL
    passwd: ${var.admin_password}
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCb6YR4KE3QWUPBDNVtWQT+VZLxIYkeiTClHjpVTLX5e7b99mXpj6Nvi8offj4cse8LpyYDCAfK111+OtFn4x2V+brf/tmnV/eBTxsDhvY3CMzvVxYayiB0qvfw8oUu0IaBXhOtHGxy79wTy1GqwihP+iKW/7yvtmplX/FpuwSxhG/KDraPu70FG+B4wX4sS2LXBmT+baBQoVFi2G2sUZUa3iaInd0ar+AHx01qlltv/zkQaK9gFSyck258YL2S1uVbZO/+anXBHreaKhoTR0YeVIJPlBuQWzppeKsbiCOftZpGWYLMZRz5Jw95rRTSc7C88Wp7KCNVa+1o7vniZXEXsqkiuTlqUiUxTdNxzCc2h3TOHRw6O/BvAusoGBs5I79/2jfUTrrRNCsIuH16qXk5dhYm16IAcIwgvHysugsOdDOrlHsWUYRh/yi8EdswExhrYg5+xvt37I5K9Nfsh23O/pH7evyDB3pBKdig7LwUxtwIfxWGXRJIOD7GD+ELOvXLJPnDZ9mhs7TwqThwGkK78WP9QykRcbjN/fVPsxgqPQl7FnTHauNNddyMp5If49he+lf5ZWHdimImIDlgFMjNBoc8QVHovR1ui1ltdX+t7jrq7HMXEmqgeiEVv/QOkL5HYp3453cQk3SvnR006INIQDG3N9Tb3Lu3cTXjD43mJw== 
    shell: /bin/bash
package_update: true
package_upgrade: true
packages:
  - sudo
  - wget
  - curl
  - net-tools
write_files:
  - path: /etc/netplan/01-netcfg.yaml
    content: |
      network:
        version: 2
        ethernets:
          enp1s0:
            addresses:
              - ${var.vm_configs[count.index].ip}/24
            gateway4: 192.168.122.1
            nameservers:
              addresses:
                - 8.8.8.8
                - 8.8.4.4
runcmd:
  - [ netplan, apply ]
  - [ systemctl, enable, --now, ssh ]
EOF
}

# Define the VMs
resource "libvirt_domain" "debian_vm" {
  count      = 5
  name       = var.vm_configs[count.index].hostname
  memory     = 2048 # 2 GB
  vcpu       = 2
  autostart  = true

  cloudinit = libvirt_cloudinit_disk.cloudinit[count.index].id

  disk {
    volume_id = libvirt_volume.debian_disk[count.index].id
  }

  network_interface {
    network_name   = "default"
    addresses      = [var.vm_configs[count.index].ip]
    mac            = "52:54:00:00:00:${format("%02x", count.index + 1)}"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

# Output the VM details
output "vm_details" {
  value = [
    for i in range(5) : {
      hostname = libvirt_domain.debian_vm[i].name
      ip       = var.vm_configs[i].ip
    }
  ]
}    
