#!/bin/bash

set -e

DISTRO_NAME="budgie funtoo-test gentoo ubuntu"
ROOT_MOUNT_DIR="/mnt/"

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
	[[ -n "${ROOT_SUBVOL}" ]] && export ROOT_SUBVOL="-o subvol=${ROOT_SUBVOL} "
	[[ -n "${BOOT_SUBVOL}" ]] && export BOOT_SUBVOL="-o subvol=${BOOT_SUBVOL} "
	[[ -n "${ROOT_LABEL}" ]] && export ROOT_LABEL="LABEL=${ROOT_LABEL}"
	[[ -n "${BOOT_LABEL}" ]] && export BOOT_LABEL="LABEL=${BOOT_LABEL}"
}

unset_mount_vars() {
	for i in {ROOT,BOOT}{_PART,_LABEL,_SUBVOL}; do
		unset $i
	done
}

chroot_mount() {
	if [[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}") && $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}/boot") ]]; then
		echo -e "${DISTRO} ROOT and BOOT already mounted...skipping"
	else
		[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}") ]] || \
			{ mount ${ROOT_SUBVOL}${ROOT_LABEL}${ROOT_PART} ${ROOT_MOUNT_DIR}${DISTRO}; \
			echo -e "Mounting ${DISTRO} ROOT"; \
			NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${ROOT_MOUNT_DIR}${DISTRO}"; }
		[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}/boot") ]] || \
			{ mount ${BOOT_SUBVOL}${BOOT_LABEL}${BOOT_PART} ${ROOT_MOUNT_DIR}${DISTRO}/boot; \
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
