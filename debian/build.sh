#!/bin/bash
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6ED0E7B82643E131
update-ca-certificates
apt-key update
apt-get update
set -e

PACKAGES="bluez wireless-regdb wpasupplicant ca-certificates debian-archive-keyring dosfstools binutils file tree bash-completion u-boot-menu openssh-server network-manager dnsmasq-base libpam-systemd ppp libengine-pkcs11-openssl iptables systemd-timesyncd vim usbutils parted exfatprogs systemd-sysv i2c-tools net-tools ethtool avahi-utils sudo gnupg rsync gpiod u-boot-tools libubootenv-tool"

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
sed -i '/image rootfs.ext4 {/,/}/s/size = .*/size = 1G/' device/$BOARD/genimage.cfg

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

# chroot into the rootfs we just created
echo "==========  CHROOT $ROOTFS =========="
chroot $ROOTFS qemu-riscv64-static /bin/sh /bootstrap.sh
echo "========== EXIT CHROOT =========="

rm $ROOTFS/bootstrap.sh

if [ -L ${OUTPUT_DIR}/fs ]; then
  rm ${OUTPUT_DIR}/fs
fi

ln -s $ROOTFS ${OUTPUT_DIR}/fs
ln -s $ROOTFS ${OUTPUT_DIR}/br-rootfs
cd /duo-buildroot-sdk/install
/duo-buildroot-sdk/device/gen_burn_image_sd.sh $OUTPUT_DIR
