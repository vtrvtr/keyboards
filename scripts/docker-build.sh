#!/bin/bash
# Docker-based ZMK Build Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 ZMK Docker Build Environment${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not running${NC}"
    echo "Please install Docker Desktop or Docker Engine"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose is not available${NC}"
    echo "Please install Docker Compose"
    exit 1
fi

# Use modern docker compose if available, fallback to docker-compose
DOCKER_COMPOSE_CMD="docker-compose"
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Function to run commands in container
run_in_container() {
    $DOCKER_COMPOSE_CMD run --rm zmk-build "$@"
}

# Function to build container if needed
ensure_container() {
    if ! docker images | grep -q "$(basename $(pwd))_zmk-build"; then
        echo -e "${BLUE}📦 Building Docker image (this may take a few minutes)...${NC}"
        $DOCKER_COMPOSE_CMD build
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
    fi
}

case "${1:-help}" in
    "setup")
        ensure_container
        echo -e "${BLUE}🔧 Setting up ZMK workspace in container...${NC}"
        run_in_container bash -c "
            if [ ! -d 'zmk' ]; then
                echo '📦 Initializing west workspace...'
                west init -l config
                west update --fetch-opt=--filter=tree:0
                west zephyr-export
                echo '✅ West workspace initialized'
            else
                echo '📦 Updating west workspace...'
                west update --fetch-opt=--filter=tree:0
                west zephyr-export
                echo '✅ West workspace updated'
            fi
        "
        echo -e "${GREEN}🎉 Setup complete!${NC}"
        ;;
    
    "build")
        ensure_container
        side="${2:-both}"
        echo -e "${BLUE}🔨 Building firmware for $side side(s)...${NC}"
        
        build_side() {
            local side=$1
            echo -e "${BLUE}Building $side side...${NC}"
            
            run_in_container bash -c "
                # Set up Zephyr environment
                export ZEPHYR_BASE=/workspace/zephyr
                west zephyr-export
                
                # Clean previous build
                rm -rf build
                
                # Build firmware (using the same method as GitHub Actions)
                west build -s zmk/app -b nice_nano_v2 -d build -- -DSHIELD=corne_$side -DZMK_CONFIG=/workspace/config
                
                # Create output directory and copy firmware
                mkdir -p firmware
                timestamp=\$(date +\"%Y%m%d_%H%M%S\")
                
                if [ -f 'build/zephyr/zmk.uf2' ]; then
                    cp build/zephyr/zmk.uf2 firmware/corne_${side}_\${timestamp}.uf2
                    cp build/zephyr/zmk.uf2 firmware/corne_${side}_latest.uf2
                    echo '✅ Built $side side: firmware/corne_${side}_\${timestamp}.uf2'
                else
                    echo '❌ Build failed - no zmk.uf2 file generated'
                    exit 1
                fi
            "
        }
        
        case "$side" in
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
        echo -e "${GREEN}🎉 Build complete! Firmware files are in the 'firmware' directory${NC}"
        ;;
    
    "shell")
        ensure_container
        echo -e "${BLUE}🐚 Starting interactive shell in container...${NC}"
        run_in_container bash -c "
            export ZEPHYR_BASE=/workspace/zephyr
            west zephyr-export
            exec bash
        "
        ;;
    
    "clean")
        echo -e "${BLUE}🧹 Cleaning build artifacts...${NC}"
        run_in_container bash -c "rm -rf build"
        rm -rf firmware/*
        echo -e "${GREEN}✅ Cleaned build artifacts${NC}"
        ;;
    
    "update")
        ensure_container
        echo -e "${BLUE}🔄 Updating ZMK workspace...${NC}"
        run_in_container bash -c "west update --fetch-opt=--filter=tree:0 && west zephyr-export"
        echo -e "${GREEN}✅ Workspace updated${NC}"
        ;;
    
    "rebuild-image")
        echo -e "${BLUE}🔄 Rebuilding Docker image...${NC}"
        $DOCKER_COMPOSE_CMD build --no-cache
        echo -e "${GREEN}✅ Docker image rebuilt${NC}"
        ;;
    
    "help"|*)
        echo -e "${GREEN}ZMK Docker Build System${NC}"
        echo ""
        echo "Available commands:"
        echo -e "  ${YELLOW}setup${NC}           - Initialize ZMK workspace"
        echo -e "  ${YELLOW}build [side]${NC}    - Build firmware (left/right/both)"
        echo -e "  ${YELLOW}shell${NC}           - Open interactive shell in container"
        echo -e "  ${YELLOW}clean${NC}           - Clean build artifacts"
        echo -e "  ${YELLOW}update${NC}          - Update ZMK workspace"
        echo -e "  ${YELLOW}rebuild-image${NC}   - Rebuild Docker image"
        echo -e "  ${YELLOW}help${NC}            - Show this help"
        echo ""
        echo "Examples:"
        echo -e "  ${BLUE}./scripts/docker-build.sh setup${NC}"
        echo -e "  ${BLUE}./scripts/docker-build.sh build${NC}"
        echo -e "  ${BLUE}./scripts/docker-build.sh build left${NC}"
        ;;
esac
