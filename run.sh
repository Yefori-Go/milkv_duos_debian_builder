#!/bin/bash

SPATH=$(dirname "$(realpath "$0")")
cd $SPATH

TARGET_BUILDER=debian
ROOTPW=milkv

source $TARGET_BUILDER/ENV

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    # Not running as root, prompt for root password and rerun the script
    echo "This script needs to run with root privileges."
    sudo "$0" "$@"
    exit $?
fi

docker build $TARGET_BUILDER -t builder

if [ -d "out" ]; then
  rm -R --force out/*
fi

mkdir -p out
chmod 777 out
realpath out

docker run -it --rm --privileged -e BOARD=$BOARD -e CONFIG=$CONFIG -e ROOTPW=$ROOTPW  -v $SPATH/$TARGET_BUILDER:/build -v $SPATH/out:/duo-buildroot-sdk/install builder bash /build/build.sh

if [[ ! -d "out" ]]; then
    echo "No image found."
    exit 1
fi

# Find the first .img file within subdirectories of "out"
IMAGE=$(find out -type f -name "*.img" | head -n 1)

if [[ -z "$IMAGE" ]]; then
    echo "No image found."
    exit 1
else
    echo "Built $IMAGE"
fi