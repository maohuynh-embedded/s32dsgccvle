#!/bin/sh
set -e

download_tarball() {
    baseurl=$1
    filename=$2

    # Check if the file already exists
    if [ ! -e "$filename" ]; then
        echo "Downloading $filename..."
        wget "$baseurl/$filename" || { echo "Failed to download $filename"; exit 1; }
    fi

    # Check for the checksum file and validate it
    if [ -e "$filename.sha256" ]; then
        if shasum -c "$filename.sha256" 2>/dev/null; then
            echo "SHA-256 for $filename matches."
        else
            echo "SHA-256 for $filename does not match. Deleting file."
            rm -f "$filename"
            exit 1
        fi
    else
        echo "Checksum file for $filename not found."
        exit 1
    fi
}

# Download required tarballs
download_tarball "https://www.nxp.com/lgfiles/updates/S32DS" "S32DS_PA_2017.R1_GCC.tar"
download_tarball "ftp://gcc.gnu.org/pub/gcc/infrastructure" "mpfr-2.4.2.tar.bz2"
download_tarball "ftp://gcc.gnu.org/pub/gcc/infrastructure" "gmp-4.3.2.tar.bz2"
download_tarball "ftp://gcc.gnu.org/pub/gcc/infrastructure" "mpc-0.8.1.tar.gz"
download_tarball "ftp://gcc.gnu.org/pub/gcc/infrastructure" "isl-0.12.2.tar.bz2"
download_tarball "ftp://gcc.gnu.org/pub/gcc/infrastructure" "cloog-0.18.1.tar.gz"

# Build Docker container with network connectivity
echo "Building Docker container with network connectivity..."
docker build --target s32dsgccvle-setup -t s32dsgccvle .

# Build Docker container without external network connectivity
echo "Building Docker container without external network connectivity..."
docker build --target s32dsgccvle-build --network=none -t s32dsgccvle .
