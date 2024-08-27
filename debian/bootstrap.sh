#!/bin/bash
set -ex
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
mount proc -t proc /proc
mount -B sys /sys
mount -B run /run
mount -B dev /dev
# Update sources
cat >/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian sid main non-free-firmware
EOF

# update and install some packages
apt-get update
apt-get install -y util-linux haveged openssh-server systemd kmod initramfs-tools conntrack ebtables ethtool iproute2 iptables mount socat ifupdown iputils-ping neofetch sudo chrony pciutils
dpkg --configure -a
unset DEBIAN_FRONTEND DEBCONF_NONINTERACTIVE_SEEN

# Create base config files
mkdir -p /etc/network
cat >>/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto end0
iface end0 inet dhcp

EOF

cat >/etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

cat >/etc/fstab <<EOF
# <file system>	<mount pt>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext2	rw,noauto	0	1
proc		/proc		proc	defaults	0	0
devpts		/dev/pts	devpts	defaults,gid=5,mode=620,ptmxmode=0666	0	0
tmpfs		/dev/shm	tmpfs	mode=0777	0	0
tmpfs		/tmp		tmpfs	mode=1777	0	0
tmpfs		/run		tmpfs	mode=0755,nosuid,nodev,size=64M	0	0
sysfs		/sys		sysfs	defaults	0	0
#/dev/mmcblk0p3  none            swap    sw              0       0
EOF

# set hostname
echo "duos-debian" > /etc/hostname

# enable root login through ssh
sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config

# set root passwd
echo "root:$ROOTPW" | chpasswd
