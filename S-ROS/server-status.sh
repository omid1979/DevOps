#!/bin/bash

# Output file
OUTPUT_FILE="/var/log/server_status.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Gathering server information
HOSTNAME=$(hostname)
IP_ADDRESS=$(ip -4 addr show | grep inet | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)
MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || echo "N/A")
UUID=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null || echo "N/A")
UPTIME=$(uptime -p | sed 's/up //')
LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1, $2, $3}' | tr -d ',')

# CPU usage (percentage)
CPU_USAGE=$(top -bn1 | head -n 3 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{printf "%.1f%%", $1}')

# Memory usage
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
MEM_FREE=$(free -h | awk '/Mem:/ {print $4}')
MEM_USAGE="$MEM_USED/$MEM_TOTAL (Free: $MEM_FREE)"

# Disk usage
DISK_USAGE=$(df -h --output=source,fstype,size,used,avail,pcent,target | grep -E '^/dev/' | awk '{print $1 " | Type: " $2 " | Size: " $3 " | Used: " $4 " | Avail: " $5 " | Use%: " $6 " | Mounted on: " $7}')

# Network interfaces (sending/receiving)
NET_INTERFACES=$(ip link show | grep '^[0-9]' | awk -F': ' '{print $2}' | grep -v lo)
NET_INFO=""
for iface in $NET_INTERFACES; do
    IP=$(ip -4 addr show $iface | grep inet | awk '{print $2}' | cut -d'/' -f1)
    [ -z "$IP" ] && IP="No IP"
    RX=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo "N/A")
    TX=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo "N/A")
    # Convert bytes to human-readable format
    RX_HUMAN=$(echo $RX | awk '{if ($1 == "N/A") print "N/A"; else if ($1 > 1073741824) printf "%.2f GB", $1/1073741824; else if ($1 > 1048576) printf "%.2f MB", $1/1048576; else if ($1 > 1024) printf "%.2f KB", $1/1024; else printf "%d Bytes", $1}')
    TX_HUMAN=$(echo $TX | awk '{if ($1 == "N/A") print "N/A"; else if ($1 > 1073741824) printf "%.2f GB", $1/1073741824; else if ($1 > 1048576) printf "%.2f MB", $1/1048576; else if ($1 > 1024) printf "%.2f KB", $1/1024; else printf "%d Bytes", $1}')
    LINK_STATUS=$(cat /sys/class/net/$iface/operstate 2>/dev/null || echo "N/A")
    NET_INFO="$NET_INFO\n$iface | $IP | Sending: $TX_HUMAN | Receiving: $RX_HUMAN | Status: $LINK_STATUS"
done

# Service status (specific services)
SERVICES=("nginx" "wireguard" "ffr")
SERVICE_STATUS=""
for service in "${SERVICES[@]}"; do
    systemctl status $service >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        STATUS="Installed ($(systemctl is-active $service))"
    else
        STATUS="Not Installed"
    fi
    if [ -z "$SERVICE_STATUS" ]; then
        SERVICE_STATUS="    $service: $STATUS"
    else
        SERVICE_STATUS="$SERVICE_STATUS    $service: $STATUS"
    fi
done

# Write to output file
cat << EOF > $OUTPUT_FILE
===== Server Status Report =====
Generated on: $TIMESTAMP
===============================

System Information:
-------------------
Hostname: $HOSTNAME
System Date: $TIMESTAMP
Machine ID: $MACHINE_ID
UUID: $UUID
IP Address: $IP_ADDRESS
Gateway: $GATEWAY
System Uptime: $UPTIME
Load Average: $LOAD_AVERAGE

Resource Usage:
-------------------
CPU Usage: $CPU_USAGE
Memory: $MEM_USAGE

Disk Usage:
-------------------
$DISK_USAGE

Network Interfaces:
-------------------
Interface Name | IP Address | Sending/Receiving | Status
$NET_INFO

Service Status:
-------------------
$SERVICE_STATUS

===============================
EOF

# Display the output file for confirmation
cat $OUTPUT_FILE
