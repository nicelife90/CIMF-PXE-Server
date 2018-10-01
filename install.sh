#!/bin/bash
#------------------------------------------------------------------------
# PXE SERVER INSTALLER
# Created by : Yanick Lafontaine
# Date       : 30-09-2018
#------------------------------------------------------------------------
# Ubuntu 18.04 LTS
# Clonezilla version 	: alternative stable releases - 20140114-saucy
# GParted version 		: Stable directory (.iso/.zip) 0.18.0-1
#
#------------------------------------------------------------------------
#
# sudo -i
# cd /home/$SUDO_USER/pxe_install
# dos2unix install_without_DHCP.sh
# chmod 775 install_without_DHCP.sh
# ./install_without_DHCP.sh
#
#------------------------------------------------------------------------
#
# Variable			Value								EX
#
# $srvIp 			--> Adresse IP du serveur eth1 		--> 10.10.73.1
# $srvNetmask 		--> Subnetmask du serveur eth1 		--> 255.255.255.0
# $srvNetwork 		--> Broadcast adresse pour le DHCP 	--> 10.10.73.0
# $srvGateway 		--> Passerelle par défaut 			--> 10.10.43.1
# $srvDNS			--> Nom de domaine pour le DHCP		--> 192.168.0.10 192.168.0.11 8.8.8.8 8.8.4.4
# $srvDomain		--> Sous-Réseau						--> domain.local
# $srvSambaUser		--> Utilisateur SAMBA				--> user
# $srvSambaPassword	--> Mot de passe SAMBA				--> password
#------------------------------------------------------------------------

#Intallation de dialog
apt install dialog -y

#Initialisation de l'affichage
DIALOG=${DIALOG=dialog}

#-----------------------------------------------------------
# Function : cancel
#-----------------------------------------------------------
function cancel()
{
$DIALOG --title " PXE SERVER " \
		--ok-label "Quiter l'installation" \
		--msgbox "\nMerci d'avoir utiliser PXE SERVER" 6 50
		
$DIALOG --clear

exit 1
}

#-----------------------------------------------------------
# Function : install
#-----------------------------------------------------------
function install()
{
$DIALOG --clear

#--------------------------------------------------------------------------------
# Configuration
#--------------------------------------------------------------------------------

# -- IP
$DIALOG --title " Configuration du réseau " --clear \
		--inputbox "\nEntrer l'adresse IP du serveur d'imagerie [eth0] :" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvIp=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)
		
		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac
		
# -- NETMASK
$DIALOG --title " Configuration du réseau " --clear \
		--inputbox "\nEntrer le masque de sous-réseau du serveur d'imagerie [eth0] :" 25 70 "255.255.255.0" 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvNetmask=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)
		
		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac
		
# -- GATEWAY	
$DIALOG --title " Configuration du réseau " --clear \
		--inputbox "\nEntrer la passerelle par défaut pour le serveur d'imagerie [eth0] :" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvGateway=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)
		
		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac

# -- DNS
		$DIALOG --title " Configuration du réseau " --clear \
		--inputbox "\nEntrer les serveurs DNS pour ce serveur [eth0] :\n\nEx: 192.168.0.1 8.8.8.8 8.8.4.4" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvDNS=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)

		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac

# -- DOMAIN
$DIALOG --title " Configuration du réseau " --clear \
		--inputbox "\nEntrer le domaine du serveur d'imagerie [eth0] :" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvDomain=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)

		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac

# -- Nom d'utilisateur samba
$DIALOG --title " Configuration des partages " --clear \
		--inputbox "\nEntrer un nom d'utilisateur pour vos partages (SAMBA) :" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvSambaUser=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)

		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac
		
# -- PASSWORD samba
$DIALOG --title " Configuration des partages " --clear \
		--inputbox "\nEntrer un mot de passe pour vos partages (SAMBA) :" 25 70 2> /tmp/inputbox.tmp.$$
		retval=$?
		srvSambaPassword=`cat /tmp/inputbox.tmp.$$`
		rm -f /tmp/inputbox.tmp.$$
		case $retval in
		0)

		;;
		1)
		cancel
		;;
		255)
		cancel
		;;
		esac

#-------------------------------------------------------------------------------------------
# INSTALLATION ET CONFIGURATION
#-------------------------------------------------------------------------------------------

#ajout des sources universe
add-apt-repository universe


#installation des packages requis
apt-get install ifupdown unzip unrar dos2unix apache2 nfs-kernel-server net-tools


#configuration du grub
mv /etc/default/grub /etc/default/grub.old
echo \
"GRUB_DEFAULT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=\"ipv6.disable=1 netcfg/do_not_use_netplan=true\""> /etc/default/grub


#configuration du réseau
mv /etc/network/interfaces /etc/network/interfaces.old
echo \
"# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
address $srvIp
netmask $srvNetmask
gateway $srvGateway
dns-nameservers $srvDNS
dns-domain $srvDomain"> /etc/network/interfaces


#configuration tftp
cp /etc/default/tftpd-hpa /etc/default/tftpd-hpa.old
echo \
"TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS=\"--secure -l -v -m /etc/tftpd.remap"\" >> /etc/default/tftpd-hpa

echo \
"rg \\ /" >> /etc/default/tftpd.remap


#configuration du pxe
mkdir /srv/tftp/pxelinux.cfg
mkdir /srv/tftp/menu
mkdir /srv/tftp/images
cp /usr/lib/syslinux/pxelinux.0 /srv/tftp/
cp /usr/lib/syslinux/memdisk /srv/tftp/
cp /usr/lib/syslinux/vesamenu.c32 /srv/tftp/
cp /usr/lib/syslinux/linux.c32 /srv/tftp/
cp /usr/lib/syslinux/chain.c32 /srv/tftp/


#styles
cp bg.png /srv/tftp/menu/

echo \
"menu color screen		*       #90ffffff #00000000 *
menu color border		*       #00000000 #00000000 *
menu color title		*       #ffffffff #00000000 *
menu color unsel		*       #90ffffff #00000000 *
menu color hotkey		*       #ffff0505 #00000000 *
menu color sel			*       #e0ffffff #20ff0505 *
menu color hotsel		*       #ffff0505 #20ff0505 *
menu color scrollbar	*       #20ff0505 #00000000 *
menu color tabmsg		*       #60ffffff #00000000 *
menu color cmdmark		*       #c000ffff #00000000 *
menu color cmdline		*       #c0ffffff #00000000 *
menu color pwdborder	*       #ffff0505 #20ff0505 *
menu color pwdheader	*       #ffffffff #20ff0505 *
menu color pwdentry		*       #90ffffff #20ff0505 *
menu color timeout_msg	*       #80ffffff #00000000 *
menu color timeout		*       #c0ffffff #00000000 *

#Image de fond doit le format se doit detre en 640x480 24Bit PNG
menu background menu/bg.png

menu width              	42
menu margin             	3
menu passwordmargin     	3
menu rows               	14
menu tabmsgrow          	20
menu cmdlinerow         	22
menu endrow             	22
menu passwordrow        	19
menu timeoutrow         	22
menu vshift 				5

allowoptions 0
prompt 0
noescape 1" >> /srv/tftp/menu/design.conf

#main menu
echo \
"DEFAULT vesamenu.c32 menu/design.conf ~

TIMEOUT 0
MENU TITLE Menu Principal

LABEL os-installation
	MENU LABEL ^1) Installation Windows ->
	TEXT HELP
	Permet de faire une installation de Windows
	ENDTEXT
	KERNEL vesamenu.c32
	APPEND menu/design.conf menu/os_install.conf
	
LABEL tools
	MENU LABEL ^2) Outils de diagnostique ->
	TEXT HELP
	Liste des outils de diagnostique
	ENDTEXT
	KERNEL vesamenu.c32
	APPEND menu/design.conf menu/tools.conf

LABEL gparted
	MENU LABEL ^3) GParted
	TEXT HELP
	GParted Live
	ENDTEXT
	KERNEL gparted/vmlinuz
	APPEND initrd=gparted/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_live_run=\"ocs-live-general\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/gparted/filesystem.squashfs
	
MENU SEPARATOR

LABEL capture
	MENU LABEL ^4) Gestion des images ->
	TEXT HELP
	Permet de capturer une image
	ENDTEXT
	KERNEL vesamenu.c32
	APPEND menu/design.conf menu/os_capture.conf
	
MENU SEPARATOR

LABEL local-boot
	MENU LABEL ^5) Local Boot
	TEXT HELP
	Local Boot - HDD
	ENDTEXT
	localboot 0"  >> /srv/tftp/pxelinux.cfg/default
	
#menu capture
echo \
"MENU TITLE Menu - Windows Installation

LABEL clonezilla-capture-10
	MENU LABEL ^1) Windows 10 [Capture]
	TEXT HELP
	Capturer une image Windows 10
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win10 /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla-capture-81
	MENU LABEL ^2) Windows 8.1 [Capture]
	TEXT HELP
	Capturer une image Windows 8.1
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win81 /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla-capture-8
	MENU LABEL ^3) Windows 8 [Capture]
	TEXT HELP
	Capturer une image Windows 8
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win8 /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla-capture-7
	MENU LABEL ^4) Windows 7 [Capture]
	TEXT HELP
	Capturer une image Windows 7
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win7 /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla-capture-v
	MENU LABEL ^5) Windows Vista [Capture]
	TEXT HELP
	Capturer une image Windows Vista
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/winv /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla-capture-xp
	MENU LABEL ^6) Windows XP [Capture]
	TEXT HELP
	Capturer une image Windows XP
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/winxp /home/partimag\" ocs_live_run=\"ocs-sr -q2 -c -j2 -z3 -i 2000 -rm-win-swap-hib -p poweroff saveparts ask_user sda1\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs keyboard-layouts=NONE locales=\"en_US.UTF-8\"


LABEL clonezilla
	MENU LABEL ^7) Clonezilla
	TEXT HELP
	Capturer manuellement
	ENDTEXT
	KERNEL clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset ocs_live_run=\"ocs-live-general\" ocs_live_batch=\"no\" vga=788 nosplash noprompt fetch=tftp://$srvIp/clonezilla/filesystem.squashfs


MENU SEPARATOR


LABEL retourMenu
	MENU LABEL <- ^Retour menu principal
	KERNEL vesamenu.c32
	APPEND menu/design.conf ~" >> /srv/tftp/menu/os_capture.conf
	
#menu ghost
echo \
"MENU TITLE Menu - Installation Windows

LABEL windows-10
	MENU LABEL ^1) Windows 10
	TEXT HELP
	Installer une version de Windows 10
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win10 /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales

LABEL windows-81
	MENU LABEL ^2) Windows 8.1 
	TEXT HELP
	Installer une version de Windows 8.1
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win81 /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales

LABEL windows-8
	MENU LABEL ^3) Windows 8
	TEXT HELP
	Installer une version de Windows 8.
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win8 /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales
	
LABEL windows-7
	MENU LABEL ^4) Windows 7 
	TEXT HELP
	Installer une version de Windows 7.
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/win7 /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales

LABEL windows-vista
	MENU LABEL ^5) Windows Vista 
	TEXT HELP
	Installer une version de Windows Vista.
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/winv /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales

LABEL windows-xp
	MENU LABEL ^6) Windows XP 
	TEXT HELP
	Installer une version de Windows XP.
	ENDTEXT
	kernel clonezilla/vmlinuz
	APPEND initrd=clonezilla/initrd.img boot=live union=aufs config noswap noprompt vga=788 ip=frommedia fetch=tftp://$srvIp/clonezilla/filesystem.squashfs ocs_prerun2=\"sudo mount -t cifs -o user=$srvSambaUser,password=$srvSambaPassword //$srvIp/winxp /home/partimag\" ocs_prerun3=\"busybox tftp -g -r partition-script -l /tmp/partition-script $srvIp\" ocs_live_run=\"bash /tmp/partition-script\" keyboard-layouts=NONE ocs_live_batch=\"no\" locales=\"en_US.UTF-8\" nolocales

MENU SEPARATOR

LABEL retourMenu
	MENU LABEL <- ^Retour menu principal
	KERNEL vesamenu.c32
	APPEND menu/design.conf ~" >> /srv/tftp/menu/os_install.conf
	
#menu tools
echo \
"MENU TITLE Menu - Outils de test

LABEL memtest420
        MENU LABEL ^1) Memtest86+ V4.20
        TEXT HELP
        Utilitaire de test pour la RAM
        ENDTEXT
        KERNEL tools/memtest

LABEL memtest501
        MENU LABEL ^2) Memtest86+ V5.01
        TEXT HELP
        Utilitaire de test pour la RAM
        ENDTEXT
        LINUX /tools/memtest86p.bin

MENU SEPARATOR

LABEL seatools
        MENU LABEL ^3) SeaTools V2.23 (Seagate/Maxtor)
        TEXT HELP
        Test pour les disques Seagate/Maxtor
        ENDTEXT
        KERNEL memdisk
        INITRD tools/seatool.img.gz

LABEL ubcd
        MENU LABEL ^4) Ultimate Boot CD
        TEXT HELP
        Collection d'outil de diagnostique
        ENDTEXT
        KERNEL memdisk
        INITRD tools/fdubcd.img.gz

LABEL dft
        MENU LABEL ^5) Drive Fitness Test V4.16 (IBM/Hitachi)
        TEXT HELP
        Test pour les disques IBM/Hitachi
        ENDTEXT
        KERNEL memdisk
        INITRD tools/dft.img.gz

LABEL powermax
        MENU LABEL ^6) PowerMax V4.23 (Maxtor/Quantum)
        TEXT HELP
        Test pour les disques Maxtor/Quantum
        ENDTEXT
        KERNEL memdisk
        INITRD tools/powmx423.img.gz

MENU SEPARATOR

LABEL ntpasswd
        MENU LABEL ^7) Offline NT Password Changer
        TEXT HELP
        Utility to reset/unlock windows NT/2000/XP/Vista/7 administrator/user password.
        ENDTEXT
        KERNEL memdisk
        INITRD tools/ntpasswd.iso
        APPEND iso raw

LABEL esrsystemrecovery
        MENU LABEL ^8) ESR System Recovery
        TEXT HELP
        Utility to reset/unlock windows NT/2000/XP/Vista/7 administrator/user password.
        ENDTEXT
        KERNEL memdisk
        INITRD tools/esrsystemrecovery.iso
        APPEND iso raw

MENU SEPARATOR

LABEL retourMenu
	MENU LABEL <- ^Retour menu principal
	KERNEL vesamenu.c32
	APPEND menu/design.conf ~" >> /srv/tftp/menu/tools.conf

#Creation du script de partition
cp packages/partition-script /srv/tftp/partition-script

#dos2unix file
dos2unix /srv/tftp/partition-script
dos2unix /srv/tftp/menu/*.conf
dos2unix /srv/tftp/pxelinux.cfg/*

#Installation des outils
mkdir /srv/tftp/tools
mkdir /srv/tftp/gparted
mkdir /srv/tftp/clonezilla

#memtest 4.20
unzip packages/memtest.zip -d /srv/tftp/tools/
mv /srv/tftp/tools/memtest.bin /srv/tftp/tools/memtest

#memtest 5.01
cp packages/memtest86p.bin /srv/tftp/tools/

#seetools
cp packages/seatool.img.gz /srv/tftp/tools/

#Offline password changer
cp packages/ntpasswd.iso /srv/tftp/tools/

#clonezilla
unzip -j packages/clonezilla.zip live/vmlinuz live/initrd.img live/filesystem.squashfs -d /srv/tftp/clonezilla/

#gparted
unzip -j packages/gparted.zip live/vmlinuz live/initrd.img live/filesystem.squashfs -d /srv/tftp/gparted/

#dft
cp packages/dft.img.gz /srv/tftp/tools/

#esr
cp packages/esrsystemrecovery.iso /srv/tftp/tools/

#ubcd
cp packages/fdubcd.img.gz /srv/tftp/tools/

#powermax
cp packages/powmx423.img.gz /srv/tftp/tools/

#configuration du ftp (BIND PXE FOLDER)
mkdir /home/$SUDO_USER/PXE
chown -R $SUDO_USER /home/$SUDO_USER/PXE
chgrp -R root /home/$SUDO_USER/PXE
chmod -R 775 /home/$SUDO_USER/PXE
chmod -R g+s /home/$SUDO_USER/PXE
chown -R $SUDO_USER /srv/tftp
chgrp -R root /srv/tftp
chmod -R 775 /srv/tftp
chmod -R g+s /srv/tftp
mv /etc/rc.local /etc/rc.local.old
echo \
"mount --bind /srv/tftp /home/$SUDO_USER/PXE
exit 0" >> /etc/rc.local
chmod 775 /etc/rc.local

#Configuration de (SAMBA)
useradd $srvSambaUser -p $srvSambaPassword
(echo $srvSambaPassword; echo $srvSambaPassword) | smbpasswd -as $srvSambaUser

mkdir /opt/Images /opt/Images/win10 /opt/Images/win81 /opt/Images/win8 /opt/Images/win7 /opt/Images/winv /opt/Images/winxp

chmod -R 775 /opt/Images
chown -R $srvSambaUser /opt/Images
chgrp -R root /opt/Images
chmod -R g+s /opt/Images

mv /etc/samba/smb.conf /etc/samba/smb.conf.old
echo \
"
#========================================
#-------[ CONFIGURATION GLOBAL ]---------
#========================================

[global]
# ID du serveur
workgroup = WORKGROUP
server string = Serveur d'imagerie (smb v.%v)
netbios name = $HOSTNAME
os level = 20

# Authentification
security = user
domain logons = no
encrypt passwords = yes
smb passwd file = /etc/samba/smbpasswd
unix password sync = no

# Affichage accents
dos charset = 850
display charset = UTF8

# LOGS
max log size = 50
log file = /var/log/samba/%m.log
username map = /etc/samba/smbusers

#========================================
#-------------[ PARTAGES ]---------------
#========================================

[win10]
comment = Image Windows 10
path = /opt/Images/win10
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser

[win81]
comment = Image Windows 8.1
path = /opt/Images/win81
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser

[win8]
comment = Image Windows 8
path = /opt/Images/win8
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser

[win7]
comment = Image Windows 7
path = /opt/Images/win7
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser

[winv]
comment = Image Windows Vista
path = /opt/Images/winv
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser

[winxp]
comment = Image Windows XP
path = /opt/Images/winxp
browsable = yes
guest ok = no
read only = no
create mask = 0770
directory mask = 0770
force group = root
force user = $srvSambaUser
valid users = $srvSambaUser" >> /etc/samba/smb.conf

# -- MESSAGE FINAL
$DIALOG --title " Configuration du DHCP " --clear \
		--ok-label "Terminer" \
        --msgbox "\nVous devez maintenant configurer votre DHCP pour pointer sur le serveur d'imagerie. 
		\n\nWINDOWS :
		\nOption 66 : $srvIp
		\nOption 67 : pxelinux.0" 25 70

}


#-----------------------------------------------------------
#        Message d'accueil du script d'installation
#-----------------------------------------------------------
$DIALOG --title " PXE SERVER - INSTALL" --clear \
        --yesno "\nBienvenue dans l'assistance d'installation.
		\n\nCette assistant vous guidera tous au long du processus d'installation de votre nouveau serveur PXE.
		\n\nEn acceptant, vous reconnaissez avoir l'autorisation d'utiliser ce script. Bien que la totalité des services installés par ce script soit Open Source, ce script demeure la propriété de son créateur et vous devez avoir eu une autorisation avant de l'utiliser.
		\n\nVoulez-vous lancer l'installation?" 25 70

case $? in
  0)
    install;;
  1)
    cancel
	;;
  255)
    cancel
	;;
esac
