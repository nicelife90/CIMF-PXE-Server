#!/bin/bash

#install base package
sudo -s
cd ~
add-apt-repository universe
apt update -y
apt upgrade -y
apt install tftpd-hpa samba apache2 nfs-kernel-server net-tools

#configure tftpd
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure -l -v -m /etc/tftpd.remap"


# /etc/default/tftpd.remap
rg \\ /




#create folder
mkdir /srv/tftp
mkdir /srv/tftp/images
chmod 777 /srv/tfpt/
chmod 777 /srv/tfpt/images/

#download syslinux
cd /tmp
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.07.tar.gz
tar -xf syslinux-4.07.tar.gz
cd syslinux-4.07/
find ./ -name "memdisk" -type f|xargs -I {} cp '{}' /srv/tftp/
find ./ -name "pxelinux.0"|xargs -I {} cp '{}' /srv/tftp/
find ./ -name "gpxelinux.0"|xargs -I {} cp '{}' /srv/tftp/
find ./ -name "*.c32"|xargs -I {} cp '{}' /srv/tftp/
cd /srv/tftp/


#configure samba
[images]
comment = images
path = /srv/tftp/images
create mask = 0660
directory mask = 0771
writable = yes
guest ok = yes