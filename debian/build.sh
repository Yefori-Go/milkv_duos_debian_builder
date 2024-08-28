#!/bin/bash
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6ED0E7B82643E131
update-ca-certificates
apt-key update
apt-get update
set -e

PACKAGES="bluez wireless-regdb wpasupplicant ca-certificates debian-archive-keyring dosfstools binutils file tree bash-completion u-boot-menu openssh-server network-manager dnsmasq-base libpam-systemd ppp libengine-pkcs11-openssl iptables systemd-timesyncd vim usbutils parted exfatprogs systemd-sysv i2c-tools net-tools ethtool avahi-utils sudo gnupg rsync gpiod u-boot-tools libubootenv-tool gawk libc6 libtinfo6 libacl1 libattr1 libgmp10 libselinux1 libssl3t64 bzip2 liblzma5 libmd0 libzstd1 zlib1g libpcre2-8-0  libcrypt1 libpam-modules-bin debconf libpam0g libdb5.3t64 libaudit1 libsystemd0 dpkg libacl1 libpam-modules libpam-runtime libblkid1 libcap-ng0 libmount1 libsmartcols1 libudev1 libuuid1"

SPATH=$(dirname "$(realpath "$0")")

source $SPATH/ENV

if [ -z "$BOARD" ]; then
    echo "The BOARD variable is not set. Exiting..."
    exit 1
fi

if [ -z "$CONFIG" ]; then
    echo "The CONFIG variable is not set. Exiting..."
    exit 1
fi

echo "$BOARD $CONFIG"

cd /duo-buildroot-sdk

#Make sure we have room to work with
sed -i 's/size = 768M/size = 1G/g' device/$BOARD/genimage.cfg

source device/$BOARD/boardconfig.sh
source build/milkvsetup.sh
defconfig $CONFIG

echo "Updating Kernel /duo-buildroot-sdk/build/boards/$CHIP_SEGMENT/$CONFIG/linux/*milkv*_defconfig"
cat /build/kernel.conf >> /duo-buildroot-sdk/build/boards/$CHIP_SEGMENT/$CONFIG/linux/*milkv*_defconfig

clean_all
build_all

ROOTFS=${OUTPUT_DIR}/rootfs-debian
mkdir -p $ROOTFS

# generate minimal bootstrap rootfs
update-binfmts --enable
# debootstrap --exclude vim --arch=riscv64 --foreign $DISTRO $ROOTFS $BASE_URL
mmdebstrap -v --architectures=riscv64 --include="$PACKAGES" sid "$ROOTFS" "deb http://deb.debian.org/debian/ sid main"

cp -rf /usr/bin/qemu-riscv64-static $ROOTFS/usr/bin/
cp /bootstrap.sh $ROOTFS/.

mkdir -p /addons
cd /addons
# add aic8800-firmware
echo "Installing aic8800-firmware for $BOARD"
rm -rf aic8800-firmware
git clone --depth 1 https://github.com/armbian/firmware.git aic8800-firmware
mkdir -p $ROOTFS/lib/firmware/aic8800_sdio/aic8800/
cp -a aic8800-firmware/aic8800/SDIO/aic8800/ $ROOTFS/lib/firmware/aic8800_sdio/
# 	This is the DUOS firmware
cp -a aic8800-firmware/aic8800/SDIO/aic8800D80/* $ROOTFS/lib/firmware/aic8800_sdio/aic8800/

cd /duo-buildroot-sdk

# chroot into the rootfs we just created
echo "==========  CHROOT $ROOTFS =========="
chroot $ROOTFS qemu-riscv64-static /bin/sh /bootstrap.sh
echo "========== EXIT CHROOT =========="
umount $ROOTFS/proc || true 
umount $ROOTFS/sys || true 
umount $ROOTFS/run || true 
umount $ROOTFS/dev || true

rm $ROOTFS/bootstrap.sh

if [ -L ${OUTPUT_DIR}/fs ]; then
  rm ${OUTPUT_DIR}/fs
fi

ln -s $ROOTFS ${OUTPUT_DIR}/fs
ln -s $ROOTFS ${OUTPUT_DIR}/br-rootfs
cd /duo-buildroot-sdk/install
/duo-buildroot-sdk/device/gen_burn_image_sd.sh $OUTPUT_DIR
