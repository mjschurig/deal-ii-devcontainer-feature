#!/bin/sh
# Bootstrap script to ensure bash is available

set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "ERROR: Cannot detect OS - /etc/os-release not found"
    exit 1
fi

# Install bash if not available (needed for Alpine)
if [ "${ID}" = "alpine" ]; then
    echo "Detected Alpine Linux - installing bash..."
    apk add --no-cache bash
    
    # Also install basic build dependencies for Alpine
    apk add --no-cache \
        build-base \
        cmake \
        wget \
        ca-certificates \
        git \
        curl \
        linux-headers
        
    # Note: deal.II requires more dependencies that may not be available in Alpine
    echo "WARNING: Alpine Linux support is experimental. Some dependencies may not be available."
    echo "Consider using a Debian or Ubuntu-based image for full compatibility."
fi

# Execute the main install script with bash
exec /bin/bash "$(dirname $0)/install.sh" "$@" 