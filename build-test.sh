#!/bin/bash

set -e

# define name of chroot build
BUILD_NAME="buildtest"

# define directory used for mounts
MOUNT_DIR="/mnt"

# define directory to download stage3 tarball and configs
FILES_DIR="/root/buildfiles"

# define FETCH_LINK to point to stage download link
FETCH_LINK="http://build.funtoo.org/funtoo-current"

# set ARCH as x86-64bit or x86-32bit
ARCH="x86-64bit"

# set subarch stage optimization. choose from subarches listed at https://www.funtoo.org/Subarches
SUB_ARCH="generic_64"

# define stage tarball name
STAGE_NAME="stage3-latest.tar.xz"

# define timezone
TIMEZONE="EST5EDT"

# define distfiles directory for bind mount
DISTFILES_DIR="/var/cache/portage/distfiles"

# define meta-repo directory
META_REPO_DIR="/var/git/meta-repo"

# define partitions to mount. if unset it will use directory only
ROOT_LABEL="Test-Root"
BOOT_LABEL="Test-Boot"
#ROOT_PART="/dev/sda#"
#BOOT_PART="/dev/sda#"
#ROOT_SUBVOL="@"

ROOT_MOUNT_DIR="${MOUNT_DIR}/${BUILD_NAME}"

ispart() {
# check if using directories or physical partitions
	for i in ${1}{_LABEL,_PART,_SUBVOL}; do
		[[ ! -z "${!i}" ]] && echo "${!i}" && return
	done
}

unmountdirs() {
# unmount directories, partitions, and binds
	echo -e "Unmounting ${ROOT_MOUNT_DIR}"
	[[ $(findmnt -M "${ROOT_MOUNT_DIR}${META_REPO_DIR}") ]] && umount -lR "${ROOT_MOUNT_DIR}${META_REPO_DIR}"
	[[ $(findmnt -M "${ROOT_MOUNT_DIR}${DISTFILES_DIR}") ]] && umount -lR "${ROOT_MOUNT_DIR}${DISTFILES_DIR}"
	[[ $(ispart ROOT) ]] && umount -lR $ROOT_MOUNT_DIR || umount -lR $ROOT_MOUNT_DIR{/dev,/sys,/proc,/tmp}
	exit 1
}

createnmount() {
# mount physical filesystems and create directories if they don't exist
	[[ -e "$ROOT_MOUNT_DIR" ]] && ( echo -e "Using $ROOT_MOUNT_DIR"; return 0 ) || { mkdir $ROOT_MOUNT_DIR && echo "Creating directory $ROOT_MOUNT_DIR"; }

	[[ $(ispart ROOT) ]] && { mount ${ROOT_SUBVOL/#/-o subvol= }${ROOT_PART}${ROOT_LABEL/#/LABEL=} $ROOT_MOUNT_DIR; \
		echo "Mounting: ROOT: ${ROOT_SUBVOL/#/-o subvol= }${ROOT_PART}${ROOT_LABEL/#/LABEL=} @: $ROOT_MOUNT_DIR"; }

	( [[ $(ispart BOOT) ]] && [ -e "$ROOT_MOUNT_DIR/boot" ] ) && { mount ${BOOT_PART}${BOOT_LABEL/#/LABEL=} "$ROOT_MOUNT_DIR/boot"; \
		echo "Mounting: BOOT: ${BOOT_PART}${BOOT_LABEL/#/LABEL=} @: $ROOT_MOUNT_DIR/boot"; }
	( [[ $(ispart BOOT) ]] && [ ! -e "$ROOT_MOUNT_DIR/boot" ] ) && { mkdir "$ROOT_MOUNT_DIR/boot"; echo "Creating directory $ROOT_MOUNT_DIR/boot"; \
		mount ${BOOT_PART}${BOOT_LABEL/#/LABEL=} "$ROOT_MOUNT_DIR/boot"; echo "Mounting: BOOT: ${BOOT_PART}${BOOT_LABEL/#/LABEL=} @: $ROOT_MOUNT_DIR/boot"; }
return 0
}

fetchnunpack() {
# fetch copy and unpack stage3
	if [ ! -e $FILES_DIR/$STAGE_NAME ]; then
		echo "No stage3 found, fetching:"
		cd $FILES_DIR
		wget $FETCH_LINK/$ARCH/$SUB_ARCH/$STAGE_NAME
	fi

	if [ ! -e $ROOT_MOUNT_DIR/".unpacked" ]; then
		echo "Unpacking stage3 to $ROOT_MOUNT_DIR"
		cp $FILES_DIR/$STAGE_NAME $ROOT_MOUNT_DIR
		cd $ROOT_MOUNT_DIR
		tar -xpf $STAGE_NAME || return 1
		touch $ROOT_MOUNT_DIR/".unpacked" && echo $(date) >> $ROOT_MOUNT_DIR/".unpacked"
	fi
}

dnscopy() {
# copy DNS info
	cp -L /etc/resolv.conf $ROOT_MOUNT_DIR/etc
	echo "Copying resolv.conf to $ROOT_MOUNT_DIR/etc"
}

repomount() {
# bind mount meta-repo git
	if [ -e "$ROOT_MOUNT_DIR${META_REPO_DIR}" ]; then
		mount --bind $META_REPO_DIR $ROOT_MOUNT_DIR${META_REPO_DIR}
	else
		mkdir -p $ROOT_MOUNT_DIR${META_REPO_DIR}
		mount --bind $META_REPO_DIR $ROOT_MOUNT_DIR${META_REPO_DIR}
	fi

	echo "Bind mounting $META_REPO_DIR"
}

distfilesmount() {
# bind mount distfiles
	[ -e ${ROOT_MOUNT_DIR}${DISTFILES_DIR} ] || mkdir -p ${ROOT_MOUNT_DIR}${DISTFILES_DIR}
	mount --bind $DISTFILES_DIR ${ROOT_MOUNT_DIR}${DISTFILES_DIR}
	echo "Bind mounting $DISTFILES_DIR"
}

configcopy() {
# copy fstab from $FILES_DIR
	( [[ $(ispart ROOT) ]] && [ -e $FILES_DIR/fstab ] ) && cp $FILES_DIR/fstab $ROOT_MOUNT_DIR/etc && echo "Copying fstab from $FILES_DIR"

# copy make.conf from $FILES_DIR
	[ -e $FILES_DIR/make.conf ] && cp $FILES_DIR/make.conf $ROOT_MOUNT_DIR/etc/portage && echo "Copying make.conf from $FILES_DIR"

# copy ego.conf from $FILES_DIR
	[ -e $FILES_DIR/ego.conf ] && cp $FILES_DIR/ego.conf $ROOT_MOUNT_DIR/etc && echo "Copying ego.conf from $FILES_DIR"

# set timezone
	ln -sf $ROOT_MOUNT_DIR/usr/share/zoneinfo/$TIMEZONE $ROOT_MOUNT_DIR/etc/localtime
	echo "Setting $TIMEZONE as timezone"
}

systembind() {
# mount bind proc sys dev tmp to real root
	mount -t proc /proc $ROOT_MOUNT_DIR/proc
	mount --rbind /tmp $ROOT_MOUNT_DIR/tmp

	chmod 1777 $ROOT_MOUNT_DIR/tmp

	for dir in sys dev; do
		mount --rbind /$dir $ROOT_MOUNT_DIR/$dir
		mount --make-rslave $ROOT_MOUNT_DIR/$dir
	done
	echo "Bind mounting proc,sys,dev,tmp"
}

dochroot() {
# chroot into our new root
	echo "Chrooting into $ROOT_MOUNT_DIR"
	env -i HOME=/root TERM=$TERM /usr/bin/chroot $ROOT_MOUNT_DIR /bin/bash -l
}

createnmount || echo -e "Failed to create or mount $ROOT_MOUNT_DIR"
fetchnunpack || ( echo -e "Failed to fetch or unpack $STAGENAME"; unmountdirs; exit 1 )
repomount || ( echo -e "Failed to bind mount $META_REPO_DIR"; unmountdirs; exit 1 )
distfilesmount || ( echo -e "Failed to bindmount $DISTFILES_DIR"; unmountdirs; exit 1 )
dnscopy || ( echo -e "Failed to copy resolv.conf to $ROOT_MOUNT_DIR/etc"; unmountdirs; exit 1 )
configcopy || ( echo -e "Failed to copy configs from $FILESDIR to $ROOT_MOUNT_DIR"; umountdirs; exit 1 )
systembind ||  ( echo -e "Failed to bind mount /proc /sys /dev /tmp"; unmountdirs; exit 1 )
dochroot || ( echo -e "Chroot $ROOT_MOUNT_DIR failed"; unmountdirs; exit 1 )

# unmount chroot on exit
unmountdirs
