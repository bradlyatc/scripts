#!/bin/bash

set -e

# define name of chroot build
BUILD_NAME="buildtest"

# define directory used for mounts
MOUNT_DIR="/mnt"

# define directory to download stage3 tarball and configs
FILES_DIR="/root/buildfiles"

# define stage tarball name
STAGE_NAME="stage3-latest.tar.xz"

# define timezone
TIMEZONE="EST5EDT"

# define distfiles directory for bind mount
DISTFILES_DIR="/var/cache/portage/distfiles"

# define meta-repo directory
META_REPO_DIR="/var/git/meta-repo"

# define partitions to mount
#ROOT_LABEL="LABEL=Test-Root"
#BOOT_LABEL="LABEL=Test-Boot"
#ROOT_PART="/dev/sda#"
#BOOT_PART="/dev/sda#"
#ROOT_SUBVOL="@"

ispart() {
	for i in {ROOT,BOOT}{_LABEL,_PART,_SUBVOL}; do
		[[ ! -z "${!i}" ]] && echo "${!i}" && return
	done
}

# mount physical filesystems and create directories if they don't exist
ROOT_MOUNT_DIR="${MOUNT_DIR}/${BUILD_NAME}"
[[ ! -z "${ROOT_SUBVOL}" ]] && ROOT_SUBVOL="-o subvol=${ROOT_SUBVOL}"
if [[ $(ispart) ]]; then
	if [ -e "$ROOT_MOUNT_DIR" ]; then
		mount $ROOT{_SUBVOL,_PART,_LABEL} $ROOT_MOUNT_DIR
	else
		mkdir $ROOT_MOUNT_DIR && mount $ROOT{_SUBVOL,_PART,_LABEL} $ROOT_MOUNT_DIR
	fi
echo "Mounting: $ROOT{_SUBVOL,_PART,_LABEL} @ $ROOT_MOUNT_DIR"

	if [ -e "$ROOT_MOUNT_DIR/boot" ]; then
		mount $BOOT{_PART,_LABEL} $ROOT_MOUNT_DIR/boot
	else
		mkdir $ROOT_MOUNT_DIR/boot && mount $BOOT{_PART,_LABEL} $ROOT_MOUNT_DIR/boot
	fi
echo "Mounting: $BOOT{_PART,_LABEL} @ $ROOT_MOUNT_DIR/boot"
fi

if [ -e "$ROOT_MOUNT_DIR" ]; then
	echo "Using $ROOT_MOUNT_DIR"
else
	mkdir $ROOT_MOUNT_DIR
	echo "Creating directory $ROOT_MOUNT_DIR"
fi

# copy and unpack stage3
if [ ! -e $FILES_DIR/$STAGE_NAME ]; then
	echo "No stage3 found, fetching:"
	cd $FILES_DIR
	wget http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz
fi

if [ ! -e $ROOT_MOUNT_DIR/$STAGE_NAME ]; then
	echo "Unpacking stage3 to $ROOT_MOUNT_DIR"
	cp $FILES_DIR/$STAGE_NAME $ROOT_MOUNT_DIR
	cd $ROOT_MOUNT_DIR
	tar -xpf $STAGE_NAME
fi

# copy DNS info
cp -L /etc/resolv.conf $ROOT_MOUNT_DIR/etc
echo "Copying resolv.conf to $ROOT_MOUNT_DIR/etc"

# bind mount meta-repo git
if [ -e "$ROOT_MOUNT_DIR${META_REPO_DIR}" ]; then
	mount --bind $META_REPO_DIR $ROOT_MOUNT_DIR${META_REPO_DIR}
else
	mkdir -p $ROOT_MOUNT_DIR${META_REPO_DIR}
	mount --bind $META_REPO_DIR $ROOT_MOUNT_DIR${META_REPO_DIR}
fi

echo "Bind mounting $META_REPO_DIR"

# bind mount distfiles
[ -e ${ROOT_MOUNT_DIR}${DISTFILES_DIR} ] || mkdir -p ${ROOT_MOUNT_DIR}${DISTFILES_DIR}
mount --bind $DISTFILES_DIR ${ROOT_MOUNT_DIR}${DISTFILES_DIR}
echo "Bind mounting $DISTFILES_DIR"

# copy fstab from $FILES_DIR
[ -e $FILES_DIR/fstab ] && cp $FILES_DIR/fstab $ROOT_MOUNT_DIR/etc && echo "Copying fstab from $FILES_DIR"

# copy make.conf from $FILES_DIR
[ -e $FILES_DIR/make.conf ] && cp $FILES_DIR/make.conf $ROOT_MOUNT_DIR/etc/portage && echo "Copying make.conf from $FILES_DIR"

# copy ego.conf from $FILES_DIR
[ -e $FILES_DIR/ego.conf ] && cp $FILES_DIR/ego.conf $ROOT_MOUNT_DIR/etc && echo "Copying ego.conf from $FILES_DIR"

# set timezone
ln -sf $ROOT_MOUNT_DIR/usr/share/zoneinfo/$TIMEZONE $ROOT_MOUNT_DIR/etc/localtime
echo "Setting $TIMEZONE as timezone"

# mount bind proc sys dev tmp to real root
mount -t proc /proc $ROOT_MOUNT_DIR/proc
mount --rbind /tmp $ROOT_MOUNT_DIR/tmp

chmod 1777 $ROOT_MOUNT_DIR/tmp

for dir in sys dev; do
	mount --rbind /$dir $ROOT_MOUNT_DIR/$dir
	mount --make-rslave $ROOT_MOUNT_DIR/$dir
done
echo "Bind mounting proc,sys,dev,tmp"

## needed if chrooting on non-gentoo based systems
#test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
#mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
#chmod 1777 /dev/shm

## needed for os-prober to test EFI system partition
#mkdir -p $ROOT_MOUNT_DIR/run/udev
#mount -o bind /run/udev $ROOT_MOUNT_DIR/run/udev
#mount --make-rslave $ROOT_MOUNT_DIR/run/udev

# chroot into our new root
echo "Chrooting into $ROOT_MOUNT_DIR"
env -i HOME=/root TERM=$TERM /usr/bin/chroot $ROOT_MOUNT_DIR /bin/bash -l

# unmount chroot on exit
echo -e "Unmounting ${ROOT_MOUNT_DIR}"
[[ $(findmnt -M "${ROOT_MOUNT_DIR}${META_REPO_DIR}") ]] && umount -lR "${ROOT_MOUNT_DIR}${META_REPO_DIR}"
[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTFILES_DIR}") ]] && umount -lR "${ROOT_MOUNT_DIR}${DISTFILES_DIR}"
if [[ $(ispart) ]]; then
	umount -lR $ROOT_MOUNT_DIR
else
	umount -lR $ROOT_MOUNT_DIR{/dev,/sys,/proc,/tmp}
fi
