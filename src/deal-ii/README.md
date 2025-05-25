
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
| buildThreads | Number of threads to use for building deal.II | string | 4 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mjschurig/deal-ii-devcontainer-feature/blob/main/src/deal-ii/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
