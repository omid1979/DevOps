#!/bin/bash

# Set the path to the output file
OUTPUT_FILE="pjsip.conf"

# Header for the pjsip.conf file
HEADER="[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

[transport-tcp]
type=transport
protocol=tcp
bind=0.0.0.0:5060
"

# Template for each extension
TEMPLATE="[${EXTENSION}]
type=endpoint
context=from-pstn
disallow=all
allow=ulaw
auth=${EXTENSION}
aors=${EXTENSION}

[${EXTENSION}]
type=auth
auth_type=userpass
password=${EXTENSION}
username=${EXTENSION}

[${EXTENSION}]
type=aor
max_contacts=1
;---------------------------
"

# Generate the configuration for extensions 101 to 199
for EXTENSION in {101..199}; do
  echo "$TEMPLATE" | sed "s/\${EXTENSION}/$EXTENSION/g" >> $OUTPUT_FILE
done

# Print the header at the top of the file
echo -e "$HEADER" | cat - $OUTPUT_FILE > temp && mv temp $OUTPUT_FILE

echo "pjsip.conf generated successfully."
		
