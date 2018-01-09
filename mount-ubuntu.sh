#!/bin/bash

set -e

# set directory to be our chroot
MOUNTDIR=/mnt/ubuntu

# mount physical filesystem
echo -e "Mounting ${MOUNTDIR}"
mount -o subvol=@ /dev/sda12 $MOUNTDIR
mount -o subvol=@home /dev/sda12 $MOUNTDIR/home
mount /dev/sda11 $MOUNTDIR/boot

# copy DNS info
cp -L /etc/resolv.conf $MOUNTDIR/etc

# bind mount proc sys dev tmp to real root
mount -t proc /proc $MOUNTDIR/proc
mount --rbind /tmp $MOUNTDIR/tmp

for DIR in sys dev ; do
	mount --rbind /$DIR $MOUNTDIR/$DIR
	mount --make-rslave $MOUNTDIR/$DIR
done

## needed if chrooting on non-gentoo based systems
#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

## needed for os-prober to test EFI system partition
#mount -o bind /run/udev $MOUNTDIR/run/udev
#mount --make-rslave $MOUNTDIR/run/udev

#chroot into our new root
env -i HOME=/root TERM=$TERM /usr/bin/chroot $MOUNTDIR /bin/bash -l

#unmount chroot on exit
echo -e "Umounting ${MOUNTDIR}"
umount -lR $MOUNTDIR
