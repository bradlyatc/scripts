#!/bin/bash

set -e
clear

DISTRO_NAME="budgie funtoo-test gentoo ubuntu"
MOUNTS_DIR="/mnt"

budgie() {
	ROOT_SUBVOL="@"
	ROOT_PART="/dev/sda5"
	BOOT_PART="/dev/sda7"
}

funtoo-test() {
	ROOT_LABEL="Funtoo-Root"
	BOOT_LABEL="Funtoo-Boot"
}

gentoo() {
	ROOT_LABEL="Gentoo-Root"
	BOOT_LABEL="Gentoo-Boot"
}

ubuntu() {
	ROOT_SUBVOL="@"
	ROOT_PART="/dev/sda12"
	BOOT_PART="/dev/sda11"
}

unset_mount_vars() {
	for i in {ROOT,BOOT}{_PART,_LABEL,_SUBVOL}; do
		unset $i
	done
}

chroot_mount() {
	if [[ $(findmnt -M "${MOUNTS_DIR}/${DISTRO}") && $(findmnt -M "${MOUNTS_DIR}/${DISTRO}/boot") ]]; then
		echo -e "${DISTRO} ROOT and BOOT already mounted...skipping \n"
	else
		[[ $(findmnt -M "${MOUNTS_DIR}/${DISTRO}") ]] && echo -e "${DISTRO} ROOT already mounted at ${MOUNTS_DIR}/${DISTRO}...skipping" || \
			{ mount ${ROOT_SUBVOL/#/-o subvol=} ${ROOT_LABEL/#/LABEL=}${ROOT_PART} "${MOUNTS_DIR}/${DISTRO}"; \
			echo -e "Mounting ${DISTRO} ROOT: ${ROOT_SUBVOL/#/subvol=} ${ROOT_LABEL/#/LABEL=}${ROOT_PART} @: ${MOUNTS_DIR}/${DISTRO}"; \
			ROOT_MOUNTS=(${ROOT_MOUNTS[@]} "${MOUNTS_DIR}/${DISTRO}"); };
		[[ $(findmnt -M "${MOUNTS_DIR}/${DISTRO}/boot") ]] && echo -e "${DISTRO} BOOT already mounted at ${MOUNTS_DIR}/${DISTRO}/boot...skipping \n" || \
			{ mount ${BOOT_SUBVOL/#/-o subvol=} ${BOOT_LABEL/#/LABEL=}${BOOT_PART} "${MOUNTS_DIR}/${DISTRO}/boot"; \
			echo -e "Mounting ${DISTRO} BOOT: ${BOOT_SUBVOL/#/subvol=} ${BOOT_LABEL/#/LABEL=}${BOOT_PART} @: ${MOUNTS_DIR}/${DISTRO}/boot \n"; \
			BOOT_MOUNTS=(${BOOT_MOUNTS[@]} "${MOUNTS_DIR}/${DISTRO}/boot"); };
	fi
}

chroot_unmount() {
	ALL_MOUNTS=(${BOOT_MOUNTS[@]} ${ROOT_MOUNTS[@]})
	for MOUNTED in ${ALL_MOUNTS[@]};do
		[[ $(findmnt -M ${MOUNTED}) ]] && umount -lR ${MOUNTED} && echo -e "Unmounting: ${MOUNTED}"  
	done
}

for DISTRO in ${DISTRO_NAME}; do
	$DISTRO;
	chroot_mount
	unset_mount_vars
done

boot-update

echo -e "Unmounting only automounted directories: \n"
chroot_unmount
