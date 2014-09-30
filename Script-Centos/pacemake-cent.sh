#!/bin/bash

# Run this script on all node

NETWORK="10.10.10.0"

yum -y install pacemaker 

cat << EOF > /etc/ha.d/authkeys 
auth 1
1 sha1 secret
EOF

chmod 600 /etc/ha.d/authkeys 

cp /etc/corosync/corosync.conf.example /etc/corosync/corosync.conf 

cat << EOF > /etc/corosync/corosync.conf 
compatibility: whitetank

# add like follows.

aisexec {
        user: root
        group: root
}
service {
        name: pacemaker
        ver: 0
        use_mgmtd: yes
}

totem {
        version: 2
        secauth: off
        threads: 0
        interface {
                ringnumber: 0
# Specify network address for inter-connection
                bindnetaddr: $NETWORK
                mcastaddr: 226.94.1.1
                mcastport: 5405
        }
}
logging {
        fileline: off
        to_stderr: no
        to_logfile: yes
        to_syslog: yes
        logfile: /var/log/cluster/corosync.log
        debug: off
        timestamp: on
        logger_subsys {
                subsys: AMF
                debug: off
        }
}
amf {
        mode: disabled
}
EOF

chown -R hacluster. /var/log/cluster 

/etc/rc.d/init.d/corosync start

chkconfig corosync on 
