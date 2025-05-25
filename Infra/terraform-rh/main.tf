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

# Define variables
variable "vm_count" {
  default = 3
}

variable "base_image" {
  default = "/var/lib/libvirt/images/rhel9.5.qcow2"
}

# Create a network
resource "libvirt_network" "vm_network" {
  name      = "vm_network"
  mode      = "nat"
  domain    = "local.lan"
  addresses = ["192.168.122.0/24"]

  dns {
    enabled = true
  }

  dhcp {
    enabled = false
  }
}


# Create base volume
resource "libvirt_volume" "base_volume" {
  name   = "rhel9.5-base"
  source = var.base_image
}

# Create VM volumes
resource "libvirt_volume" "vm_volume" {
  count          = var.vm_count
  name           = "rhel9.5-vm-${count.index + 1}.qcow2"
  base_volume_id = libvirt_volume.base_volume.id
  size           = 21474836480 # 20GB
  format         = "qcow2"
}

# Create cloud-init disk for each VM
resource "libvirt_cloudinit_disk" "cloudinit" {
  count = var.vm_count
  name  = "cloudinit-${count.index + 1}.iso"

  user_data = <<EOF

variable "admin_password" {
  type        = string
  description = "Static password for the admin user"
  default     = "$y$j9T$8sS.1U8hzHlrkzmHQdO4L/$1bXNaA2JHBvIZQXjgbRkXSnDNFdcZhCjs2/iLbVjpb7"
  sensitive   = true
}

#cloud-config
hostname: rhel-vm-${count.index + 1}
fqdn: rhel-vm-${count.index + 1}.local.lan
users:
  - name: sysadmin
    passwd: cluster
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel
    shell: /bin/bash
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
        - 192.168.122.20${count.index + 1}/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
          - 192.168.122.1
EOF
}


# Create virtual machines
resource "libvirt_domain" "rhel_vm" {
  count  = var.vm_count
  name   = "rhel-vm-${count.index + 1}"
  memory = 2048
  vcpu   = 2

  network_interface {
    network_id = libvirt_network.vm_network.id
    addresses  = ["192.168.122.20${count.index + 1}"]
  }

  disk {
    volume_id = libvirt_volume.vm_volume[count.index].id
  }

  disk {
    volume_id = libvirt_cloudinit_disk.cloudinit[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# Output VM IPs
output "vm_ips" {
  value = [for i in range(var.vm_count) : "192.168.122.20${i + 1}"]
}

