#!/bin/sh

TARBALL=gcc-4.9.4-Ee200-eabivle-i686-linux-g.tar.bz2

# Check if the tarball exists
if [ ! -f "../$TARBALL" ]; then
    echo "Error: Tarball ${TARBALL} does not exist."
    exit 1
fi

# Navigate to the source directory
cd src/s32ds || { echo "Failed to change directory to src/s32ds"; exit 1; }

# Check if the source_release directory exists
if [ ! -d "source_release" ]; then
    echo "Directory source_release does not exist."
    exit 1
fi

# Run the Docker command to extract the tarball
if ! docker run --rm s32dsgccvle tar -C /source/directory -cf - "${TARBALL}" | tar -xjf - -C source_release; then
    echo "Error: Failed to extract ${TARBALL}."
    exit 1
fi

echo "Extraction of ${TARBALL} completed successfully."
