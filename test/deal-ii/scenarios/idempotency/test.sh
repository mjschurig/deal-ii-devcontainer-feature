#!/bin/bash
set -e

# Test idempotency - installing the feature multiple times should work

echo "=== Testing feature idempotency ==="

# First installation should succeed
echo "First installation..."
/bin/bash /feature/install.sh

# Check that it installed correctly
if [ ! -d "${DEAL_II_DIR}" ]; then
    echo "ERROR: First installation failed - DEAL_II_DIR not found"
    exit 1
fi

# Second installation should detect existing installation and handle gracefully
echo "Second installation (should detect existing installation)..."
/bin/bash /feature/install.sh

# Third installation with same version should also work
echo "Third installation (testing repeated installation)..."
VERSION="9.5.0" /bin/bash /feature/install.sh

# Verify installation is still working
if [ ! -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    echo "ERROR: deal.II installation corrupted after multiple installs"
    exit 1
fi

echo "=== Idempotency test passed! ===" 