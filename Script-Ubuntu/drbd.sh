#!/bin/bash

# Them mot o cung nua co dung luong 3GB trong vmware workstation

# Chay tren hai node

aptitude install drbd8-utils drbdlinks -y
fdisk /dev/sdb
    n
    p
    w
pvcreate /dev/sdb1
vgcreate sync /dev/sdb1
lvcreate -n drbd-demo -L 2G sync

mv /etc/drbd.conf /etc/drbd.conf.bka

cat << EOF > /etc/drbd.conf
global {
 usage-count yes;
}
common {
 protocol C;
}
resource wwwdata {
 meta-disk internal;
 device  /dev/drbd1;
 syncer {
  verify-alg sha1;
 }
 net {
  allow-two-primaries;
 }
 on network1 {
  disk   /dev/mapper/sync-drbd--demo;
  address  10.10.10.131:7789;
 }
 on network2 {
  disk   /dev/mapper/sync-drbd--demo;
  address  10.10.10.132:7789;
 }
}
EOF

mkdir /service
drbdadm create-md wwwdata
update-rc.d -f drbd remove
watch cat /proc/drbd
/etc/init.d/drbd start

#network1
drbdadm -- --overwrite-data-of-peer primary wwwdata

cp /usr/sbin/drbdlinks /etc/init.d/
vi /etc/drbdlinks.conf
    mountpoint('/service')
    link('/var/www','/service/www')
    link('/var/lib/mysql','/service/mysql')

    
mkfs.ext4 /dev/drbd1
mount /dev/drbd1 /service

#test drbd
#tren node1
touch /service/1
ls /service
drbdadm secondary wwwdata
#node2
drbdadm primary wwwdata
mount /dev/drbd1 /service
ls /service


#install pacemaker tren hai node
crm configure property stonith-enabled="false"
crm configure property no-quorum-policy="ignore"
crm configure primitive drbd_mysql ocf:linbit:drbd \
       params drbd_resource="wwwdata" \
       op monitor interval="1s" role="Master" \
       op monitor interval="3s" role="Slave"
crm configure primitive fs_mysql ocf:heartbeat:Filesystem \
        params device="/dev/drbd1" directory="/service/" fstype="ext4"
crm configure primitive ip_mysql ocf:heartbeat:IPaddr2 \
        params ip="10.10.10.200" nic="eth0"
crm configure group mysql ip_mysql fs_mysql
crm configure ms ms_drbd_mysql drbd_mysql \
        meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
crm configure colocation mysql_on_drbd inf: mysql ms_drbd_mysql:Master
crm configure order mysql_after_drbd inf: ms_drbd_mysql:promote mysql:start


#aptitude install mysql-server apache2 -y
#cp -Ra /var/lib/mysql/ /service/mysql
#mkdir /service/etc
#cp -Ra /etc/apache2/ /service/etc/
#umount /service/

cat << EOF > config
primitive drbd_mysql ocf:linbit:drbd \
        params drbd_resource="wwwdata" \
        op monitor interval="15s"
primitive fs_mysql ocf:heartbeat:Filesystem \
        params device="/dev/drbd1" directory="/service/" fstype="ext4"
primitive ip_mysql ocf:heartbeat:IPaddr2 \
        params ip="10.10.10.200" nic="eth0"
primitive mysqld lsb:mysql
primitive apache lsb:apache2

group mysql fs_mysql ip_mysql mysqld apache
ms ms_drbd_mysql drbd_mysql \
        meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
colocation mysql_on_drbd inf: mysql ms_drbd_mysql:Master
order mysql_after_drbd inf: ms_drbd_mysql:promote mysql:start
property $id="cib-bootstrap-options" \
        no-quorum-policy="ignore" \
        stonith-enabled="false" \
        expected-quorum-votes="2" \
        dc-version="1.0.4-2ec1d189f9c23093bf9239a980534b661baf782d" \
        cluster-infrastructure="openais"
EOF

#crm config
#    load replace /root/config

#reboot    
