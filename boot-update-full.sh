#!/bin/bash

set -e

DISTRO_NAME="budgie funtoo-test gentoo ubuntu"
MOUNT_DIR="/mnt/"

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

check_mount_options() {
	if [[ -n "${ROOT_SUBVOL}" ]]; then
		ROOT_SUBVOL="-o subvol=${ROOT_SUBVOL} "
	fi
	if [[ -n "${BOOT_SUBVOL}" ]]; then
		BOOT_SUBVOL="-o subvol=${BOOT_SUBVOL} "
	fi
	if [[ -n "${ROOT_LABEL}" ]]; then
		ROOT_LABEL="LABEL=${ROOT_LABEL}"
	fi
	if [[ -n "${BOOT_LABEL}" ]]; then
		BOOT_LABEL="LABEL=${BOOT_LABEL}"
	fi
}

unset_mount_vars() {
	for i in {ROOT_,BOOT_}{PART,LABEL,SUBVOL}; do
		unset $i
	done
}

chroot_mount() {
	BOOT_MOUNT_DIR="${MOUNT_DIR}${DISTRO}/boot"
	ROOT_MOUNT_DIR="${MOUNT_DIR}${DISTRO}"
	if [[ $(findmnt -M "${ROOT_MOUNT_DIR}") && $(findmnt -M "${BOOT_MOUNT_DIR}") ]]; then
		echo -e "${DISTRO} ROOT and BOOT already mounted...skipping"
	else
		for REAL in "ROOT BOOT"; do
			[[ $(findmnt -M "${[$REAL]_MOUNT_DIR}") ]] || \
				{ mount ${[$REAL]_SUBVOL}${[$REAL]_LABEL}${[$REAL]_PART} ${[$REAL]_MOUNT_DIR}; \
				echo -e "Mounting ${DISTRO} ${REAL}"; \
				NEW_${!REAL}_MOUNTS="${NEW_[$REAL]_MOUNTS} ${[$REAL]_MOUNT_DIR}"; }
		done
		#[[ $(findmnt -M "${BOOT_MOUNT_DIR}") ]] || \
		#	{ mount ${BOOT_SUBVOL}${BOOT_LABEL}${BOOT_PART} ${BOOT_MOUNT_DIR}; \
		#	echo -e "Mounting ${DISTRO} BOOT \n"; \
		#	NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${BOOT_MOUNT_DIR}"; }
	fi
}

chroot_unmount() {
	for MOUNTED in ${NEW_BOOT_MOUNTS} ${NEW_ROOT_MOUNTS};do
		[[ $(findmnt -M ${MOUNTED}) ]] && umount -lR ${MOUNTED} && echo -e "Unmounting: ${MOUNTED}"
	done
}

for DISTRO in ${DISTRO_NAME}; do
	$DISTRO;
	check_mount_options
	chroot_mount
	unset_mount_vars
done

boot-update

echo -e "Unmounting only automounted directories: \n"
chroot_unmount
