# Use an Ubuntu base image
FROM ubuntu:22.04 as builder

ARG BOARD=milkv-duos-sd
ENV BOARD=${BOARD}

ENV DEBIAN_FRONTEND=non-interactive
ENV BUILD_OUTPUT=/build-output


RUN apt-get update \
    && apt-get install -y \
    wget git make build-essential libtool rsync \
    ca-certificates gnupg joe --no-install-recommends


#Requied for duo-buildroot-sdk
RUN apt install -y pkg-config build-essential ninja-build automake autoconf libtool wget curl git gcc libssl-dev bc slib squashfs-tools android-sdk-libsparse-utils jq python3-distutils scons parallel tree python3-dev python3-pip device-tree-compiler ssh cpio fakeroot libncurses5 flex bison libncurses5-dev genext2fs rsync unzip dosfstools mtools tcl openssh-client cmake expect

#Required for debian build
RUN apt install -y debian-archive-keyring mmdebstrap qemu qemu-user qemu-user-static arch-test binfmt-support dpkg-cross  --no-install-recommends

RUN update-ca-certificates

WORKDIR /

RUN git clone https://github.com/milkv-duo/duo-buildroot-sdk.git --depth=1

WORKDIR duo-buildroot-sdk

RUN wget https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz
RUN tar -xf host-tools.tar.gz
RUN rm host-tools.tar.gz

COPY debian/bootstrap.sh /.

RUN apt-get clean
RUN rm -rf /var/cache/apt/



FROM builder as builder_image
WORKDIR /duo-buildroot-sdk

CMD /bin/bash