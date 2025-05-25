# Trilinos Support in deal.II DevContainer Feature

This feature now includes optional support for [Trilinos](https://trilinos.github.io/), a collection of open-source software libraries for large-scale, complex multi-physics engineering and scientific problems.

## Enabling Trilinos

To enable Trilinos support, set the `enableTrilinos` option to `true` in your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/your-username/deal-ii:latest": {
      "version": "9.5.0",
      "enableMPI": true,
      "enableTrilinos": true
    }
  }
}
```

**Note:** Trilinos requires MPI support. If you enable Trilinos without enabling MPI, the installation script will automatically enable MPI for you.

## What Gets Installed

When Trilinos is enabled, the following packages are built and installed:

- **Amesos** - Direct sparse solver interfaces
- **AztecOO** - Iterative linear solver package
- **Epetra** - Core linear algebra package
- **EpetraExt** - Extensions to Epetra
- **Ifpack** - Incomplete factorization preconditioners
- **ML** - Multilevel preconditioning package
- **MueLu** - Next-generation multigrid framework
- **NOX** - Nonlinear solver package
- **ROL** - Rapid Optimization Library
- **Sacado** - Automatic differentiation
- **SEACAS** - Suite for Engineering Analysis Code Access System
- **Teuchos** - Common tools package
- **Tpetra** - Templated linear algebra
- **Zoltan** - Parallel partitioning and load balancing

## Version Information

- The feature installs Trilinos version 13.4.1, which is known to work well with deal.II
- deal.II requires at least Trilinos 12.4 (12.14.1 if Trilinos includes Kokkos)
- deal.II is known to work with Trilinos up to version 13.4

## Build Time

**Warning:** Building Trilinos from source is computationally intensive and can take 30-60 minutes or more depending on your system. The build process uses parallel compilation with the number of threads specified by the `buildThreads` option.

## Environment Variables

When Trilinos is installed, the following environment variables are configured:

- `CMAKE_PREFIX_PATH` includes `/usr/local/trilinos`
- `LD_LIBRARY_PATH` includes `/usr/local/trilinos/lib`

## Verification

After installation, you can verify that Trilinos is properly installed and integrated with deal.II by:

1. Checking for Trilinos libraries:
   ```bash
   ls /usr/local/trilinos/lib/
   ```

2. Verifying deal.II configuration:
   ```bash
   grep TRILINOS /usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake
   ```

## Using Trilinos with deal.II

Once installed, you can use Trilinos features in your deal.II programs. For example:

- Use `TrilinosWrappers::SparseMatrix` for distributed sparse matrices
- Use `TrilinosWrappers::MPI::Vector` for distributed vectors
- Use `TrilinosWrappers::SolverCG` for parallel iterative solvers
- Use `TrilinosWrappers::PreconditionAMG` for algebraic multigrid preconditioning

See the [deal.II documentation on Trilinos](https://www.dealii.org/current/external-libs/trilinos.html) for more information on using Trilinos with deal.II. 