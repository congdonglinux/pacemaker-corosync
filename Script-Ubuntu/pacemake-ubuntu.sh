#!/bin/bash

# Run this script on all node Ubuntu 14.04

BIND_NETWORK="10.10.10.0"
#SHARED_VIP="192.168.5.30"

apt-get update
apt-get install -y pacemaker ntp

# Configure Corosync
echo "START=yes" > /etc/default/corosync
sed -i "s/bindnetaddr: 127.0.0.1/bindnetaddr: $BIND_NETWORK/g" /etc/corosync/corosync.conf

# Start clustering software
service corosync start
service pacemaker start
