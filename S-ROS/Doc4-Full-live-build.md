Below is a comprehensive guide to creating a custom Debian 12-based Linux distribution without a graphical environment, configured as a router with High Availability (HA) capabilities, and building a bootable ISO using `live-build`. The guide includes the required packages, detailed installation steps, configuration for HA, and ISO creation process. The system will be minimal, optimized for routing, and include HA features using `keepalived`, `pacemaker`, and `corosync`. The resulting ISO will be suitable for deployment on physical or virtual machines.

---

### Step-by-Step Guide to Building a Debian 12-Based Router with HA and Creating an ISO

#### 1. Prerequisites
To build the custom Debian 12 ISO and configure it as a router with HA, you need:
- A Debian 12 system (or a compatible environment like Ubuntu) to run `live-build`.
- Root or sudo privileges.
- Internet access to download Debian packages and dependencies.
- At least 20 GB of free disk space for building the ISO.
- Basic knowledge of Linux networking and configuration files.

#### 2. Install `live-build` and Required Tools
`live-build` is a set of scripts provided by Debian to create customized live systems. Install it on your build system:

```bash
sudo apt update
sudo apt install -y live-build debootstrap
```

- `live-build`: Tools to build a Debian live system.
- `debootstrap`: Used to bootstrap a minimal Debian system.

#### 3. Set Up the `live-build` Environment
Create a working directory for the live system and initialize the `live-build` configuration:

```bash
mkdir ~/custom-router
cd ~/custom-router
sudo lb config
```

This creates a `config/` directory with default settings. Customize the configuration to suit your needs:

```bash
sudo lb config \
  --distribution bookworm \
  --architecture amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --mirror-bootstrap http://deb.debian.org/debian/ \
  --mirror-chroot http://deb.debian.org/debian/ \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components hostname=debian-router locale=en_US.UTF-8" \
  --security true \
  --updates true
```

Explanation:
- `--distribution bookworm`: Targets Debian 12 (Bookworm).
- `--architecture amd64`: Builds for 64-bit systems (use `i386` for 32-bit if needed).
- `--archive-areas`: Includes `main`, `contrib`, `non-free`, and `non-free-firmware` for broader package availability (e.g., for firmware or proprietary drivers).
- `--debian-installer none`: Excludes the Debian installer, as this is a live system.
- `--mirror-bootstrap` and `--mirror-chroot`: Specifies Debian mirror for package downloads.
- `--binary-images iso-hybrid`: Creates a hybrid ISO that can boot from CD or USB.
- `--bootappend-live`: Sets live system parameters like hostname and locale.
- `--security` and `--updates`: Includes security updates and latest packages.

#### 4. Specify Required Packages
Create a package list file to include all the specified packages and essential utilities for a router with HA capabilities. Edit `config/package-lists/router.list.chroot`:


iptables
iproute2
tc
wondershaper
vlan
dnsmasq
net-snmp
squid
zabbix-agent
zabbix-get
zabbix-sender
ssh
net-tools
bind9-utils
screen
curl
wget
dialog
fail2ban
rsync
rsyslog
wireguard
wireguard-tools
strongswan
openvpn
easy-rsa
nginx
tcpdump
nmap
ntpsec
keepalived
pacemaker
corosync
cockpit


Explanation of Packages:
- **Networking and Routing**:
  - `iptables`: Firewall rules for packet filtering.
  - `iproute2`: Advanced routing and network configuration.
  - `tc`: Traffic control for bandwidth shaping.
  - `wondershaper`: Simplified bandwidth management.
  - `vlan`: VLAN support for network segmentation.
  - `dnsmasq`: Lightweight DNS and DHCP server.
  - `bind9-utils`: DNS utilities for troubleshooting.
  - `net-tools`: Legacy tools like `ifconfig` and `netstat`.
- **Monitoring and Management**:
  - `net-snmp`: SNMP for network monitoring.
  - `zabbix-agent`, `zabbix-get`, `zabbix-sender`: Monitoring agent and tools for Zabbix integration.
  - `cockpit`: Web-based system administration interface.
- **Security and VPN**:
  - `fail2ban`: Protection against brute-force attacks.
  - `wireguard`, `wireguard-tools`: Modern VPN solution.
  - `strongswan`: IPsec-based VPN.
  - `openvpn`, `easy-rsa`: OpenVPN for secure tunneling.
- **Diagnostics and Utilities**:
  - `tcpdump`: Packet analysis.
  - `nmap`: Network scanning and security auditing.
  - `curl`, `wget`: Tools for fetching data.
  - `screen`: Terminal multiplexer for persistent sessions.
  - `dialog`: Interactive shell scripting.
- **System Services**:
  - `ssh`: Secure remote access.
  - `rsync`: File synchronization.
  - `rsyslog`: System logging.
  - `ntpsec`: Network time synchronization.
- **High Availability**:
  - `keepalived`: VRRP for IP failover.
  - `pacemaker`, `corosync`: Cluster resource management and messaging for HA.
- **Web Proxy**:
  - `squid`: Caching proxy server.
- **Web Server**:
  - `nginx`: Lightweight web server for Cockpit or other services.

#### 5. Configure the System (Chroot Hooks)
To configure the system, create hook scripts to set up networking, HA, and other services during the build process. Create a directory for hook scripts:

```bash
mkdir -p config/hooks/live
```

##### 5.1. Configure Networking
Create a hook script to set up basic networking and enable routing. Create `config/hooks/live/0100-network-setup.hook.chroot`:

```x-shellscript
#!/bin/sh
set -e

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Create a basic network configuration
cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet dhcp
EOF

# Enable dnsmasq service
systemctl enable dnsmasq

# Enable rsyslog
systemctl enable rsyslog
```

Make the script executable:

```bash
chmod +x config/hooks/live/0100-network-setup.hook.chroot
```

This script:
- Enables IP forwarding for routing.
- Configures two network interfaces (`eth0` and `eth1`) with DHCP (modify as needed for static IPs).
- Enables `dnsmasq` for DNS/DHCP and `rsyslog` for logging.

##### 5.2. Configure High Availability (HA)
Set up `keepalived`, `pacemaker`, and `corosync` for HA. Create `config/hooks/live/0200-ha-setup.hook.chroot`:

```x-shellscript
#!/bin/sh
set -e

# Install and configure keepalived
cat > /etc/keepalived/keepalived.conf << EOF
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 12345
    }
    virtual_ipaddress {
        192.168.1.100/24
    }
}
EOF

# Enable keepalived
systemctl enable keepalived

# Configure corosync for pacemaker
cat > /etc/corosync/corosync.conf << EOF
totem {
    version: 2
    cluster_name: router_cluster
    transport: knet
    crypto_cipher: aes256
    crypto_hash: sha256
}

nodelist {
    node {
        ring0_addr: 192.168.1.10
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.1.11
        nodeid: 2
    }
}

quorum {
    provider: corosync_votequorum
    two_node: 1
}

logging {
    to_syslog: yes
}
EOF

# Enable corventy
systemctl enable corosync
systemctl enable pacemaker
```

Make the script executable:

```bash
chmod +x config/hooks/live/0200-ha-setup.hook.chroot
```

Explanation:
- **Keepalived**: Configures a Virtual Router Redundancy Protocol (VRRP) instance with a virtual IP (`192.168.1.100`). Adjust the IP, interface, and priority for your setup.
- **Corosync/Pacemaker**: Sets up a two-node cluster with encrypted communication. Update `ring0_addr` with the actual IPs of your nodes.

##### 5.3. Configure Security and Services
Create a hook to configure `fail2ban`, `ntpsec`, and other services. Create `config/hooks/live/0300-services-setup.hook.chroot`:

```x-shellscript
#!/bin/sh
set -e

# Configure fail2ban
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 600
EOF

# Enable fail2ban
systemctl enable fail2ban

# Configure ntpsec
cat > /etc/ntpsec/ntp.conf << EOF
server pool.ntp.org iburst
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
EOF

# Enable ntpsec
systemctl enable ntpsec

# Enable nginx for Cockpit
systemctl enable nginx
systemctl enable cockpit.socket
```

Make the script executable:

```bash
chmod +x config/hooks/live/0300-services-setup.hook.chroot
```

This script:
- Configures `fail2ban` to protect SSH.
- Sets up `ntpsec` for time synchronization using public NTP servers.
- Enables `nginx` and `cockpit` for web-based management.

#### 6. Bootstrap and Build the Chroot Environment
Bootstrap the base system and install packages:

```bash
sudo lb bootstrap
sudo lb chroot
```

If errors occur during bootstrapping, ensure your internet connection is stable and the Debian mirrors are accessible.

#### 7. Build the ISO
After configuring the chroot environment, build the ISO:

```bash
sudo lb binary
sudo lb build
```

This generates a `live-image-amd64.hybrid.iso` file in the `~/custom-router` directory.

#### 8. Test the ISO
Test the ISO using a virtual machine (e.g., QEMU or VirtualBox):

```bash
sudo apt install -y qemu-system-x86
qemu-system-x86_64 -cdrom live-image-amd64.hybrid.iso -m 512
```

Boot the ISO and verify that:
- The system boots without a graphical environment.
- Networking is functional (check with `ip a`).
- HA services (`keepalived`, `pacemaker`, `corosync`) are running (`systemctl status`).
- Other services (`dnsmasq`, `fail2ban`, `ntpsec`, `cockpit`) are operational.

#### 9. Installation on Physical Hardware
To install the live system on a physical machine:
1. **Create a Bootable USB**:
   ```bash
   sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress && sync
   ```
   Replace `/dev/sdX` with your USB device (use `lsblk` to identify it).
2. **Boot and Test**:
   - Boot the target machine from the USB.
   - Log in as `root` (default password is empty or set via a hook if customized).
   - Verify routing and HA functionality.
3. **Install to Disk** (Optional):
   Since this is a live system, you can use `live-installer` or manually copy the system to disk:
   ```bash
   sudo apt install live-installer
   live-installer
   ```
   Follow the prompts to install the system to the hard drive.

#### 10. Post-Installation Configuration
After booting the system (live or installed):
- **Configure Network Interfaces**: Edit `/etc/network/interfaces` for static IPs or additional interfaces.
- **Set Up HA Cluster**:
  - Update `/etc/keepalived/keepalived.conf` and `/etc/corosync/corosync.conf` with actual IP addresses.
  - Test failover: `systemctl stop keepalived` on the master node and verify the backup node takes over.
  - Use `crm_mon` to monitor the Pacemaker cluster status.
- **Configure Services**:
  - Set up `dnsmasq` for DHCP/DNS (`/etc/dnsmasq.conf`).
  - Configure `squid` for proxy caching (`/etc/squid/squid.conf`).
  - Set up VPNs (`wireguard`, `strongswan`, or `openvpn`) as needed.
  - Access Cockpit at `https://<IP>:9090` for web-based management.
- **Secure the System**:
  - Set a root password: `passwd`.
  - Configure `fail2ban` rules for additional services.
  - Update `iptables` rules for firewalling: `/etc/iptables/rules.v4`.

#### 11. Troubleshooting
- **Build Failures**: Check `lb` logs in the build directory for errors.
- **Networking Issues**: Verify interface configurations and `sysctl` settings.
- **HA Issues**: Check `corosync` logs (`/var/log/corosync`) and ensure nodes can communicate.
- **Package Conflicts**: Use `apt` to resolve dependency issues during the chroot phase.

#### 12. Additional Notes
- **Customizing the ISO**: Add more hook scripts for specific configurations (e.g., custom `iptables` rules, additional users).
- **Minimal Resource Usage**: The system is designed to be lightweight, suitable for low-resource hardware (e.g., 512 MB RAM, 2 GB disk).
- **Backup and Recovery**: Use `rsync` for backups and configure `zabbix-agent` for monitoring.
- **Documentation**: Refer to the Debian Live Manual (`https://live-team.pages.debian.net/live-manual/`) for advanced `live-build` options.[](https://debian-handbook.info/browse/fa-IR/stable/sect.installation-steps.html)

---

This guide provides a complete process to create a Debian 12-based router with HA capabilities and a custom ISO. Adjust configurations (e.g., IP addresses, service settings) based on your network environment. Let me know if you need help with specific configurations or additional features!

