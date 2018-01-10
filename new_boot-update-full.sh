#!/bin/bash

set -e

DISTRO_NAME="budgie funtoo-test gentoo ubuntu"

budgie {
	BTRFS_SUB_ROOT="@"
	ROOT_PART="/dev/sda5"
	BOOT_PART="/dev/sda7"
}

funtoo-test {
	ROOT_PART_LABEL="Funtoo-Root"
	BOOT_PART_LABEL="Funtoo-Boot"
}

gentoo {
	ROOT_PART_LABEL="Gentoo-Root"
	BOOT_PART_LABEL="Gentoo-Boot"
}

ubuntu {
	BTRFS_SUB_ROOT="@"
	ROOT_PART="/dev/sda12"
	BOOT_PART="/dev/sda11"
}

ROOT_MOUNT_DIR="/mnt/"

chroot_mount () {
	if [[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}") && $(findmnt -M "${ROOT_MOUNT_DIR}${DISTRO}/boot") ]]; then
		echo -e "${DISTRO} ROOT and BOOT already mounted...skipping"
	else
		[[ $(findmnt -M ${DISTRO_MOUNT}) ]] \
			{ mount ${BTRFS_SUB_ROOT}${ROOT_PART_LABEL}${ROOT_PART} ${DISTRO_MOUNT}; \
			echo -e "Mounting ${DISTRO} ROOT"; \
			NEW_ROOT_MOUNTS="${NEW_ROOT_MOUNTS} ${ROOT_MOUNT_DIR}${DISTRO}"; }
		[[ $(findmnt -M ${ROOT_MOUNT_DIR}${DISTRO}/boot) ]] \
			{ mount ${BTRFS_SUB_BOOT}${BOOT_PART_LABEL}${BOOT_PART} ${ROOT_MOUNT_DIR}${DISTRO}/boot; \
			echo -e "Mounting ${DISTRO} BOOT \n"; \
			NEW_BOOT_MOUNTS="${NEW_BOOT_MOUNTS} ${ROOT_MOUNT_DIR}${DISTRO}/boot"; }
	fi
}

chroot_unmount () {
	for MOUNTED in ${NEW_BOOT_MOUNTS} ${NEW_ROOT_MOUNTS};do
		[[ $(findmnt -M ${MOUNTED}) ]] && umount -lR ${MOUNTED} && echo -e "Unmounting: ${MOUNTED}"
	done
}

for DISTRO in ${DISTRO_NAME}; do
	source ${DISTRO}
	chroot_mount
done

boot-update

echo -e "Unmounting only automounted directories: \n"
chroot_unmount
