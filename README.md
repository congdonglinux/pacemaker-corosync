Pacemaker-Corosync
=============

## [Script cài đặt Pacemaker trên CentOS](https://github.com/ducnc/pacemaker-corosync/blob/master/Script-Centos/pacemake-cent.sh)

## [Script cài đặt Pacemaker trên Ubuntu Server](https://github.com/ducnc/pacemaker-corosync/blob/master/Script-Ubuntu/pacemake-ubuntu.sh)

## [Bài lab pacemaker HA mysql, apapche](https://github.com/ducnc/pacemaker-corosync/blob/master/Script-Ubuntu/drbd.sh)

## Một số cấu hình cơ bản với Pacemaker

Cấu hình một Virtual IP cho hai node
    
    crm configure property stonith-enabled=false
    crm configure property no-quorum-policy="ignore"
    crm configure primitive ClusterIP ocf:heartbeat:IPaddr2 params ip=10.10.10.200 cidr_netmask="24" op monitor interval="30s"
    
Show cấu hình 
    
    crm configure show
    
Stop

    crm resource stop ClusterIPs
Xóa
    
    crm configure delete ClusterIP
