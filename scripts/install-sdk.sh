#!/bin/bash
# Manual Zephyr SDK Installation Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Manual Zephyr SDK Installation${NC}"
echo ""

# Detect OS and architecture
case "$(uname -s)" in
    Darwin*)
        os_name="macos"
        case "$(uname -m)" in
            x86_64) arch="x86_64" ;;
            arm64) arch="aarch64" ;;
            *) echo -e "${RED}❌ Unsupported macOS architecture: $(uname -m)${NC}"; exit 1 ;;
        esac
        ;;
    Linux*)
        os_name="linux"
        case "$(uname -m)" in
            x86_64) arch="x86_64" ;;
            aarch64) arch="aarch64" ;;
            *) echo -e "${RED}❌ Unsupported Linux architecture: $(uname -m)${NC}"; exit 1 ;;
        esac
        ;;
    *)
        echo -e "${RED}❌ Unsupported OS: $(uname -s)${NC}"
        exit 1
        ;;
esac

sdk_version="0.16.8"
sdk_name="zephyr-sdk-${sdk_version}_${os_name}-${arch}"
sdk_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdk_version}/${sdk_name}.tar.xz"
install_dir="$HOME/zephyr-sdk-${sdk_version}"

echo -e "${YELLOW}System detected: ${os_name}-${arch}${NC}"
echo -e "${YELLOW}SDK URL: ${sdk_url}${NC}"
echo -e "${YELLOW}Install directory: ${install_dir}${NC}"
echo ""

# Check if already installed
if [ -d "$install_dir" ]; then
    echo -e "${GREEN}✅ SDK already exists at: $install_dir${NC}"
    echo -e "${YELLOW}To reinstall, remove the directory first:${NC}"
    echo "  rm -rf $install_dir"
    exit 0
fi

echo -e "${BLUE}Manual installation steps:${NC}"
echo ""
echo "1. Download the SDK:"
echo -e "   ${YELLOW}curl -L -O \"$sdk_url\"${NC}"
echo ""
echo "2. Create install directory:"
echo -e "   ${YELLOW}mkdir -p \"$install_dir\"${NC}"
echo ""
echo "3. Extract SDK:"
echo -e "   ${YELLOW}tar -xf \"${sdk_name}.tar.xz\" --strip-components=1 -C \"$install_dir\"${NC}"
echo ""
echo "4. Run setup:"
echo -e "   ${YELLOW}cd \"$install_dir\" && ./setup.sh -h -c${NC}"
echo ""
echo "5. Set environment variable:"
echo -e "   ${YELLOW}export ZEPHYR_SDK_INSTALL_DIR=\"$install_dir\"${NC}"
echo ""

read -p "Would you like me to run these commands automatically? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Starting automatic installation...${NC}"
    
    # Download
    echo -e "${BLUE}Downloading...${NC}"
    curl -L -O "$sdk_url"
    
    # Create directory
    echo -e "${BLUE}Creating directory...${NC}"
    mkdir -p "$install_dir"
    
    # Extract
    echo -e "${BLUE}Extracting...${NC}"
    tar -xf "${sdk_name}.tar.xz" --strip-components=1 -C "$install_dir"
    
    # Setup
    echo -e "${BLUE}Running setup...${NC}"
    cd "$install_dir"
    ./setup.sh -h -c
    
    # Cleanup
    cd - > /dev/null
    rm -f "${sdk_name}.tar.xz"
    
    echo -e "${GREEN}✅ SDK installed successfully!${NC}"
    echo -e "${YELLOW}Add this to your shell profile:${NC}"
    echo "export ZEPHYR_SDK_INSTALL_DIR=\"$install_dir\""
else
    echo -e "${YELLOW}Run the commands above manually to install the SDK.${NC}"
fi