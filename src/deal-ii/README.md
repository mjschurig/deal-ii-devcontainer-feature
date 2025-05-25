# deal.II (Differential Equations Analysis Library)

A lean devcontainer feature for installing [deal.II](https://www.dealii.org/), a C++ finite element library for solving partial differential equations.

## Example Usage

```json
"features": {
    "ghcr.io/yourusername/deal-ii-devcontainer-feature/deal-ii:1": {
        "version": "9.5.0"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version of deal.II to install | string | 9.5.0 |
| enableMPI | Enable MPI support (installs OpenMPI) | boolean | false |
| enablePETSc | Enable PETSc support | boolean | false |
| buildThreads | Number of threads to use for building deal.II | string | 4 |

## What's Installed

This lean installation includes:
- deal.II core library
- Basic dependencies (CMake, Boost, BLAS, LAPACK)
- Optional MPI support (if enabled)
- Optional PETSc support (if enabled)

The following are **not** included to keep the installation lean:
- Documentation
- Examples
- Additional optional dependencies (Trilinos, SLEPc, etc.)

## Environment Variables

The feature sets the following environment variable:
- `DEAL_II_DIR`: Points to the deal.II installation directory (`/usr/local/deal.II`)

## Usage Example

After installation, you can use deal.II in your C++ projects:

```cpp
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>

using namespace dealii;

int main()
{
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(4);
    
    return 0;
}
```

Compile with:
```bash
cmake -DDEAL_II_DIR=/usr/local/deal.II .
make
```

## Notes

- Building deal.II from source can take significant time (15-30 minutes depending on hardware)
- This feature is designed for Debian/Ubuntu-based containers
- For full documentation and examples, visit [deal.II documentation](https://www.dealii.org/current/doxygen/deal.II/index.html)

## License

deal.II is licensed under LGPL 2.1 or later. See the [deal.II license page](https://www.dealii.org/license.html) for details. 