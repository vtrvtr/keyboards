#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔧 Setting up ZMK build environment..."

# Check if west is available
if ! command -v west &>/dev/null; then
	echo -e "${RED}❌ West is not installed. Please install it first:${NC}"
	echo "  pip3 install west"
	exit 1
fi

# Check for Zephyr SDK
check_zephyr_sdk() {
	if [ -n "$ZEPHYR_SDK_INSTALL_DIR" ] && [ -d "$ZEPHYR_SDK_INSTALL_DIR" ]; then
		echo -e "${GREEN}✅ Zephyr SDK found at: $ZEPHYR_SDK_INSTALL_DIR${NC}"
		return 0
	fi

	# Common SDK locations
	local sdk_paths=(
		"$HOME/zephyr-sdk-0.16.8"
		"$HOME/zephyr-sdk-0.16.5"
		"$HOME/zephyr-sdk"
		"/opt/zephyr-sdk"
		"/usr/local/zephyr-sdk"
	)

	for path in "${sdk_paths[@]}"; do
		if [ -d "$path" ]; then
			export ZEPHYR_SDK_INSTALL_DIR="$path"
			echo -e "${GREEN}✅ Zephyr SDK found at: $path${NC}"
			return 0
		fi
	done

	return 1
}

# Install Zephyr SDK if not found
install_zephyr_sdk() {
	echo -e "${YELLOW}📦 Zephyr SDK not found. Installing...${NC}"

	# Detect OS and architecture
	local os_name=""
	local arch=""

	case "$(uname -s)" in
	Darwin*)
		os_name="macos"
		case "$(uname -m)" in
		x86_64) arch="x86_64" ;;
		arm64) arch="aarch64" ;;
		*)
			echo -e "${RED}❌ Unsupported macOS architecture: $(uname -m)${NC}"
			exit 1
			;;
		esac
		;;
	Linux*)
		os_name="linux"
		case "$(uname -m)" in
		x86_64) arch="x86_64" ;;
		aarch64) arch="aarch64" ;;
		*)
			echo -e "${RED}❌ Unsupported Linux architecture: $(uname -m)${NC}"
			exit 1
			;;
		esac
		;;
	*)
		echo -e "${RED}❌ Unsupported OS: $(uname -s)${NC}"
		exit 1
		;;
	esac

	local sdk_version="0.16.8"
	local sdk_name="zephyr-sdk-${sdk_version}_${os_name}-${arch}"
	local sdk_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdk_version}/${sdk_name}.tar.xz"
	local install_dir="$HOME/zephyr-sdk-${sdk_version}"

	echo -e "${BLUE}Downloading Zephyr SDK ${sdk_version} for ${os_name}-${arch}...${NC}"

	# Create temporary directory
	local temp_dir=$(mktemp -d)
	echo -e "${BLUE}Using temporary directory: $temp_dir${NC}"
	cd "$temp_dir"

	# Download SDK
	if command -v curl &>/dev/null; then
		echo -e "${BLUE}Downloading with curl: $sdk_url${NC}"
		curl -L -O "$sdk_url"
	elif command -v wget &>/dev/null; then
		echo -e "${BLUE}Downloading with wget: $sdk_url${NC}"
		wget "$sdk_url"
	else
		echo -e "${RED}❌ Neither curl nor wget found. Please install one of them.${NC}"
		exit 1
	fi

	# Verify download
	if [ ! -f "${sdk_name}.tar.xz" ]; then
		echo -e "${RED}❌ Download failed - file not found: ${sdk_name}.tar.xz${NC}"
		ls -la
		exit 1
	fi

	# Extract SDK
	echo -e "${BLUE}Extracting SDK...${NC}"

	# Extract directly to the target directory
	mkdir -p "$install_dir"
	tar -xf "${sdk_name}.tar.xz" --strip-components=1 -C "$install_dir"

	# Run setup script
	cd "$install_dir"
	./setup.sh -h -c

	# Set environment variable
	export ZEPHYR_SDK_INSTALL_DIR="$install_dir"

	# Cleanup
	rm -rf "$temp_dir"

	# Return to original directory
	cd - >/dev/null

	# Verify installation
	if [ -d "$install_dir" ] && [ -f "$install_dir/setup.sh" ]; then
		echo -e "${GREEN}✅ Zephyr SDK installed at: $install_dir${NC}"
	else
		echo -e "${RED}❌ SDK installation failed${NC}"
		echo -e "${YELLOW}Please install manually:${NC}"
		echo "1. Download SDK from: $sdk_url"
		echo "2. Extract to: $install_dir"
		echo "3. Run: $install_dir/setup.sh -h -c"
		exit 1
	fi
}

# Initialize west workspace
if [ ! -d "zmk" ]; then
	echo -e "${BLUE}📦 Initializing west workspace...${NC}"
	west init -l config
	west update
	echo -e "${GREEN}✅ West workspace initialized${NC}"
else
	echo -e "${BLUE}📦 Updating west workspace...${NC}"
	west update
	echo -e "${GREEN}✅ West workspace updated${NC}"
fi

# Check and install Zephyr SDK
if ! check_zephyr_sdk; then
	echo -e "${YELLOW}⚠️  Zephyr SDK not found.${NC}"
	echo -e "${YELLOW}You can install it manually with: ${BLUE}just install-sdk${NC}"
	echo -e "${YELLOW}Or follow the instructions at: https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html${NC}"
	echo ""
	echo -e "${YELLOW}Continuing with workspace setup...${NC}"
fi

# Verify Zephyr installation
if [ ! -d "zephyr" ]; then
	echo -e "${RED}❌ Zephyr not found after west update. Something went wrong.${NC}"
	exit 1
fi

echo -e "${GREEN}🎉 Setup complete! You can now build your firmware.${NC}"
echo ""
echo "Next steps:"
echo -e "  ${YELLOW}./scripts/build.sh${NC}       - Build both left and right firmware"
echo -e "  ${YELLOW}./scripts/build.sh left${NC}  - Build only left side"
echo -e "  ${YELLOW}./scripts/build.sh right${NC} - Build only right side"
