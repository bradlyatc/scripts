#!/bin/bash

set -e

# set directory to be our chroot
MOUNT="/mnt/test"

## define distfiles directory for bind mount
#DISTFILES_DIR="/var/cache/portage/distfiles"

## define partitions to mount
#ROOT_PART="LABEL=Funtoo-Root"
#BOOT_PART="LABEL=Funtoo-Boot"

## mount physical filesystem
echo -e "Mounting ${MOUNT}"
#mount $ROOT_PART $MOUNT
#mount $BOOT_PART $MOUNT/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNT/etc

# bind mount proc sys dev tmp to real root
mount -t proc /proc $MOUNT/proc
mount --rbind /tmp $MOUNT/tmp

for dir in sys dev; do
	mount --rbind /$dir $MOUNT/$dir
	mount --make-rslave $MOUNT/$dir
done

# mount funtoo meta-repo
test -d $MOUNT/var/git && mount --bind /var/git $MOUNT/var/git || mkdir $MOUNT/var/git && mount --bind /var/git $MOUNT/var/git

## bind mount distfiles
#mount --bind $DISTFILES_DIR ${MOUNT}${DISTFILES_DIR}

## needed if chrooting on non-gentoo based systems
#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

## needed for os-prober to test EFI system partition
#mkdir -p $MOUNT/run/udev
#mount -o bind /run/udev $MOUNT/run/udev
#mount --make-rslave $MOUNT/run/udev

# chroot into our new root
env -i HOME=/root TERM=$TERM /usr/bin/chroot $MOUNT /bin/bash -l

# unmount chroot on exit
echo -e "Unmounting ${MOUNT}"
umount -lR $MOUNT
