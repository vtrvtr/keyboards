#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_PATH="$(pwd)/config"
BUILD_DIR="build"
OUTPUT_DIR="firmware"

# Check if west workspace is initialized
if [ ! -d "zmk" ] || [ ! -f ".west/config" ]; then
    echo -e "${RED}❌ West workspace not initialized. Run 'just setup' first.${NC}"
    exit 1
fi

# Setup build environment
source scripts/env.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to setup environment${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

build_side() {
    local side=$1
    echo -e "${BLUE}🔨 Building Corne $side side...${NC}"
    
    # Clean previous build
    rm -rf "$BUILD_DIR"
    
    # Build firmware with proper Zephyr environment
    west build -s zmk/app -b nice_nano_v2 -d "$BUILD_DIR" -- -DSHIELD=corne_$side -DZMK_CONFIG="$CONFIG_PATH"
    
    # Copy firmware to output directory with timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local output_file="$OUTPUT_DIR/corne_${side}_${timestamp}.uf2"
    local latest_file="$OUTPUT_DIR/corne_${side}_latest.uf2"
    
    cp "$BUILD_DIR/zephyr/zmk.uf2" "$output_file"
    cp "$BUILD_DIR/zephyr/zmk.uf2" "$latest_file"
    
    echo -e "${GREEN}✅ Built $side side: $output_file${NC}"
    echo -e "${GREEN}✅ Latest build: $latest_file${NC}"
}

case "${1:-both}" in
    "left")
        build_side "left"
        ;;
    "right")
        build_side "right"
        ;;
    "both"|"")
        build_side "left"
        echo ""
        build_side "right"
        ;;
    *)
        echo -e "${RED}❌ Invalid option. Use: left, right, or both${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}📁 Firmware files are in the 'firmware' directory${NC}"
echo -e "${YELLOW}🔌 To flash: Put Nice Nano in bootloader mode and copy the .uf2 file${NC}"