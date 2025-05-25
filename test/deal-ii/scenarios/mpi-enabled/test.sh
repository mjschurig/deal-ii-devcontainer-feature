#!/bin/bash
set -e

# Test MPI-enabled installation

echo "=== Testing MPI-enabled installation ==="

# Install with MPI enabled
ENABLEMPI="true" /bin/bash /feature/install.sh

# Check MPI installation
if ! command -v mpirun &> /dev/null; then
    echo "ERROR: mpirun command not found after MPI installation"
    exit 1
fi

# Create a simple MPI test program
cat > /tmp/test_mpi.cpp << 'EOF'
#include <deal.II/base/mpi.h>
#include <deal.II/base/utilities.h>
#include <iostream>

using namespace dealii;

int main(int argc, char *argv[])
{
    Utilities::MPI::MPI_InitFinalize mpi_initialization(argc, argv, 1);
    
    std::cout << "MPI process " 
              << Utilities::MPI::this_mpi_process(MPI_COMM_WORLD)
              << " of " 
              << Utilities::MPI::n_mpi_processes(MPI_COMM_WORLD)
              << std::endl;
    
    return 0;
}
EOF

# Build the MPI test
cat > /tmp/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test_mpi)
find_package(deal.II REQUIRED HINTS ${DEAL_II_DIR})
deal_ii_initialize_cached_variables()
add_executable(test_mpi test_mpi.cpp)
deal_ii_setup_target(test_mpi)
EOF

cd /tmp
mkdir -p build_mpi_test
cd build_mpi_test
cmake .. -DDEAL_II_DIR=${DEAL_II_DIR}
make

# Run with MPI
mpirun -np 2 ./test_mpi

echo "=== MPI test passed! ===" 