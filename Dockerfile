FROM debian:stretch as s32dsgccvle-setup

# Set environment variables
ENV TZ=Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/user

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Update and install necessary packages
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential gcc-multilib g++-multilib \
        wget sudo less vim-tiny \
        zlib1g-dev autoconf autogen bison flex gettext libtool-bin m4 \
        expect dejagnu texinfo automake tcl-dev file \
        texlive libgmp-dev libmpfr-dev libmpc-dev \
        libncurses-dev:i386 zlib1g-dev:i386 libpython-dev:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add user and configure sudo
RUN useradd -c 'User' -G sudo -m -g users user \
    && perl -i -pe 's/(%sudo.*) ALL/\1 NOPASSWD: ALL/' /etc/sudoers

USER user
WORKDIR ${HOME}

# Set up the build environment
FROM s32dsgccvle-setup as s32dsgccvle-build

# Copy the toolchain tarball
COPY S32DS_PA_2017.R1_GCC.tar ${HOME}/S32DS_PA_2017.R1_GCC.tar

RUN mkdir -p src/s32ds bin build && \
    cd src/s32ds && \
    tar -xf ${HOME}/S32DS_PA_2017.R1_GCC.tar

ENV SRCDIR=${HOME}/src/s32ds/source_release
WORKDIR ${HOME}/bin
RUN ln -s ${SRCDIR}/build_gnu/build.sh .

ENV HOSTNAME=s32dsgccvle

# Create build environment variables
RUN echo "REPODIR=${SRCDIR}" > build.env-${HOSTNAME} && \
    echo "RELEASEDIR=${SRCDIR}" >> build.env-${HOSTNAME} && \
    echo "NJOBS=\"-j 16\"" >> build.env-${HOSTNAME} && \
    echo "export PATH=${SRCDIR}/fake_32bit_tools:${HOME}/bin:\$PATH" >> build.env-${HOSTNAME}

WORKDIR ${HOME}/build

# Update PATH
ENV PATH=${PATH}:${HOME}/bin

# Fix for build.sh using hostname to pick up environment file
RUN perl -i -pe "s/\`hostname\`/${HOSTNAME}/" ${SRCDIR}/build_gnu/build.sh

# Run builds
RUN build.sh s=F494 ELe200 && \
    build.sh -s Xbin s=F494 ELe200

# Disable wget in download_prerequisites
RUN perl -i -pe 's/wget/#wget/' "opt/freescale/ELe200/gcc-4.9.4/contrib/download_prerequisites"

# Copy required archives for building
COPY cloog-0.18.1.tar.gz gmp-4.3.2.tar.bz2 \
     isl-0.12.2.tar.bz2 mpc-0.8.1.tar.gz mpfr-2.4.2.tar.bz2 \
     opt/freescale/ELe200/gcc-4.9.4/

RUN (cd opt/freescale/ELe200/gcc-4.9.4 && contrib/download_prerequisites)

# Additional builds
RUN build.sh -s EgccM s=F494 ELe200 && \
    build.sh -s newlib s=F494 ELe200 && \
    build.sh -s Egcc s=F494 ELe200 && \
    grep -lr '__attribute__ *((fallthrough))' opt/freescale/ELe200/src_gdb | \
    xargs perl -i -pe 's/ __attribute__\s*\(\(fallthrough\)\);//' && \
    build.sh -s EgdbPy s=F494 ELe200 && \
    build.sh -s tar s=F494 ELe200
