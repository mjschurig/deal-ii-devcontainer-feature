#!/bin/bash
set -e

# deal.II devcontainer feature installation script
echo "Installing deal.II..."

# Feature options
DEALII_VERSION="${VERSION:-9.5.0}"
ENABLE_MPI="${ENABLEMPI:-false}"
ENABLE_PETSC="${ENABLEPETSC:-false}"
BUILD_THREADS="${BUILDTHREADS:-4}"

# Logging functions
print_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" 1>&2
}

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

# OS Detection - following best practices
. /etc/os-release
ARCHITECTURE="$(dpkg --print-architecture)"

print_info "Detected OS: ${ID} ${VERSION_ID} (${VERSION_CODENAME})"
print_info "Architecture: ${ARCHITECTURE}"

# Check for supported distributions
SUPPORTED_DISTRIBUTIONS="debian ubuntu"
if [[ ! " ${SUPPORTED_DISTRIBUTIONS} " =~ " ${ID} " ]]; then
    print_error "Unsupported distribution '${ID}'. This feature only supports: ${SUPPORTED_DISTRIBUTIONS}"
    exit 1
fi

# Version-specific checks for Debian/Ubuntu
SUPPORTED_DEBIAN_CODENAMES="buster bullseye bookworm"
SUPPORTED_UBUNTU_CODENAMES="focal jammy lunar mantic"

if [ "${ID}" = "debian" ] && [[ ! " ${SUPPORTED_DEBIAN_CODENAMES} " =~ " ${VERSION_CODENAME} " ]]; then
    print_error "Unsupported Debian version '${VERSION_CODENAME}'. Supported versions: ${SUPPORTED_DEBIAN_CODENAMES}"
    exit 1
elif [ "${ID}" = "ubuntu" ] && [[ ! " ${SUPPORTED_UBUNTU_CODENAMES} " =~ " ${VERSION_CODENAME} " ]]; then
    print_error "Unsupported Ubuntu version '${VERSION_CODENAME}'. Supported versions: ${SUPPORTED_UBUNTU_CODENAMES}"
    exit 1
fi

# Feature Idempotency - Check if deal.II is already installed
if [ -d "/usr/local/deal.II" ] && [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    print_info "deal.II appears to be already installed at /usr/local/deal.II"
    
    # Check installed version if possible
    if command -v cmake &> /dev/null; then
        INSTALLED_VERSION=$(cmake -DDEAL_II_DIR=/usr/local/deal.II -P /dev/stdin <<< "
            find_package(deal.II QUIET)
            if(deal.II_FOUND)
                message(\${DEAL_II_VERSION})
            endif()
        " 2>&1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        
        if [ "${INSTALLED_VERSION}" = "${DEALII_VERSION}" ]; then
            print_info "Requested version ${DEALII_VERSION} is already installed. Skipping installation."
            exit 0
        else
            print_info "Different version installed (${INSTALLED_VERSION}). Installing version ${DEALII_VERSION}..."
            # For now, we'll proceed with installation. In future, we could support multiple versions.
        fi
    fi
fi

# Non-root user detection - following best practices
USERNAME="${_REMOTE_USER:-vscode}"
USER_UID="${_REMOTE_USER_UID:-1000}"
USER_GID="${_REMOTE_USER_GID:-1000}"
USER_HOME="${_REMOTE_USER_HOME:-/home/${USERNAME}}"

print_info "Target user: ${USERNAME} (UID: ${USER_UID}, GID: ${USER_GID})"

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
    git \
    curl

# Install optional MPI support
if [ "${ENABLE_MPI}" = "true" ]; then
    print_info "Installing MPI support..."
    apt-get install -y --no-install-recommends \
        libopenmpi-dev \
        openmpi-bin \
        openmpi-common
fi

# Install optional PETSc support
if [ "${ENABLE_PETSC}" = "true" ]; then
    print_info "Installing PETSc..."
    apt-get install -y --no-install-recommends \
        petsc-dev \
        libpetsc-real-dev || {
            print_error "Failed to install PETSc. It may not be available in the package repository."
            print_info "Continuing without PETSc support..."
            ENABLE_PETSC="false"
        }
fi

# Create temporary build directory
BUILD_DIR="/tmp/dealii-build-$$"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Function to download deal.II with fallback strategies
download_dealii() {
    local version=$1
    local download_successful=false
    
    # Strategy 1: Try GitHub releases
    print_info "Attempting to download deal.II ${version} from GitHub releases..."
    if wget -q --spider "https://github.com/dealii/dealii/releases/download/v${version}/dealii-${version}.tar.gz"; then
        wget -q "https://github.com/dealii/dealii/releases/download/v${version}/dealii-${version}.tar.gz" && download_successful=true
    fi
    
    # Strategy 2: Try GitHub archive (if release download fails)
    if [ "${download_successful}" = "false" ]; then
        print_info "GitHub release not found. Trying GitHub archive..."
        if wget -q --spider "https://github.com/dealii/dealii/archive/v${version}.tar.gz"; then
            wget -q "https://github.com/dealii/dealii/archive/v${version}.tar.gz" -O "dealii-${version}.tar.gz" && download_successful=true
        fi
    fi
    
    # Strategy 3: Clone from git (last resort)
    if [ "${download_successful}" = "false" ]; then
        print_info "Download failed. Trying to clone from git..."
        if git clone --depth 1 --branch "v${version}" https://github.com/dealii/dealii.git "dealii-${version}"; then
            download_successful=true
        fi
    fi
    
    if [ "${download_successful}" = "false" ]; then
        print_error "Failed to download deal.II ${version} from any source."
        return 1
    fi
    
    return 0
}

# Download deal.II source
if ! download_dealii "${DEALII_VERSION}"; then
    # Clean up and exit
    cd /
    rm -rf ${BUILD_DIR}
    exit 1
fi

# Extract if it's a tarball
if [ -f "dealii-${DEALII_VERSION}.tar.gz" ]; then
    tar -xzf "dealii-${DEALII_VERSION}.tar.gz"
fi

cd "dealii-${DEALII_VERSION}"

# Configure deal.II
print_info "Configuring deal.II..."
mkdir -p build && cd build

CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local/deal.II"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_MPI=${ENABLE_MPI}"

if [ "${ENABLE_PETSC}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_PETSC=ON"
fi

# Configure with minimal features for a lean installation
cmake .. ${CMAKE_ARGS} \
    -DDEAL_II_COMPONENT_DOCUMENTATION=OFF \
    -DDEAL_II_COMPONENT_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release || {
        print_error "CMake configuration failed."
        cd /
        rm -rf ${BUILD_DIR}
        exit 1
    }

# Build and install
print_info "Building deal.II (this may take a while)..."
make -j${BUILD_THREADS} || {
    print_error "Build failed. Trying with single thread..."
    make -j1 || {
        print_error "Build failed even with single thread."
        cd /
        rm -rf ${BUILD_DIR}
        exit 1
    }
}

make install

# Set proper permissions for non-root user
if [ "${USERNAME}" != "root" ]; then
    print_info "Setting permissions for user ${USERNAME}..."
    # Create user's local bin directory if it doesn't exist
    mkdir -p "${USER_HOME}/.local/bin"
    
    # Add deal.II to user's PATH via .bashrc if not already present
    if ! grep -q "DEAL_II_DIR" "${USER_HOME}/.bashrc" 2>/dev/null; then
        echo "export DEAL_II_DIR=/usr/local/deal.II" >> "${USER_HOME}/.bashrc"
        echo "export PATH=\${DEAL_II_DIR}/bin:\${PATH}" >> "${USER_HOME}/.bashrc"
    fi
    
    # Ensure proper ownership
    chown -R ${USER_UID}:${USER_GID} "${USER_HOME}/.local" 2>/dev/null || true
    chown ${USER_UID}:${USER_GID} "${USER_HOME}/.bashrc" 2>/dev/null || true
fi

# Clean up
cd /
rm -rf ${BUILD_DIR}
apt-get clean
rm -rf /var/lib/apt/lists/*

print_info "deal.II ${DEALII_VERSION} installation complete!"
print_info "DEAL_II_DIR is set to /usr/local/deal.II" 