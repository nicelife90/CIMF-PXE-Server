#!/bin/bash

# These variables hold the counters.
ERR_MSG=""

# This will clear the screen before displaying the menu.
clear

while :
do
	# Write out the menu options...
	printf '\033[0;34;40m'
	echo ""
	echo "========================================================================================"
	printf '\033[0m'
	echo ""
	echo "	Vous devez maintenant choisir le type de partition pour le PC client."
	echo ""
	echo "	1) Utiliser le disque entier."
	echo "	2) Utiliser le disque entier + Recovery."
	echo ""
	# If error exists, display it
	if [ "$ERR_MSG" != "" ]; then
		echo "        Erreur: $ERR_MSG"
	fi
	printf '\033[0;34;40m'
	echo ""
	echo "========================================================================================"
	printf '\033[0m'
	echo ""
	
	# Clear the error message
	ERR_MSG=""

	# Read the user input
	read -p "        Quel actions voulez-vous faire [1-2] ? " -n 1 SEL
	case $SEL in
		1)
                #Cleaning MBR
                sudo dd if=/dev/zero of=/dev/sda bs=512 count=1
		#Partitionnement du disque
		(echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo 4; echo n; echo p; echo 1; echo ; echo ; echo t; echo 7; echo a; echo 1; echo w;) | sudo fdisk /dev/sda
		#Formatage de la partition
		sudo mkfs.ntfs -f /dev/sda1
		#Lancement de clonezilla
		ocs-sr -e1 auto -e2 -r -j2 -k -p reboot restoreparts ask_user sda1
		;;
		
		2)
                #Cleaning MBR
                sudo dd if=/dev/zero of=/dev/sda bs=512 count=1
		#Get disk total block
		DTBLOCK=`cat /sys/block/sda/size`
		#Get disk total size in GB
		DTSIZE=$(($DTBLOCK * 512 / 1024 / 1024 / 1024))
		
		#Check if disk have enough space
		if [ "$DTSIZE" -ge "65" ]; then
		#calculating sda1 size
		SDA1=$(($DTSIZE - 30))
		#Partitionement du disque
		(echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo 4; echo n; echo p; echo 1; echo ; echo +"$SDA1"G; echo n; echo p;  echo 2; echo ; echo ; echo t; echo 1; echo 7; echo t; echo 2; echo b; echo a; echo 1; echo w;) | sudo fdisk /dev/sda
		#Formatage des partitions
		sudo mkfs.ntfs -f /dev/sda1
		sudo mkfs.msdos -F 32 /dev/sda2
		#Lancement de clonezilla
		ocs-sr -e1 auto -e2 -r -j2 -k -p reboot restoreparts ask_user sda1
		
		#Not enough space for recovery partition
		else
		ERR_MSG="Le disque est trop petit pour cette configuration!"
		fi		
		;;
		
		*) ERR_MSG="Votre choix est invalide!"
	esac
	clear
done
