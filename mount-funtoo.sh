#!/bin/bash

set -e

# set directory to be our chroot
MOUNT=/mnt/funtoo

# mount physical filesystem
mount /dev/sda16 $MOUNT
mount /dev/sda15 $MOUNT/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNT/etc

# mount proc sys dev tmp 
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

umount -lR $MOUNT
