#!/bin/bash

set -e

# define directory to be our chroot
ROOT_MOUNT="/mnt/gentoo"

# define distfiles directory for bind mount
#DISTFILES_DIR="/usr/portage/distfiles"

# define portage directory for bind mount
#PORTAGE_DIR="/usr/portage"

# define partitions to mount
ROOT_PART="LABEL=Gentoo-Root"
BOOT_PART="LABEL=Gentoo-Boot"

# mount physical filesystems
mount $ROOT_PART $ROOT_MOUNT
mount $BOOT_PART $ROOT_MOUNT/boot

# copy DNS info
cp -L /etc/resolv.conf $ROOT_MOUNT/etc

# bind mount PORTAGE_DIR
#test -d $ROOT_MOUNT${PORTAGE_DIR} && mount --bind $PORTAGE_DIR $ROOT_MOUNT${PORTAGE_DIR} || mkdir $ROOT_MOUNT${PORTAGE_DIR} && mount --bind $PORTAGE_DIR $ROOT_MOUNT${PORTAGE_DIR} 

# bind mount DISTFILES_DIR
#mount --bind $DISTFILES_DIR ${ROOT_MOUNT}${DISTFILES_DIR}

# mount bind proc sys dev tmp to real root
mount -t proc /proc $ROOT_MOUNT/proc
mount --rbind /tmp $ROOT_MOUNT/tmp

for dir in sys dev; do
	mount --rbind /$dir $ROOT_MOUNT/$dir
	mount --make-rslave $ROOT_MOUNT/$dir
done


## needed if chrooting on non-gentoo based systems
#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

## needed for os-prober to test EFI system partition
#mkdir -p $ROOT_MOUNT/run/udev
#mount -o bind /run/udev $ROOT_MOUNT/run/udev
#mount --make-rslave $ROOT_MOUNT/run/udev

# chroot into our new root
env -i HOME=/root TERM=$TERM /usr/bin/chroot $ROOT_MOUNT /bin/bash -l

# unmount chroot on exit
echo -e "Unmounting ${ROOT_MOUNT}"
umount -lR $ROOT_MOUNT
