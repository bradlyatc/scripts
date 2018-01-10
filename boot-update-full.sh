#!/bin/bash

set -e
clear
echo -e "***BOOT-UPDATE***\n"

## Budgie
BUDGIEMOUNT=/mnt/budgie
echo -e "Mounting Ubuntu Budgie @: ${BUDGIEMOUNT}"
# check if partitions are mounted if not mount physical partitions
if [[ $(findmnt -M ${BUDGIEMOUNT}) && $(findmnt -M ${BUDGIEMOUNT}/boot) ]]; then
	echo -e "${BUDGIEMOUNT} already mounted...skipping"
else
	[[ $(findmnt -M ${BUDGIEMOUNT}) ]] || \
		{ mount -o subvol=@ /dev/sda5 $BUDGIEMOUNT; \
		echo -e "mounting ${BUDGIEMOUNT} ROOT"; \
		 NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${BUDGIEMOUNT}"; }
	[[ $(findmnt -M ${BUDGIEMOUNT}/boot) ]] || \
		{ mount /dev/sda7 ${BUDGIEMOUNT}/boot; \
		echo -e "mounting ${BUDGIEMOUNT} BOOT \n"; \
		NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${BUDGIEMOUNT}/boot"; }
fi

## Funtoo Test
FUNTOOTESTMOUNT="/mnt/funtoo-test"
echo -e "Mounting Funtoo Test @: ${FUNTOOTESTMOUNT}"
# define partitions to mount
FUNTOO_ROOT_PART="LABEL=Funtoo-Root"
FUNTOO_BOOT_PART="LABEL=Funtoo-Boot"
# mount physical filesystem
if [[ $(findmnt -M ${FUNTOOTESTMOUNT}) && $(findmnt -M ${FUNTOOTESTMOUNT}/boot) ]]; then
	echo -e "${FUNTOOTESTMOUNT} already mounted...skipping"
else
	[[ $(findmnt -M ${FUNTOOTESTMOUNT}) ]] || \
		{ mount ${FUNTOO_ROOT_PART} ${FUNTOOTESTMOUNT}; \
		echo -e "mounting ${FUNTOOTESTMOUNT} ROOT"; \
		NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${FUNTOOTESTMOUNT}"; }
	[[ $(findmnt -M ${FUNTOOTESTMOUNT}/boot) ]] || \
		{ mount ${FUNTOO_BOOT_PART} ${FUNTOOTESTMOUNT}/boot; \
		echo -e "mounting ${FUNTOOTESTMOUNT} BOOT \n"; \
		NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${FUNTOOTESTMOUNT}/boot"; }
fi

## Gentoo
GENTOOMOUNT="/mnt/gentoo"
echo -e "Mounting Gentoo @: ${GENTOOMOUNT}"
# define partitions to mount
GENTOO_ROOT_PART="LABEL=Gentoo-Root"
GENTOO_BOOT_PART="LABEL=Gentoo-Boot"
# mount physical filesystem
if [[ $(findmnt -M "${GENTOOMOUNT}") && $(findmnt -M "${GENTOOMOUNT}/boot") ]];then
	echo -e "${GENTOOMOUNT} already mounted...skipping"
else
	[[ $(findmnt -M "${GENTOOMOUNT}") ]] || \
		{ mount ${GENTOO_ROOT_PART} ${GENTOOMOUNT}; \
		NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${GENTOOMOUNT}"; \
		echo -e "mounting ${GENTOOMOUNT} ROOT"; }
	[[ $(findmnt -M "${GENTOOMOUNT}/boot") ]] || \
		{ mount ${GENTOO_BOOT_PART} ${GENTOOMOUNT}/boot; \
		NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${GENTOOMOUNT}/boot"; \
		echo -e "mounting ${GENTOOMOUNT} BOOT \n"; }
fi

## Ubuntu
UBUNTUMOUNT=/mnt/ubuntu
echo -e "Mounting Ubuntu @: ${UBUNTUMOUNT}"
# mount physical filesystem
if [[ $(findmnt -M ${UBUNTUMOUNT}) && $(findmnt -M ${UBUNTUMOUNT}/boot) ]]; then
	echo -e "${UBUNTUMOUNT} already mounted...skipping"
else
	[[ $(findmnt -M ${UBUNTUMOUNT}) ]] || \
		{ mount -o subvol=@ /dev/sda12 ${UBUNTUMOUNT}; \
		echo -e "mounting ${UBUNTUMOUNT} ROOT"; \
		NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${UBUNTUMOUNT}"; }
	[[ $(findmnt -M ${UBUNTUMOUNT}/boot) ]] || \
		{ mount /dev/sda11 ${UBUNTUMOUNT}/boot; \
		echo -e "mounting ${UBUNTUMOUNT} BOOT \n"; \
		NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${UBUNTUMOUNT}/boot"; }
fi

## call boot-update to configure /boot/grub/grub.cfg
boot-update

## unmount only automounted directories
echo -e "Unmounting only automounted directories: \n"
for MOUNTED in ${NEW_BOOT_MOUNTS} ${NEW_ROOT_MOUNTS};do
	[[ $(findmnt -M ${MOUNTED}) ]] && umount -lR ${MOUNTED} && echo -e "Unmounting: ${MOUNTED}"
done
