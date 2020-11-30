#!/usr/bin/env bash
set -eEux

kernel_version=legacy

cd /build_zfs
dpkg -i linux-headers-${kernel_version}-*.deb || true
sed -i '/+= selinux/s/^/# /' /usr/src/linux-headers-*-rockchip64/scripts/Makefile
dpkg-reconfigure "linux-headers-${kernel_version}-rockchip64"

# Disable all STACKPROTECT options incompatible with GCC, this means the
# built kernel module (kmod) will be non-functional. That's OK since
# we're only interested in building the tools on Armbian.
if grep buster /etc/os-release; then
    sed -i -e 's/\(.*STACKPROTECT.*=\)y/\1n/' /usr/src/linux-headers-$(uname -r)/.config
fi

pushd zfs
    sh autogen.sh
    ./configure
    make -s -j$(nproc)
    make -s -j$(nproc) deb
popd

mv zfs/*.deb module_builder
