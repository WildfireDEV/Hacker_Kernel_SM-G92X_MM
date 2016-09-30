#!/bin/bash

export ARCH=arm64
export CROSS_COMPILE=/home/builder/toolchains/6.0/bin/aarch64-linux-android-

make ARCH=arm64 continuum_defconfig
make ARCH=arm64
