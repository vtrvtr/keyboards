#!/bin/bash
# ZMK Development Environment Setup
# Source this file before building: source scripts/env.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up ZMK environment...${NC}"

# Set Zephyr base
export ZEPHYR_BASE="$(pwd)/zephyr"

# Find Zephyr SDK
if [ -z "$ZEPHYR_SDK_INSTALL_DIR" ]; then
    # Try common SDK locations
    sdk_paths=(
        "$HOME/zephyr-sdk-0.16.8"
        "$HOME/zephyr-sdk-0.16.5" 
        "$HOME/zephyr-sdk"
        "/opt/zephyr-sdk"
        "/usr/local/zephyr-sdk"
    )
    
    for path in "${sdk_paths[@]}"; do
        if [ -d "$path" ]; then
            export ZEPHYR_SDK_INSTALL_DIR="$path"
            echo -e "${GREEN}✅ Found Zephyr SDK at: $path${NC}"
            break
        fi
    done
fi

# Check if SDK was found
if [ -z "$ZEPHYR_SDK_INSTALL_DIR" ]; then
    echo -e "${RED}❌ Zephyr SDK not found. Please run 'just setup' first.${NC}"
    return 1 2>/dev/null || exit 1
fi

# Source Zephyr environment
if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
    source "$ZEPHYR_BASE/zephyr-env.sh"
    echo -e "${GREEN}✅ Zephyr environment loaded${NC}"
else
    echo -e "${YELLOW}⚠️  Zephyr environment script not found${NC}"
fi

# Set toolchain
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

echo -e "${GREEN}🎉 Environment ready for ZMK development!${NC}"
echo ""
echo "Environment variables set:"
echo "  ZEPHYR_BASE: $ZEPHYR_BASE"
echo "  ZEPHYR_SDK_INSTALL_DIR: $ZEPHYR_SDK_INSTALL_DIR"
echo "  ZEPHYR_TOOLCHAIN_VARIANT: $ZEPHYR_TOOLCHAIN_VARIANT"