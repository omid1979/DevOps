:#!/bin/bash

# Define the output file
SIP_CONF="sip.conf"

# Function to add a SIP extension
add_extension() {
    local ext_number=$1
    local context=$2
    local auth_user=$3
    local auth_pass=$4

    echo "[$ext_number]" >> $SIP_CONF
    echo "type=friend" >> $SIP_CONF
    echo "context=$context" >> $SIP_CONF
    echo "host=dynamic" >> $SIP_CONF
    echo "secret=$auth_pass" >> $SIP_CONF
    echo "disallow=all" >> $SIP_CONF
    echo "allow=ulaw" >> $SIP_CONF
    echo "" >> $SIP_CONF

    echo "Added SIP extension: $ext_number"
}

# Clear previous content in sip.conf (optional)
echo "" > $SIP_CONF

# Define the number of extensions and their details
for i in $(seq 100 130); do
    add_extension "$i" "from-internal" "$i" "$i"
done

echo "Sample SIP extensions generated in $SIP_CONF."

