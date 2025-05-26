
# deal.II (deal-ii)

Installs deal.II (Differential Equations Analysis Library) - a C++ finite element library

## Example Usage

```json
"features": {
    "ghcr.io/mjschurig/deal-ii-devcontainer-feature/deal-ii:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version of deal.II to install. | string | 9.5.0 |
| enableMPI | Enable MPI support (installs OpenMPI) | boolean | false |
| enablePETSc | Enable PETSc support | boolean | false |
| enableTrilinos | Enable Trilinos support for linear algebra operations | boolean | false |
| buildThreads | Number of threads to use for building deal.II | string | 4 |

## Trilinos Integration

When `enableTrilinos` is set to `true`, this feature will automatically install and configure the Trilinos devcontainer feature as a dependency. The Trilinos integration provides deal.II with access to powerful linear algebra capabilities including:

- **Trilinos packages**: Amesos, AztecOO, Epetra, EpetraExt, Ifpack, ML, MueLu, NOX, ROL, Sacado, SEACAS, Teuchos, Tpetra, Zoltan
- **Automatic MPI enablement**: Trilinos requires MPI, so MPI will be automatically enabled when Trilinos is requested
- **Environment variables**: `TRILINOS_DIR` and updated `CMAKE_PREFIX_PATH` for easy discovery

Example usage with Trilinos:

```json
"features": {
    "ghcr.io/mjschurig/deal-ii-devcontainer-feature/deal-ii:1": {
        "enableTrilinos": true,
        "enableMPI": true
    }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mjschurig/deal-ii-devcontainer-feature/blob/main/src/deal-ii/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
