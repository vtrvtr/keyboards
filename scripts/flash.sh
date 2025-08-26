#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FIRMWARE_DIR="firmware"

echo -e "${BLUE}🔍 Looking for connected Nice Nano controllers...${NC}"

# Function to detect mounted Nice Nano
detect_nicenano() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        find /media /mnt -name "NICENANO" -type d 2>/dev/null
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        find /Volumes -name "NICENANO" -type d 2>/dev/null
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows (Git Bash/Cygwin)
        find /*/NICENANO -type d 2>/dev/null
    fi
}

# Function to flash firmware
flash_firmware() {
    local side=$1
    local mount_point=$2
    local firmware_file="$FIRMWARE_DIR/corne_${side}_latest.uf2"
    
    if [ ! -f "$firmware_file" ]; then
        echo "❌ Firmware file not found: $firmware_file"
        echo "   Run './scripts/build.sh $side' first"
        return 1
    fi
    
    echo -e "${YELLOW}📋 Flashing $side side firmware...${NC}"
    cp "$firmware_file" "$mount_point/"
    echo -e "${GREEN}✅ Flashed $side side to $mount_point${NC}"
}

# Check if firmware files exist
if [ ! -d "$FIRMWARE_DIR" ]; then
    echo "❌ No firmware directory found. Run './scripts/build.sh' first."
    exit 1
fi

# Auto-detect mode
if [ $# -eq 0 ]; then
    echo -e "${BLUE}🔍 Auto-detecting Nice Nano controllers...${NC}"
    
    nicenano_mounts=$(detect_nicenano)
    
    if [ -z "$nicenano_mounts" ]; then
        echo "❌ No Nice Nano controllers detected in bootloader mode"
        echo "   Put your Nice Nano in bootloader mode (double-tap reset) and try again"
        exit 1
    fi
    
    mount_count=$(echo "$nicenano_mounts" | wc -l)
    
    if [ "$mount_count" -eq 1 ]; then
        mount_point=$(echo "$nicenano_mounts" | head -n1)
        echo "🎯 Found one Nice Nano at: $mount_point"
        echo "   Which side would you like to flash? (left/right)"
        read -p "Side: " side
        
        if [[ "$side" =~ ^(left|right)$ ]]; then
            flash_firmware "$side" "$mount_point"
        else
            echo "❌ Invalid side. Use 'left' or 'right'"
            exit 1
        fi
    else
        echo "🎯 Found multiple Nice Nano controllers:"
        echo "$nicenano_mounts"
        echo "   Please specify which side to flash manually:"
        echo "   ./scripts/flash.sh left /path/to/mount"
        echo "   ./scripts/flash.sh right /path/to/mount"
    fi
    
# Manual mode
elif [ $# -eq 2 ]; then
    side=$1
    mount_point=$2
    
    if [[ ! "$side" =~ ^(left|right)$ ]]; then
        echo "❌ Invalid side. Use 'left' or 'right'"
        exit 1
    fi
    
    if [ ! -d "$mount_point" ]; then
        echo "❌ Mount point not found: $mount_point"
        exit 1
    fi
    
    flash_firmware "$side" "$mount_point"
    
else
    echo "Usage:"
    echo "  ./scripts/flash.sh                    # Auto-detect mode"
    echo "  ./scripts/flash.sh <side> <mount>     # Manual mode"
    echo ""
    echo "Examples:"
    echo "  ./scripts/flash.sh left /Volumes/NICENANO"
    echo "  ./scripts/flash.sh right /media/NICENANO"
fi