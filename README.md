

# Geocomputation with Julia

[![Render](https://github.com/geocompx/geocompjl/actions/workflows/main.yaml/badge.svg)](https://github.com/geocompx/geocompjl/actions/workflows/main.yaml)

Geocomputation with Julia is an open source book project. We are developing it in the open and publishing an up-to-date online version at https://jl.geocompx.org/.
Geocomputation with Julia is part of the [geocompx](https://geocompx.org/) series providing geocomputation resources in different languages.

## Reproducing the book locally

To run the code that is part of the Geocomputation with Julia book requires the following dependencies:

1. Julia: To install julia on your machine we recommend to use juliaup which can be installed follwing these [installation instructions](https://julialang.org/downloads/)
For now we need to restrict to julia 1.10 because quarto 1.5 does not work with julia 1.11
To restrict the julia version for this project folder run
```
juliaup override set 1.10
```

2. [Quarto](https://quarto.org/docs/get-started/), which is used to
    render the book. This needs quarto 1.5.30 or higher
3. Julia Dependencies:
    To install the julia dependencies run the following in the main folder of this project:
    ```
    julia --project -e "using Pkg; Pkg.instantiate()"
    ```


