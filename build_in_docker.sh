#!/usr/bin/env bash
set -eEux

: "${header_pkg_version:=legacy}"
kernel_version=$(uname -r)

cd /build_zfs
if ! dpkg -i linux-headers-${header_pkg_version}-rockchip64*.deb; then
    sed -i '/+= selinux/s/^/# /' "/usr/src/linux-headers-${kernel_version}/scripts/Makefile"
    dpkg-reconfigure "linux-headers-${header_pkg_version}-rockchip64"
fi

# Disable all STACKPROTECT options incompatible with GCC, this means the
# built kernel module (kmod) will be non-functional. That's OK since
# we're only interested in building the tools on Armbian.
if grep buster /etc/os-release; then
    sed -i -e 's/\(.*STACKPROTECT.*=\)y/\1n/' "/usr/src/linux-headers-${kernel_version}/.config"
fi

pushd zfs
    sh autogen.sh
    ./configure --with-linux="/usr/src/linux-headers-${kernel_version}"
    make -s -j$(nproc)
    make -s -j$(nproc) deb
popd
