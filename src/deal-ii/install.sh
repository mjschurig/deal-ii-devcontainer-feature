#!/bin/bash
set -e

# deal.II devcontainer feature installation script
echo "Installing deal.II..."

# Feature options
DEALII_VERSION="${VERSION:-9.5.0}"
ENABLE_MPI="${ENABLEMPI:-false}"
ENABLE_PETSC="${ENABLEPETSC:-false}"
BUILD_THREADS="${BUILDTHREADS:-4}"

# Determine architecture
ARCHITECTURE="$(dpkg --print-architecture)"
echo "Architecture: ${ARCHITECTURE}"

# Install base dependencies
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    wget \
    ca-certificates \
    libboost-all-dev \
    libblas-dev \
    liblapack-dev \
    zlib1g-dev \
    git

# Install optional MPI support
if [ "${ENABLE_MPI}" = "true" ]; then
    echo "Installing MPI support..."
    apt-get install -y --no-install-recommends \
        libopenmpi-dev \
        openmpi-bin \
        openmpi-common
fi

# Install optional PETSc support
if [ "${ENABLE_PETSC}" = "true" ]; then
    echo "Installing PETSc..."
    apt-get install -y --no-install-recommends \
        petsc-dev \
        libpetsc-real-dev
fi

# Create temporary build directory
BUILD_DIR="/tmp/dealii-build"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Download deal.II source
echo "Downloading deal.II ${DEALII_VERSION}..."
wget -q https://github.com/dealii/dealii/releases/download/v${DEALII_VERSION}/dealii-${DEALII_VERSION}.tar.gz
tar -xzf dealii-${DEALII_VERSION}.tar.gz
cd dealii-${DEALII_VERSION}

# Configure deal.II
echo "Configuring deal.II..."
mkdir build && cd build

CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local/deal.II"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_MPI=${ENABLE_MPI}"

if [ "${ENABLE_PETSC}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_PETSC=ON"
fi

# Configure with minimal features for a lean installation
cmake .. ${CMAKE_ARGS} \
    -DDEAL_II_COMPONENT_DOCUMENTATION=OFF \
    -DDEAL_II_COMPONENT_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release

# Build and install
echo "Building deal.II (this may take a while)..."
make -j${BUILD_THREADS}
make install

# Clean up
cd /
rm -rf ${BUILD_DIR}
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "deal.II installation complete!"
echo "DEAL_II_DIR is set to /usr/local/deal.II" 