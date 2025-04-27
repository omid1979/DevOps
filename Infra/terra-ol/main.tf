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

# Define a libvirt network (NAT-based)
resource "libvirt_network" "vm_network" {
  name      = "vm_network"
  mode      = "nat"
  domain    = "localdomain"
  addresses = ["192.168.122.0/24"]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

# Define the base volume (qcow2 image)
resource "libvirt_volume" "base_image" {
  name   = "OracleLinux.qcow2"
  source = "/var/lib/libvirt/images/OracleLinux.qcow2" # Path to your base qcow2 image on the KVM host
  format = "qcow2"
}

# Create volumes for each VM by cloning the base image
resource "libvirt_volume" "vm_disk" {
  count          = 5
  name           = "ol-vm-${count.index + 1}-disk.qcow2"
  base_volume_id = libvirt_volume.base_image.id
  format         = "qcow2"
  size           = 21478375424 # 20GB (in bytes), adjust as needed
}

# Define cloud-init configuration for each VM
resource "libvirt_cloudinit_disk" "cloudinit" {
  count = 5
  name  = "cloudinit-vm-${count.index + 1}.iso"
  user_data = <<EOF
#cloud-config
hostname: vm-${count.index + 1}
fqdn: vm-${count.index + 1}.localdomain
users:
  - name: sysadmin
    plain_text_passwd: "cluster"
    #ssh-authorized-keys:
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
ssh_pwauth: true

packages:
  - vim
  - curl
runcmd:
  - [ "sh", "-c", "echo 'VM ${count.index + 1} configured' > /root/setup.log" ]
EOF
}

# Define the VMs
resource "libvirt_domain" "vm" {
  count      = 4
  name       = "ol-vm-${count.index + 1}"
  memory     = 2048 # 2GB RAM
  vcpu       = 2    # 2 CPUs
  autostart  = true

  # Network configuration
  network_interface {
    network_id     = libvirt_network.vm_network.id
    hostname       = "vm-${count.index + 1}"
    addresses      = ["192.168.122.5${count.index + 1}"] # Static IPs: 192.168.100.11 to 192.168.100.15
    wait_for_lease = false
  }

  # Disk configuration
  disk {
    volume_id = libvirt_volume.vm_disk[count.index].id
  }

  # Cloud-init configuration
  cloudinit = libvirt_cloudinit_disk.cloudinit[count.index].id

  # Console configuration
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  # Graphics (VNC for remote access)
  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }

  # QEMU-specific options
  cpu {
    mode = "host-passthrough"
  }
}

# Output the IP addresses of the VMs
output "vm_ips" {
  value = [for vm in libvirt_domain.vm : vm.network_interface[0].addresses[0]]
}
