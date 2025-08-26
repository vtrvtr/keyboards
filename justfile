# Corne Keyboard Firmware - Docker Build System
# Run `just` to see all available commands

# Default recipe - show help
default:
    @just --list

# === Docker-based builds (stable & recommended) ===

# Setup ZMK workspace using Docker (run this first)
setup:
    ./scripts/docker-build.sh setup

# Build firmware for both sides
build side="both":
    ./scripts/docker-build.sh build {{side}}

# Build only left side
build-left:
    ./scripts/docker-build.sh build left

# Build only right side  
build-right:
    ./scripts/docker-build.sh build right

# Open interactive shell in Docker container
shell:
    ./scripts/docker-build.sh shell

# Clean build artifacts
clean:
    ./scripts/docker-build.sh clean

# Update ZMK workspace
update:
    ./scripts/docker-build.sh update

# Rebuild Docker image from scratch
rebuild:
    ./scripts/docker-build.sh rebuild-image

# === Utilities ===

# Auto-detect and flash firmware to controllers
flash:
    ./scripts/flash.sh

# Flash specific side to specific mount point
flash-to side mount:
    ./scripts/flash.sh {{side}} {{mount}}

# Show build info and status
info:
    #!/usr/bin/env bash
    echo "🎹 Corne Keyboard Firmware (Docker Build)"
    echo "========================================"
    echo ""
    if [ -d "zmk" ]; then
        echo "✅ ZMK workspace: Initialized"
        cd zmk && git log --oneline -1 && cd ..
    else
        echo "❌ ZMK workspace: Not initialized (run 'just setup')"
    fi
    echo ""
    if [ -d "firmware" ]; then
        echo "📁 Firmware files:"
        ls -la firmware/*.uf2 2>/dev/null || echo "  No firmware files found"
    else
        echo "📁 No firmware directory found"
    fi
    echo ""
    echo "🔧 Configuration:"
    echo "  Board:   nice_nano_v2"
    echo "  Shield:  corne_left / corne_right"
    echo "  Keymap:  config/corne.keymap"
    echo "  Config:  config/corne.conf"
    echo ""
    echo "🐳 Docker Status:"
    if docker images | grep -q "keyboards_zmk-build"; then
        echo "  ✅ Docker image: Built"
    else
        echo "  ❌ Docker image: Not built"
    fi

# Validate keymap syntax
validate:
    #!/usr/bin/env bash
    echo "🔍 Validating keymap syntax..."
    if [ -f "config/corne.keymap" ]; then
        # Basic syntax check - looking for common issues
        if grep -q "^#include" config/corne.keymap && \
           grep -q "keymap {" config/corne.keymap && \
           grep -q "bindings = <" config/corne.keymap; then
            echo "✅ Keymap syntax looks good"
        else
            echo "❌ Keymap may have syntax issues"
            echo "   Check for #include statements, keymap block, and bindings"
        fi
    else
        echo "❌ Keymap file not found: config/corne.keymap"
    fi

# Quick workflow: clean, build, and show info
quick: clean build info

# Development workflow: update and build
dev: update build

# List all available recipes
list:
    @just --list
