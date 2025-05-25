#!/bin/bash
set -e

# deal.II devcontainer feature installation script
echo "Installing deal.II..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set non-interactive mode for package installations
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

# Feature options
DEALII_VERSION="${VERSION:-9.5.0}"
ENABLE_MPI="${ENABLEMPI:-false}"
ENABLE_PETSC="${ENABLEPETSC:-false}"
ENABLE_TRILINOS="${ENABLETRILINOS:-false}"
BUILD_THREADS="${BUILDTHREADS:-4}"

# Logging functions
print_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" 1>&2
}

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

# Function to remove system Trilinos packages to prevent conflicts
remove_system_trilinos() {
    print_info "Removing any conflicting system Trilinos packages..."
    apt-get remove -y --purge \
        trilinos-all-dev \
        libtrilinos-ml-dev \
        libtrilinos-aztecoo-dev \
        libtrilinos-epetra-dev \
        libtrilinos-epetraext-dev \
        libtrilinos-ifpack-dev \
        libtrilinos-amesos-dev \
        libtrilinos-teuchos-dev \
        libtrilinos-thyra-dev \
        libtrilinos-tpetra-dev \
        libtrilinos-belos-dev \
        libtrilinos-nox-dev \
        libtrilinos-sacado-dev \
        libtrilinos-zoltan-dev \
        libtrilinos-dev \
        trilinos-dev 2>/dev/null || true
    
    # Clean up broken cmake configuration files
    rm -rf /usr/lib/x86_64-linux-gnu/cmake/Trilinos* \
           /usr/lib/x86_64-linux-gnu/cmake/ML* \
           /usr/lib/x86_64-linux-gnu/cmake/Epetra* \
           /usr/lib/x86_64-linux-gnu/cmake/EpetraExt* \
           /usr/lib/x86_64-linux-gnu/cmake/Teuchos* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosCore* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosComm* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosParameterList* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosParser* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosNumerics* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosRemainder* \
           /usr/lib/x86_64-linux-gnu/cmake/TeuchosKokko* \
           /usr/lib/x86_64-linux-gnu/cmake/AztecOO* \
           /usr/lib/x86_64-linux-gnu/cmake/Ifpack* \
           /usr/lib/x86_64-linux-gnu/cmake/Amesos* \
           /usr/lib/x86_64-linux-gnu/cmake/Thyra* \
           /usr/lib/x86_64-linux-gnu/cmake/ThyraCore* \
           /usr/lib/x86_64-linux-gnu/cmake/ThyraEpetra* \
           /usr/lib/x86_64-linux-gnu/cmake/ThyraEpetraAdapters* \
           /usr/lib/x86_64-linux-gnu/cmake/ThyraEpetraExtAdapters* \
           /usr/lib/x86_64-linux-gnu/cmake/Tpetra* \
           /usr/lib/x86_64-linux-gnu/cmake/Triutils* \
           /usr/lib/x86_64-linux-gnu/cmake/RTOp* \
           /usr/lib/x86_64-linux-gnu/cmake/Kokkos* \
           /usr/lib/x86_64-linux-gnu/cmake/Zoltan* \
           /usr/lib/x86_64-linux-gnu/cmake/Galeri* \
           /usr/lib/x86_64-linux-gnu/cmake/Isorropia* \
           /usr/lib/x86_64-linux-gnu/cmake/Xpetra* \
           /usr/lib/x86_64-linux-gnu/cmake/Belos* \
           /usr/lib/x86_64-linux-gnu/cmake/NOX* \
           /usr/lib/x86_64-linux-gnu/cmake/LOCA* \
           /usr/lib/x86_64-linux-gnu/cmake/Rythmos* \
           /usr/lib/x86_64-linux-gnu/cmake/Piro* \
           /usr/lib/x86_64-linux-gnu/cmake/Stratimikos* \
           /usr/lib/x86_64-linux-gnu/cmake/Sacado* \
           /usr/lib/x86_64-linux-gnu/cmake/Stokhos* \
           /usr/share/trilinos* \
           /usr/share/Trilinos* 2>/dev/null || true
           
    apt-get autoremove -y 2>/dev/null || true
}

# OS Detection
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
        fi
    fi
fi

# Non-root user detection
USERNAME="${_REMOTE_USER:-vscode}"
USER_UID="${_REMOTE_USER_UID:-1000}"
USER_GID="${_REMOTE_USER_GID:-1000}"
USER_HOME="${_REMOTE_USER_HOME:-/home/${USERNAME}}"

print_info "Target user: ${USERNAME} (UID: ${USER_UID}, GID: ${USER_GID})"

# Pre-configure tzdata to prevent interactive prompts
echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections
echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

# Update package lists and remove any existing system Trilinos packages
apt-get update
remove_system_trilinos

# Install base dependencies
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
    curl \
    libhdf5-dev \
    libsuitesparse-dev \
    gfortran

# Install optional MPI support
if [ "${ENABLE_MPI}" = "true" ]; then
    print_info "Installing MPI support..."
    apt-get install -y --no-install-recommends \
        libopenmpi-dev \
        openmpi-bin \
        openmpi-common \
        libhdf5-mpi-dev \
        libscalapack-mpi-dev
    
    # Remove any Trilinos packages that might have been installed as MPI dependencies
    remove_system_trilinos
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

# Install optional Trilinos support
if [ "${ENABLE_TRILINOS}" = "true" ]; then
    if [ "${ENABLE_MPI}" != "true" ]; then
        print_error "Trilinos requires MPI support. Enabling MPI..."
        ENABLE_MPI="true"
        apt-get install -y --no-install-recommends \
            libopenmpi-dev \
            openmpi-bin \
            openmpi-common \
            libhdf5-mpi-dev \
            libscalapack-mpi-dev
    fi
    
    print_info "Building and installing Trilinos (this may take a while)..."
    
    # Create temporary directory for Trilinos build
    TRILINOS_BUILD_DIR="/tmp/trilinos-build-$$"
    mkdir -p ${TRILINOS_BUILD_DIR}
    cd ${TRILINOS_BUILD_DIR}
    
    # Download Trilinos (version 13.4.1 is known to work with deal.II)
    TRILINOS_VERSION="13.4.1"
    print_info "Downloading Trilinos ${TRILINOS_VERSION}..."
    
    if ! wget -q "https://github.com/trilinos/Trilinos/archive/trilinos-release-${TRILINOS_VERSION//./-}.tar.gz" -O trilinos.tar.gz; then
        print_error "Failed to download Trilinos. Continuing without Trilinos support..."
        ENABLE_TRILINOS="false"
    else
        tar -xzf trilinos.tar.gz
        cd Trilinos-trilinos-release-${TRILINOS_VERSION//./-}
        
        # Apply LAPACK compatibility patch if needed (for LAPACK 3.6.0+)
        print_info "Applying LAPACK compatibility patch..."
        if [ -f "packages/epetra/src/Epetra_LAPACK_wrappers.h" ]; then
            sed -i 's/F77_BLAS_MANGLE(dggsvd,DGGSVD)/F77_BLAS_MANGLE(dggsvd3,DGGSVD3)/g' packages/epetra/src/Epetra_LAPACK_wrappers.h
            sed -i 's/F77_BLAS_MANGLE(sggsvd,SGGSVD)/F77_BLAS_MANGLE(sggsvd3,SGGSVD3)/g' packages/epetra/src/Epetra_LAPACK_wrappers.h
        fi
        
        mkdir build && cd build
        
        # Configure Trilinos with packages required by deal.II
        print_info "Configuring Trilinos..."
        cmake .. \
            -DCMAKE_INSTALL_PREFIX=/usr/local/trilinos \
            -DCMAKE_BUILD_TYPE=RELEASE \
            -DBUILD_SHARED_LIBS=ON \
            -DTrilinos_ENABLE_Amesos=ON \
            -DTrilinos_ENABLE_Epetra=ON \
            -DTrilinos_ENABLE_EpetraExt=ON \
            -DTrilinos_ENABLE_Ifpack=ON \
            -DTrilinos_ENABLE_AztecOO=ON \
            -DTrilinos_ENABLE_Sacado=ON \
            -DTrilinos_ENABLE_Teuchos=ON \
            -DTrilinos_ENABLE_MueLu=ON \
            -DTrilinos_ENABLE_ML=ON \
            -DTrilinos_ENABLE_NOX=ON \
            -DTrilinos_ENABLE_ROL=ON \
            -DTrilinos_ENABLE_Tpetra=ON \
            -DTrilinos_ENABLE_SEACAS=ON \
            -DTrilinos_ENABLE_COMPLEX=ON \
            -DTrilinos_ENABLE_FLOAT=ON \
            -DTrilinos_ENABLE_Zoltan=ON \
            -DTrilinos_VERBOSE_CONFIGURE=OFF \
            -DTPL_ENABLE_MPI=ON \
            -DCMAKE_VERBOSE_MAKEFILE=OFF \
            -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
            -DTrilinos_ENABLE_FORTRAN=OFF || {
                print_error "Trilinos configuration failed. Continuing without Trilinos support..."
                ENABLE_TRILINOS="false"
                cd /
                rm -rf ${TRILINOS_BUILD_DIR}
            }
        
        if [ "${ENABLE_TRILINOS}" = "true" ]; then
            print_info "Building Trilinos..."
            make -j${BUILD_THREADS} || {
                print_error "Trilinos build failed. Trying with fewer threads..."
                make -j2 || {
                    print_error "Trilinos build failed. Continuing without Trilinos support..."
                    ENABLE_TRILINOS="false"
                    cd /
                    rm -rf ${TRILINOS_BUILD_DIR}
                }
            }
            
            if [ "${ENABLE_TRILINOS}" = "true" ]; then
                print_info "Installing Trilinos..."
                make install
                
                # Verify Trilinos installation
                if [ -f "/usr/local/trilinos/lib/cmake/Trilinos/TrilinosConfig.cmake" ]; then
                    print_info "Trilinos ${TRILINOS_VERSION} installed successfully"
                    ldconfig
                else
                    print_error "Trilinos installation verification failed"
                    ENABLE_TRILINOS="false"
                fi
            fi
        fi
    fi
    
    # Clean up Trilinos build directory
    cd /
    rm -rf ${TRILINOS_BUILD_DIR}
fi

# Create temporary build directory for deal.II
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

# Export environment variables for CMake to find dependencies
if [ "${ENABLE_TRILINOS}" = "true" ] && [ -d "/usr/local/trilinos" ]; then
    export CMAKE_PREFIX_PATH="/usr/local/trilinos:${CMAKE_PREFIX_PATH}"
    export LD_LIBRARY_PATH="/usr/local/trilinos/lib:${LD_LIBRARY_PATH}"
    export Trilinos_ROOT="/usr/local/trilinos"
    export Trilinos_DIR="/usr/local/trilinos"
    export PKG_CONFIG_PATH="/usr/local/trilinos/lib/pkgconfig:${PKG_CONFIG_PATH}"
    unset CMAKE_MODULE_PATH
    export CMAKE_MODULE_PATH="/usr/local/trilinos/lib/cmake"
    
    print_info "Set Trilinos environment variables:"
    print_info "  CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
    print_info "  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
    print_info "  Trilinos_ROOT=${Trilinos_ROOT}"
fi

# Build CMake arguments
CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local/deal.II"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_MPI=${ENABLE_MPI}"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_BUILD_TYPE=Release"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_COMPONENT_DOCUMENTATION=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_COMPONENT_EXAMPLES=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_VERBOSE_MAKEFILE=ON"

if [ "${ENABLE_PETSC}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_PETSC=ON"
fi

if [ "${ENABLE_TRILINOS}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_TRILINOS=ON"
    CMAKE_ARGS="${CMAKE_ARGS} -DTRILINOS_DIR=/usr/local/trilinos"
    CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=/usr/local/trilinos:\${CMAKE_PREFIX_PATH}"
    CMAKE_ARGS="${CMAKE_ARGS} -DTrilinos_ROOT=/usr/local/trilinos"
    CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_IGNORE_PATH=/usr/lib/x86_64-linux-gnu/cmake"
    CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH=/usr/local/trilinos"
fi

# Run CMake configuration
print_info "Running CMake configuration (this may take a few minutes)..."
print_info "CMake arguments: ${CMAKE_ARGS}"

cmake .. ${CMAKE_ARGS}
CMAKE_EXIT_CODE=$?

if [ ${CMAKE_EXIT_CODE} -ne 0 ]; then
    print_error "CMake configuration failed with exit code ${CMAKE_EXIT_CODE}"
    
    # Provide diagnostic information
    if [ "${ENABLE_TRILINOS}" = "true" ]; then
        print_error "Trilinos support was requested. Checking Trilinos installation..."
        if [ ! -d "/usr/local/trilinos" ]; then
            print_error "Trilinos directory not found at /usr/local/trilinos"
        elif [ ! -f "/usr/local/trilinos/lib/cmake/Trilinos/TrilinosConfig.cmake" ]; then
            print_error "Trilinos CMake config not found"
        fi
    fi
    
    if [ "${ENABLE_MPI}" = "true" ]; then
        print_error "MPI support was requested. Checking MPI installation..."
        which mpicc || print_error "mpicc not found in PATH"
        which mpirun || print_error "mpirun not found in PATH"
    fi
    
    # Show CMake logs
    if [ -f "CMakeFiles/CMakeError.log" ]; then
        print_error "=== CMake Error Log (last 50 lines) ==="
        tail -n 50 CMakeFiles/CMakeError.log
    fi
    
    cd /
    rm -rf ${BUILD_DIR}
    exit 1
fi

print_info "CMake configuration completed successfully!"

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

# Set up environment for non-root user
if [ "${USERNAME}" != "root" ]; then
    print_info "Setting up environment for user ${USERNAME}..."
    mkdir -p "${USER_HOME}/.local/bin"
    
    # Add deal.II to user's PATH via .bashrc if not already present
    if ! grep -q "DEAL_II_DIR" "${USER_HOME}/.bashrc" 2>/dev/null; then
        {
            echo "export DEAL_II_DIR=/usr/local/deal.II"
            echo "export PATH=\${DEAL_II_DIR}/bin:\${PATH}"
            
            # Add Trilinos paths if installed
            if [ "${ENABLE_TRILINOS}" = "true" ] && [ -d "/usr/local/trilinos" ]; then
                echo "export CMAKE_PREFIX_PATH=/usr/local/deal.II:/usr/local/trilinos:\${CMAKE_PREFIX_PATH}"
                echo "export LD_LIBRARY_PATH=/usr/local/deal.II/lib:/usr/local/trilinos/lib:\${LD_LIBRARY_PATH}"
            fi
        } >> "${USER_HOME}/.bashrc"
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