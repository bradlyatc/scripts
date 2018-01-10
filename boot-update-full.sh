#!/bin/bash

set -e

DISTRO_NAME="budgie funtoo-test gentoo ubuntu"
ROOT_MOUNT_DIR="/mnt/"

budgie() {
	SUBVOL_ROOT="@"
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
	SUBVOL_ROOT="@"
	ROOT_PART="/dev/sda12"
	BOOT_PART="/dev/sda11"
}

check_mount_options() {
	if [[ -n "${SUBVOL_ROOT}" ]]; then
		SUBVOL_ROOT="-o subvol=${SUBVOL_ROOT} "
	fi
	if [[ -n "${SUBVOL_BOOT}" ]]; then
		SUBVOL_BOOT="-o subvol=${SUBVOL_BOOT} "
	fi
	if [[ -n "${ROOT_LABEL}" ]]; then
		ROOT_LABEL="LABEL=${ROOT_LABEL}"
	fi
	if [[ -n "${BOOT_LABEL}" ]]; then
		BOOT_LABEL="LABEL=${BOOT_LABEL}"
	fi
}

unset_mount_vars() {
	for i in "ROOT_PART BOOT_PART ROOT_LABEL BOOT_LABEL SUBVOL_ROOT SUBVOL_BOOT"; do
		unset $i
	done
}

chroot_mount() {
	if [[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}") && $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}/boot") ]]; then
		echo -e "${DISTRO} ROOT and BOOT already mounted...skipping"
	else
		[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}") ]] || \
			{ mount ${SUBVOL_ROOT}${ROOT_LABEL}${ROOT_PART} ${ROOT_MOUNT_DIR}${DISTRO}; \
			echo -e "Mounting ${DISTRO} ROOT"; \
			NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${ROOT_MOUNT_DIR}${DISTRO}"; }
		[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}/boot") ]] || \
			{ mount ${SUBVOL_BOOT}${BOOT_LABEL}${BOOT_PART} ${ROOT_MOUNT_DIR}${DISTRO}/boot; \
			echo -e "Mounting ${DISTRO} BOOT \n"; \
			NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${ROOT_MOUNT_DIR}${DISTRO}/boot"; }
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
