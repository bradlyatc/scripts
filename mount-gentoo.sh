#!/bin/bash

set -e

# define directory to be our chroot
MOUNT="/mnt/gentoo"

# define distfiles directory for bind mount
#DISTFILES_DIR="/usr/portage/distfiles"

# define portage directory for bind mount
#PORTAGE_DIR="/usr/portage"

# define partitions to mount
ROOT_PART="LABEL=Gentoo-Root"
BOOT_PART="LABEL=Gentoo-Boot"

# mount physical filesystems
mount $ROOT_PART $MOUNT
mount $BOOT_PART $MOUNT/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNT/etc

# bind mount PORTAGE_DIR
#test -d $MOUNT${PORTAGE_DIR} && mount --bind $PORTAGE_DIR $MOUNT${PORTAGE_DIR} || mkdir $MOUNT${PORTAGE_DIR} && mount --bind $PORTAGE_DIR $MOUNT${PORTAGE_DIR} 

# bind mount DISTFILES_DIR
#mount --bind $DISTFILES_DIR ${MOUNT}${DISTFILES_DIR}

# mount bind proc sys dev tmp to real root
mount -t proc /proc $MOUNT/proc
mount --rbind /tmp $MOUNT/tmp

for dir in sys dev; do
	mount --rbind /$dir $MOUNT/$dir
	mount --make-rslave $MOUNT/$dir
done


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
