#!/bin/bash
# Debug script for deal.II CMake configuration

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" 1>&2
}

print_success() {
    echo -e "\033[0;32m[SUCCESS] $1\033[0m"
}

echo "=== deal.II CMake Debug Script ==="

# Check basic requirements
print_info "Checking basic requirements..."

# Check CMake
if command -v cmake &> /dev/null; then
    print_success "CMake found: $(cmake --version | head -1)"
else
    print_error "CMake not found!"
    exit 1
fi

# Check compiler
if command -v c++ &> /dev/null; then
    print_success "C++ compiler found: $(c++ --version | head -1)"
else
    print_error "C++ compiler not found!"
    exit 1
fi

# Check essential libraries
print_info "Checking essential libraries..."

# LAPACK
if ldconfig -p | grep -q liblapack; then
    print_success "LAPACK found"
else
    print_error "LAPACK not found"
fi

# BLAS
if ldconfig -p | grep -q libblas; then
    print_success "BLAS found"
else
    print_error "BLAS not found"
fi

# Boost
if ldconfig -p | grep -q libboost; then
    print_success "Boost found"
else
    print_error "Boost not found"
fi

# Create minimal test
print_info "Testing minimal CMake configuration..."
mkdir -p /tmp/dealii-cmake-test
cd /tmp/dealii-cmake-test

# Test 1: Basic find_package test
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test)

# Test finding LAPACK
find_package(LAPACK REQUIRED)
message(STATUS "LAPACK found: ${LAPACK_LIBRARIES}")

# Test finding BLAS
find_package(BLAS REQUIRED)
message(STATUS "BLAS found: ${BLAS_LIBRARIES}")

# Test finding Boost
find_package(Boost REQUIRED)
message(STATUS "Boost found: ${Boost_VERSION}")
EOF

if cmake . > basic_test.log 2>&1; then
    print_success "Basic CMake configuration succeeded"
else
    print_error "Basic CMake configuration failed"
    cat basic_test.log
fi

# Test 2: Check MPI if enabled
if [ "${ENABLE_MPI}" = "true" ] || command -v mpicc &> /dev/null; then
    print_info "Testing MPI configuration..."
    
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test)
find_package(MPI REQUIRED)
message(STATUS "MPI C compiler: ${MPI_C_COMPILER}")
message(STATUS "MPI CXX compiler: ${MPI_CXX_COMPILER}")
EOF

    if cmake . > mpi_test.log 2>&1; then
        print_success "MPI CMake configuration succeeded"
        grep "MPI" mpi_test.log
    else
        print_error "MPI CMake configuration failed"
        cat mpi_test.log
    fi
fi

# Test 3: Check environment
print_info "Environment variables:"
echo "CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
echo "PATH=${PATH}"

# Check for deal.II source
if [ -d "/tmp/dealii-build-${DEALII_PID}/dealii-${DEALII_VERSION}" ]; then
    print_info "deal.II source directory found"
    
    # Try minimal deal.II configuration
    print_info "Attempting minimal deal.II configuration..."
    cd "/tmp/dealii-build-${DEALII_PID}/dealii-${DEALII_VERSION}"
    mkdir -p build-test && cd build-test
    
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/tmp/test-install \
        -DDEAL_II_WITH_MPI=OFF \
        -DDEAL_II_WITH_PETSC=OFF \
        -DDEAL_II_WITH_TRILINOS=OFF \
        -DDEAL_II_COMPONENT_DOCUMENTATION=OFF \
        -DDEAL_II_COMPONENT_EXAMPLES=OFF \
        -DCMAKE_BUILD_TYPE=Release > minimal_dealii.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Minimal deal.II configuration succeeded"
    else
        print_error "Minimal deal.II configuration failed"
        tail -100 minimal_dealii.log
        if [ -f "CMakeFiles/CMakeError.log" ]; then
            print_error "=== CMakeError.log ==="
            tail -100 CMakeFiles/CMakeError.log
        fi
    fi
else
    print_info "deal.II source directory not found for testing"
fi

# Cleanup
cd /
rm -rf /tmp/dealii-cmake-test

echo "=== Debug complete ===" 