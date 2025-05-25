#include <deal.II/base/utilities.h>
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>
#include <iostream>

#ifdef DEAL_II_WITH_TRILINOS
#  include <deal.II/lac/trilinos_vector.h>
#  include <deal.II/lac/trilinos_sparse_matrix.h>
#endif

using namespace dealii;

int main()
{
    std::cout << "deal.II version: " << DEAL_II_VERSION_MAJOR 
              << "." << DEAL_II_VERSION_MINOR 
              << "." << DEAL_II_VERSION_SUBMINOR << std::endl;
    
    // Create a simple 2D triangulation
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation, -1, 1);
    triangulation.refine_global(2);
    
    std::cout << "Number of active cells: " 
              << triangulation.n_active_cells() << std::endl;
    
#ifdef DEAL_II_WITH_TRILINOS
    std::cout << "Trilinos support: ENABLED" << std::endl;
    
    // Simple Trilinos test
    Utilities::MPI::MPI_InitFinalize mpi_initialization(1, nullptr, 1);
    TrilinosWrappers::MPI::Vector vec;
    vec.reinit(complete_index_set(10), MPI_COMM_WORLD);
    vec = 1.0;
    std::cout << "Trilinos vector norm: " << vec.l2_norm() << std::endl;
#else
    std::cout << "Trilinos support: DISABLED" << std::endl;
#endif

#ifdef DEAL_II_WITH_MPI
    std::cout << "MPI support: ENABLED" << std::endl;
#else
    std::cout << "MPI support: DISABLED" << std::endl;
#endif

#ifdef DEAL_II_WITH_PETSC
    std::cout << "PETSc support: ENABLED" << std::endl;
#else
    std::cout << "PETSc support: DISABLED" << std::endl;
#endif
    
    return 0;
} 