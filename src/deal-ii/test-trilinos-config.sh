#!/bin/bash
# Diagnostic script for Trilinos configuration with deal.II

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" 1>&2
}

print_success() {
    echo -e "\033[0;32m[SUCCESS] $1\033[0m"
}

echo "=== Trilinos Configuration Diagnostic ==="

# Check if Trilinos is installed
if [ -d "/usr/local/trilinos" ]; then
    print_success "Trilinos directory found at /usr/local/trilinos"
else
    print_error "Trilinos directory not found at /usr/local/trilinos"
    exit 1
fi

# Check Trilinos CMake config
if [ -f "/usr/local/trilinos/lib/cmake/Trilinos/TrilinosConfig.cmake" ]; then
    print_success "Trilinos CMake config found"
else
    print_error "Trilinos CMake config not found"
fi

# Check required Trilinos libraries
print_info "Checking for required Trilinos libraries..."
REQUIRED_LIBS=(
    "libamesos"
    "libaztecoo"
    "libepetra"
    "libifpack"
    "libml"
    "libmuelu"
    "libteuchos"
    "libzoltan"
)

MISSING_LIBS=()
for lib in "${REQUIRED_LIBS[@]}"; do
    if ls /usr/local/trilinos/lib/${lib}* 1> /dev/null 2>&1; then
        print_success "Found ${lib}"
    else
        print_error "Missing ${lib}"
        MISSING_LIBS+=("${lib}")
    fi
done

# Check optional Trilinos libraries
print_info "Checking for optional Trilinos libraries..."
OPTIONAL_LIBS=(
    "libnox"
    "librol"
    "libsacado"
    "libtpetra"
)

for lib in "${OPTIONAL_LIBS[@]}"; do
    if ls /usr/local/trilinos/lib/${lib}* 1> /dev/null 2>&1; then
        print_success "Found optional ${lib}"
    else
        print_info "Optional ${lib} not found"
    fi
done

# Test CMake find_package for Trilinos
print_info "Testing CMake find_package for Trilinos..."
mkdir -p /tmp/trilinos-test
cd /tmp/trilinos-test

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(trilinos_test)

# Find Trilinos
find_package(Trilinos REQUIRED HINTS /usr/local/trilinos)

if(Trilinos_FOUND)
    message(STATUS "Trilinos found!")
    message(STATUS "Trilinos version: ${Trilinos_VERSION}")
    message(STATUS "Trilinos packages: ${Trilinos_PACKAGE_LIST}")
    message(STATUS "Trilinos include dirs: ${Trilinos_INCLUDE_DIRS}")
    message(STATUS "Trilinos libraries: ${Trilinos_LIBRARIES}")
else()
    message(FATAL_ERROR "Trilinos not found!")
endif()
EOF

if cmake . > trilinos_cmake_test.log 2>&1; then
    print_success "CMake find_package(Trilinos) succeeded"
    echo "Trilinos packages found:"
    grep "Trilinos packages:" trilinos_cmake_test.log | sed 's/.*Trilinos packages: //' | tr ';' '\n' | sort | uniq
else
    print_error "CMake find_package(Trilinos) failed"
    echo "CMake output:"
    cat trilinos_cmake_test.log
fi

# Check environment variables
print_info "Checking environment variables..."
if [ -n "${LD_LIBRARY_PATH}" ]; then
    if [[ "${LD_LIBRARY_PATH}" == *"/usr/local/trilinos/lib"* ]]; then
        print_success "LD_LIBRARY_PATH includes Trilinos"
    else
        print_info "LD_LIBRARY_PATH does not include /usr/local/trilinos/lib"
    fi
fi

if [ -n "${CMAKE_PREFIX_PATH}" ]; then
    if [[ "${CMAKE_PREFIX_PATH}" == *"/usr/local/trilinos"* ]]; then
        print_success "CMAKE_PREFIX_PATH includes Trilinos"
    else
        print_info "CMAKE_PREFIX_PATH does not include /usr/local/trilinos"
    fi
fi

# Check MPI
print_info "Checking MPI installation (required for Trilinos)..."
if command -v mpirun &> /dev/null; then
    print_success "MPI found: $(mpirun --version | head -1)"
else
    print_error "MPI not found (required for Trilinos)"
fi

# Summary
echo ""
echo "=== Summary ==="
if [ ${#MISSING_LIBS[@]} -eq 0 ]; then
    print_success "All required Trilinos libraries found"
else
    print_error "Missing ${#MISSING_LIBS[@]} required libraries: ${MISSING_LIBS[*]}"
fi

# Cleanup
cd /
rm -rf /tmp/trilinos-test

echo "=== Diagnostic complete ===" 