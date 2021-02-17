#!/usr/bin/env bash
set -eEux

zfs_version=2.0.1
kernel_version="$(uname -r)"

get_zfs_sources() {
    # Get ZFS source code
    if ! command -v git;then sudo apt install --no-install-recommends --yes git; fi
    if [[ ! -d zfs ]]; then git clone https://github.com/openzfs/zfs.git; else git -C zfs fetch; fi
    sudo git -C zfs clean -xdf
    git -C zfs checkout "zfs-${zfs_version}"
}

get_kernel_headers() {
    # Get linux kernel headers
    apt-get download "linux-headers-current-rockchip64"
}

generate_builder() {
    part="$1"
    # Create or update image
    docker build "builder_${part}" -t "zfs_builder/${part}:latest"
}

build_zfs() {
    part="$1"
    docker run -it --rm \
        -v "$(pwd)":/build_zfs \
        -e kernel_version="$kernel_version" \
        -e config="$part" \
        "zfs_builder/${part}" \
        /build_zfs/build_in_docker.sh
    sudo mv zfs/*.deb "builder_${part}"
    sudo git -C zfs clean -xdf
}

move_packets_to_output() {
    mkdir -p output
    cp "builder_kernel/kmod-zfs-$kernel_version"*.deb output
    cp builder_user/lib*.deb output
    cp builder_user/*pyzfs*.deb output
}

parts=(
    kernel
    user
)
get_zfs_sources
get_kernel_headers
for part in "${parts[@]}"; do
    generate_builder "$part"
    build_zfs "$part"
done

move_packets_to_output

echo "Finished !"
echo "You can now install the modules present in the 'output' directory with this command:"
echo
echo "    sudo dpkg -i output/*.deb"
