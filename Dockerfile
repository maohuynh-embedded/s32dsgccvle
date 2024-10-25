FROM debian:bullseye as s32dsgccvle-setup
ENV TZ=Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive

# Set the timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install essential packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential gcc-multilib g++-multilib wget sudo less vim-tiny \
    zlib1g-dev autoconf autogen bison flex gettext libtool-bin m4 \
    expect dejagnu texinfo automake tcl-dev file \
    texlive libgmp-dev libmpfr-dev libmpc-dev \
    && dpkg --add-architecture i386 && apt-get update \
    && apt-get install -y libncurses-dev:i386 zlib1g-dev:i386

# Add user
RUN useradd -c 'User' -G sudo -m -g users user

# Don't require password for sudo
RUN perl -i -pe 's/(%sudo.*) ALL/\1 NOPASSWD: ALL/' /etc/sudoers

USER user
# Set the home directory for the user
ENV HOME=/home/user
WORKDIR ${HOME}

# Start build stage
FROM s32dsgccvle-setup as s32dsgccvle-build
COPY S32DS_PA_2017.R1_GCC.tar /home/user/S32DS_PA_2017.R1_GCC.tar

# Create necessary directories
RUN mkdir -p src/s32ds bin build
WORKDIR src/s32ds

# Extract the source tarball
RUN tar -xf ~/S32DS_PA_2017.R1_GCC.tar

WORKDIR ${HOME}/bin
RUN ln -s ${HOME}/src/s32ds/source_release/build_gnu/build.sh .

# Set environment variables for the build
ENV HOSTNAME=s32dsgccvle
RUN echo "REPODIR=${HOME}/src/s32ds/source_release" > build.env-${HOSTNAME} && \
    echo "RELEASEDIR=${HOME}/src/s32ds/source_release" >> build.env-${HOSTNAME} && \
    echo "NJOBS=\"-j 16\"" >> build.env-${HOSTNAME} && \
    echo "export PATH=${HOME}/src/s32ds/source_release/fake_32bit_tools:${HOME}/bin:\$PATH" >> build.env-${HOSTNAME}

WORKDIR ${HOME}/build
ENV PATH=${PATH}:${HOME}/bin

# Fix for build.sh using hostname to pick up environment file
RUN perl -i -pe "s/\`hostname\`/${HOSTNAME}/" ${HOME}/src/s32ds/source_release/build_gnu/build.sh

# Run the build process
RUN build.sh s=F494 ELe200
RUN build.sh -s Xbin s=F494 ELe200

# Modify download prerequisites script
RUN perl -i -pe 's/wget/#wget/' "opt/freescale/ELe200/gcc-4.9.4/contrib/download_prerequisites"

# Copy necessary files for the build
COPY cloog-0.18.1.tar.gz gmp-4.3.2.tar.bz2 isl-0.12.2.tar.bz2 \
     mpc-0.8.1.tar.gz mpfr-2.4.2.tar.bz2 \
     opt/freescale/ELe200/gcc-4.9.4/

# Execute the download prerequisites script
RUN (cd opt/freescale/ELe200/gcc-4.9.4 && contrib/download_prerequisites)

# Continue the build process
RUN build.sh -s EgccM s=F494 ELe200
RUN build.sh -s newlib s=F494 ELe200
RUN build.sh -s Egcc s=F494 ELe200

# Remove fallthrough attribute for compatibility
RUN grep -lr '__attribute__ *((fallthrough))' opt/freescale/ELe200/src_gdb | xargs perl -i -pe 's/ __attribute__\s*\(\(fallthrough\)\);//'

# Build GDB with Python enabled
RUN build.sh -s EgdbPy s=F494 ELe200

# Bundle the build output
RUN build.sh -s tar s=F494 ELe200
