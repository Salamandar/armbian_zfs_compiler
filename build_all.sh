#!/usr/bin/env bash
set -eEux
kernel_version=legacy
zfs_version=2.0.0-rc6


# Get ZFS source code
sudo apt install --no-install-recommends --yes git
if [[ ! -d zfs ]]; then git clone https://github.com/openzfs/zfs.git; else git -C zfs fetch; fi
git -C zfs clean -xdf
git -C zfs checkout "zfs-${zfs_version}"

# Get linux kernel headers
apt-get download "linux-headers-${kernel_version}-rockchip64"

# Create builder images
pushd module_builder
    docker build . -t zfs_builder/module:latest
popd

pushd utils_builder
    docker build . -t zfs_builder/utils:latest
popd


git -C zfs clean -xdf
docker run -it --rm -v $(pwd):/build_zfs zfs_builder/module /build_zfs/build_in_docker.sh
sudo mv zfs/*.deb module_builder

git -C zfs clean -xdf
docker run -it --rm -v $(pwd):/build_zfs zfs_builder/utils /build_zfs/build_in_docker.sh
sudo mv zfs/*.deb utils_builder
