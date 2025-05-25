#!/bin/bash
set -e

# Test script for deal.II feature

echo "Testing deal.II installation..."

# Check if DEAL_II_DIR is set
if [ -z "${DEAL_II_DIR}" ]; then
    echo "ERROR: DEAL_II_DIR environment variable is not set"
    exit 1
fi

echo "DEAL_II_DIR is set to: ${DEAL_II_DIR}"

# Check if deal.II directory exists
if [ ! -d "${DEAL_II_DIR}" ]; then
    echo "ERROR: deal.II directory does not exist at ${DEAL_II_DIR}"
    exit 1
fi

# Check for deal.II CMake config
if [ ! -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    echo "ERROR: deal.II CMake configuration not found"
    exit 1
fi

# Try to compile a simple test program
cat > /tmp/test_dealii.cpp << 'EOF'
#include <deal.II/base/utilities.h>
#include <iostream>

using namespace dealii;

int main()
{
    std::cout << "deal.II version: " << DEAL_II_VERSION_MAJOR 
              << "." << DEAL_II_VERSION_MINOR 
              << "." << DEAL_II_VERSION_SUBMINOR << std::endl;
    return 0;
}
EOF

# Create a simple CMakeLists.txt
cat > /tmp/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test_dealii)
find_package(deal.II REQUIRED HINTS ${DEAL_II_DIR})
deal_ii_initialize_cached_variables()
add_executable(test_dealii test_dealii.cpp)
deal_ii_setup_target(test_dealii)
EOF

# Try to build the test program
cd /tmp
mkdir -p build_test
cd build_test
cmake .. -DDEAL_II_DIR=${DEAL_II_DIR}
make

# Run the test program
./test_dealii

echo "deal.II installation test passed!" 