#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning build artifacts...${NC}"

# Remove build directory
if [ -d "build" ]; then
    rm -rf build
    echo -e "${GREEN}✅ Removed build directory${NC}"
fi

# Remove firmware directory (optional)
if [ "$1" = "--all" ]; then
    if [ -d "firmware" ]; then
        rm -rf firmware
        echo -e "${GREEN}✅ Removed firmware directory${NC}"
    fi
fi

# Remove west workspace (if requested)
if [ "$1" = "--reset" ]; then
    if [ -d "zmk" ]; then
        rm -rf zmk
        echo -e "${GREEN}✅ Removed ZMK workspace${NC}"
    fi
    if [ -d ".west" ]; then
        rm -rf .west
        echo -e "${GREEN}✅ Removed west metadata${NC}"
    fi
fi

echo -e "${YELLOW}🎉 Clean complete!${NC}"

if [ "$1" = "--reset" ]; then
    echo "   Run './scripts/setup.sh' to reinitialize the workspace"
elif [ "$1" = "--all" ]; then
    echo "   Run './scripts/build.sh' to rebuild firmware"
else
    echo "   Use '--all' to also remove firmware files"
    echo "   Use '--reset' to completely reset the workspace"
fi