#!/bin/sh

TARBALL=gcc-4.9.4-Ee200-eabivle-i686-linux-g.tar.bz2

# Check if the directory exists
if [ ! -d "../src/s32ds/source_release" ]; then
    echo "Directory ../src/s32ds/source_release does not exist."
    exit 1
fi

# Run the Docker command to extract the tarball
if ! docker run --rm s32dsgccvle tar -C /source/directory -cf - "${TARBALL}" | tar -xjf - -C ../src/s32ds/source_release; then
    echo "Error: Failed to extract ${TARBALL}."
    exit 1
fi

echo "Extraction completed successfully."

