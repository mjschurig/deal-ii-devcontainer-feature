#!/bin/bash

# Test script to verify Trilinos installation and deal.II integration

echo "Testing Trilinos installation..."

# Check if Trilinos is installed
if [ -d "/usr/local/trilinos" ]; then
    echo "✓ Trilinos directory found at /usr/local/trilinos"
else
    echo "✗ Trilinos directory not found"
    exit 1
fi

# Check for key Trilinos libraries
TRILINOS_LIBS=(
    "libamesos.so"
    "libaztecoo.so"
    "libepetra.so"
    "libifpack.so"
    "libml.so"
    "libmuelu.so"
    "libteuchos*.so"
)

echo "Checking for Trilinos libraries..."
for lib in "${TRILINOS_LIBS[@]}"; do
    if ls /usr/local/trilinos/lib/${lib} 1> /dev/null 2>&1; then
        echo "✓ Found ${lib}"
    else
        echo "✗ Missing ${lib}"
    fi
done

# Check if deal.II is configured with Trilinos
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if grep -q "DEAL_II_WITH_TRILINOS.*ON" /usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake; then
        echo "✓ deal.II is configured with Trilinos support"
    else
        echo "✗ deal.II is not configured with Trilinos support"
    fi
fi

echo "Trilinos test complete." 