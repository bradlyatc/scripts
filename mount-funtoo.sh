#!/bin/bash

set -e

# set directory to be our chroot
MOUNTDIR=/mnt/funtoo

# mount physical filesystem
mount /dev/sda16 $MOUNTDIR
mount /dev/sda15 $MOUNTDIR/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNTDIR/etc

# mount proc sys dev tmp 
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

echo -e "Unmounting: $MOUNTDIR"
umount -lR $MOUNTDIR
