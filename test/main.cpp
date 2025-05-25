#include <deal.II/base/utilities.h>
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>
#include <iostream>

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
    
    return 0;
} 