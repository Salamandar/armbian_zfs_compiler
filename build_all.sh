#!/usr/bin/env bash
set -eEux
header_pkg_version=legacy
zfs_version=2.0.0-rc6

get_zfs_sources() {
    # Get ZFS source code
    if ! command -v git;then sudo apt install --no-install-recommends --yes git; fi
    if [[ ! -d zfs ]]; then git clone https://github.com/openzfs/zfs.git; else git -C zfs fetch; fi
    sudo git -C zfs clean -xdf
    git -C zfs checkout "zfs-${zfs_version}"
}

get_kernel_headers() {
    # Get linux kernel headers
    apt-get download "linux-headers-${header_pkg_version}-rockchip64"
}

generate_builder() {
    part="$1"
    # Create or update image
    docker build "${part}_builder" -t "zfs_builder/${part}:latest"
}

build_zfs() {
    part="$1"
    docker run -it --rm \
        -v $(pwd):/build_zfs \
        -e header_pkg_version="$header_pkg_version"
        "zfs_builder/${part}" \
        /build_zfs/build_in_docker.sh
    sudo mv zfs/*.deb "${part}_builder"
    sudo git -C zfs clean -xdf
}

parts=(
    module
    utils
)
get_zfs_sources
get_kernel_headers
for part in "${parts[@]}"; do
    generate_builder "$part"
    build_zfs "$part"
done
