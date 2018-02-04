#!/bin/bash

set -e

# define directory to be our chroot
MOUNTDIR="/mnt/funtoo-test"

# define distfiles directory for bind mount
DISTFILES_DIR="/var/cache/portage/distfiles"

# define partitions to mount
ROOT_PART="LABEL=Funtoo-Root"
BOOT_PART="LABEL=Funtoo-Boot"

# mount physical filesystems
mount $ROOT_PART $MOUNTDIR
mount $BOOT_PART $MOUNTDIR/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNTDIR/etc

## bind mount meta-repo git
#test -d $MOUNTDIR/var/git && mount --bind /var/git $MOUNTDIR/var/git || mkdir $MOUNTDIR/var/git && mount --bind /var/git $MOUNTDIR/var/git 

## bind mount distfiles
#mount --bind $DISTFILES_DIR ${MOUNTDIR}${DISTFILES_DIR}

# mount bind proc sys dev tmp to real root
mount -t proc /proc $MOUNTDIR/proc
mount --rbind /tmp $MOUNTDIR/tmp

for dir in sys dev; do
	mount --rbind /$dir $MOUNTDIR/$dir
	mount --make-rslave $MOUNTDIR/$dir
done


## needed if chrooting on non-gentoo based systems
#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

## needed for os-prober to test EFI system partition
#mkdir -p $MOUNTDIR/run/udev
#mount -o bind /run/udev $MOUNTDIR/run/udev
#mount --make-rslave $MOUNTDIR/run/udev

# chroot into our new root
env -i HOME=/root TERM=$TERM /usr/bin/chroot $MOUNTDIR /bin/bash -l

# unmount chroot on exit
echo -e "Unmounting ${MOUNTDIR}"
umount -lR $MOUNTDIR
