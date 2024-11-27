#!/bin/bash
x=99
while [ $x -le 199 ]
do
  echo "Welcome $x times"
echo "[$x]
type=friend
transport=udp
secret=$x
qualify=yes
pickupgroup=
callgroup=
host=dynamic
dtmfmode=rfc2833
dial=SIP/$x
context=from-internal
callerid=$x <$x>
callcounter=yes
" >> list.txt
  x=$(( $x + 1 ))
done

