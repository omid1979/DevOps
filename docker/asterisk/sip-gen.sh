#!/bin/bash

# Set the path to the sip.conf file
SIP_CONF="sip.conf"

# Generate 10 SIP extensions
for i in {100..110}
do
    # Generate a random 4-digit password
    PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4)
    
    # Append the new extension to sip.conf
    cat << EOF >> $SIP_CONF

[$i]
type=friend
context=default
host=dynamic
secret=$i 
disallow=all
allow=ulaw
allow=alaw
qualify=yes
EOF

    echo "Created extension$i with password $PASSWORD"
done
cat sip.conf
# Reload Asterisk SIP configuration
#asterisk -rx "sip reload"

echo "SIP extensions generated and Asterisk reloaded"

