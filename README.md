# deal.II DevContainer Feature

A lean [devcontainer feature](https://code.visualstudio.com/blogs/2022/09/15/dev-container-features) that installs [deal.II](https://www.dealii.org/) - a powerful C++ finite element library for solving partial differential equations.

## 🚀 Quick Start

Add this feature to your `.devcontainer/devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/[your-username]/deal-ii-devcontainer-feature/deal-ii:1": {
      "version": "9.5.0"
    }
  }
}
```

## 📦 What's Included

This **lean** installation includes:
- ✅ deal.II core library
- ✅ Essential dependencies (CMake, Boost, BLAS, LAPACK)
- ✅ Optional MPI support (when enabled)
- ✅ Optional PETSc support (when enabled)

To keep it lean, these are **NOT** included:
- ❌ Documentation (saves ~100MB)
- ❌ Examples (saves ~50MB)
- ❌ Additional optional dependencies (Trilinos, SLEPc, etc.)

## ⚙️ Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"9.5.0"` | deal.II version to install |
| `enableMPI` | boolean | `false` | Enable MPI support (OpenMPI) |
| `enablePETSc` | boolean | `false` | Enable PETSc support |
| `buildThreads` | string | `"4"` | Number of parallel build threads |

## 🔧 Advanced Usage

### With MPI Support

```json
{
  "features": {
    "ghcr.io/[your-username]/deal-ii-devcontainer-feature/deal-ii:1": {
      "version": "9.5.0",
      "enableMPI": true,
      "buildThreads": "8"
    }
  }
}
```

### With PETSc Support

```json
{
  "features": {
    "ghcr.io/[your-username]/deal-ii-devcontainer-feature/deal-ii:1": {
      "version": "9.5.0",
      "enablePETSc": true,
      "enableMPI": true
    }
  }
}
```

## 💻 Example Code

After installation, you can use deal.II in your projects:

```cpp
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>
#include <iostream>

using namespace dealii;

int main()
{
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(4);
    
    std::cout << "Number of cells: " 
              << triangulation.n_active_cells() 
              << std::endl;
    
    return 0;
}
```

Build with CMake:

```cmake
cmake_minimum_required(VERSION 3.10)
project(my_project)

find_package(deal.II REQUIRED HINTS ${DEAL_II_DIR})
deal_ii_initialize_cached_variables()

add_executable(my_app main.cpp)
deal_ii_setup_target(my_app)
```

## 🏗️ Development

### Testing Locally

1. Clone this repository
2. Open in VS Code
3. Use the test configuration in `test/.devcontainer/`
4. The feature will be automatically built and installed

### Publishing

This feature can be published to any OCI-compliant registry. The recommended approach is using GitHub Container Registry (ghcr.io).

## ✅ Best Practices Compliance

This feature follows the [official devcontainer feature authoring best practices](https://containers.dev/guide/feature-authoring-best-practices):

- **Platform Detection**: Validates OS compatibility and provides clear error messages
- **Idempotency**: Handles multiple installations gracefully
- **Non-root User Support**: Properly configures permissions for the target user
- **Multiple Installation Strategies**: Includes fallback download methods
- **Comprehensive Testing**: Includes unit tests and scenario tests
- **Architecture Support**: Works on both x86_64 and arm64

## ⚠️ Important Notes

- **Build Time**: Installing deal.II from source takes 15-30 minutes depending on your hardware
- **Disk Space**: The installation requires ~2GB during build, ~500MB after installation
- **Compatibility**: Designed for Debian/Ubuntu-based containers
- **Architecture**: Supports both x86_64 and arm64

## 📄 License

- This devcontainer feature is provided under the MIT License
- deal.II is licensed under LGPL 2.1 or later
- See [deal.II license page](https://www.dealii.org/license.html) for details

## 🔗 Resources

- [deal.II Documentation](https://www.dealii.org/current/doxygen/deal.II/index.html)
- [deal.II Tutorials](https://www.dealii.org/current/doxygen/deal.II/Tutorial.html)
- [DevContainer Features Specification](https://containers.dev/implementors/features/)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)