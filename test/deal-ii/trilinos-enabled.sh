#!/bin/bash
set -e

# Test Trilinos-enabled installation

echo "=== Testing Trilinos-enabled installation ==="

# Install with Trilinos enabled (this will automatically enable MPI)
ENABLETRILINOS="true" BUILDTHREADS="2" /bin/bash /feature/install.sh

# Check if Trilinos is installed
if [ ! -d "/usr/local/trilinos" ]; then
    echo "ERROR: Trilinos directory not found at /usr/local/trilinos"
    exit 1
fi

# Check for key Trilinos libraries
echo "Checking for Trilinos libraries..."
TRILINOS_LIBS=(
    "libamesos.so"
    "libaztecoo.so"
    "libepetra.so"
    "libteuchos*.so"
)

for lib in "${TRILINOS_LIBS[@]}"; do
    if ! ls /usr/local/trilinos/lib/${lib} 1> /dev/null 2>&1; then
        echo "ERROR: Missing Trilinos library ${lib}"
        exit 1
    fi
done

# Verify deal.II is configured with Trilinos
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if ! grep -q "DEAL_II_WITH_TRILINOS.*ON" /usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake; then
        echo "ERROR: deal.II is not configured with Trilinos support"
        exit 1
    fi
else
    echo "ERROR: deal.II configuration file not found"
    exit 1
fi

# Create a simple Trilinos test program
cat > /tmp/test_trilinos.cpp << 'EOF'
#include <deal.II/lac/trilinos_sparse_matrix.h>
#include <deal.II/lac/trilinos_vector.h>
#include <deal.II/lac/trilinos_precondition.h>
#include <deal.II/lac/trilinos_solver.h>
#include <iostream>

using namespace dealii;

int main()
{
    // Initialize MPI (required for Trilinos)
    Utilities::MPI::MPI_InitFinalize mpi_initialization(1, nullptr, 1);
    
    // Create a small Trilinos sparse matrix
    TrilinosWrappers::SparseMatrix matrix;
    TrilinosWrappers::SparsityPattern sparsity_pattern;
    
    // Create a simple 10x10 identity matrix
    sparsity_pattern.reinit(10, 10, 1);
    for (unsigned int i = 0; i < 10; ++i)
        sparsity_pattern.add(i, i);
    sparsity_pattern.compress();
    
    matrix.reinit(sparsity_pattern);
    for (unsigned int i = 0; i < 10; ++i)
        matrix.set(i, i, 1.0);
    matrix.compress(VectorOperation::insert);
    
    // Create vectors
    TrilinosWrappers::MPI::Vector x, b;
    x.reinit(complete_index_set(10), MPI_COMM_WORLD);
    b.reinit(complete_index_set(10), MPI_COMM_WORLD);
    
    // Set RHS vector
    for (unsigned int i = 0; i < 10; ++i)
        b(i) = i + 1;
    b.compress(VectorOperation::insert);
    
    // Solve using Trilinos CG solver
    SolverControl solver_control(100, 1e-10);
    TrilinosWrappers::SolverCG solver(solver_control);
    TrilinosWrappers::PreconditionIdentity preconditioner;
    
    solver.solve(matrix, x, b, preconditioner);
    
    std::cout << "Trilinos solver converged in " 
              << solver_control.last_step() 
              << " iterations" << std::endl;
    
    return 0;
}
EOF

# Build the Trilinos test
cat > /tmp/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test_trilinos)
find_package(deal.II REQUIRED HINTS ${DEAL_II_DIR})
deal_ii_initialize_cached_variables()
add_executable(test_trilinos test_trilinos.cpp)
deal_ii_setup_target(test_trilinos)
EOF

cd /tmp
mkdir -p build_trilinos_test
cd build_trilinos_test
cmake .. -DDEAL_II_DIR=${DEAL_II_DIR}
make

# Run the test
./test_trilinos

echo "=== Trilinos test passed! ===" 