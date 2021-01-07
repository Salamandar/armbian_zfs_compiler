#!/usr/bin/env bash
set -eEux

# Should be passed by Docker command, but default to currently booted kernel
: "${kernel_version:=$(uname -r)}"
: "${config:=all}"

cd /build_zfs
if ! dpkg -i linux-headers-current-rockchip64*.deb; then
    sed -i '/+= selinux/s/^/# /' "/usr/src/linux-headers-${kernel_version}/scripts/Makefile"
    dpkg-reconfigure "linux-headers-current-rockchip64"
fi

# Disable all STACKPROTECT options incompatible with GCC, this means the
# built kernel module (kmod) will be non-functional. That's OK since
# we're only interested in building the tools on Armbian.
if grep buster /etc/os-release; then
    sed -i -e 's/\(.*STACKPROTECT.*=\)y/\1n/' "/usr/src/linux-headers-${kernel_version}/.config"
fi

pushd zfs
    sh autogen.sh
    ./configure --with-config="$config" --with-linux="/usr/src/linux-headers-${kernel_version}"
    make -s -j"$(nproc)"
    make -s -j"$(nproc)" deb
popd
