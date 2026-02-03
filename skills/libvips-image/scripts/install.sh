#!/usr/bin/env bash
#
# libvips-image skill installer
# Supports macOS, Linux (Ubuntu/Debian, Fedora/RHEL, Arch)
# Prefers uv for Python package management
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)  OS="macos" ;;
        Linux*)   OS="linux" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
        *)        error "Unsupported OS: $(uname -s)" ;;
    esac

    if [ "$OS" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO="$ID"
        elif [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="rhel"
        else
            DISTRO="unknown"
        fi
    fi

    info "Detected OS: $OS${DISTRO:+ ($DISTRO)}"
}

# Check if command exists
has_cmd() { command -v "$1" &>/dev/null; }

# Install libvips system library
install_libvips() {
    info "Installing libvips system library..."

    case "$OS" in
        macos)
            if has_cmd brew; then
                brew install vips || warn "brew install vips failed, trying alternatives..."
            elif has_cmd /opt/homebrew/bin/brew; then
                /opt/homebrew/bin/brew install vips
            elif has_cmd /usr/local/bin/brew; then
                /usr/local/bin/brew install vips
            else
                error "Homebrew not found. Install from https://brew.sh"
            fi
            ;;
        linux)
            case "$DISTRO" in
                ubuntu|debian|pop|linuxmint)
                    sudo apt-get update
                    sudo apt-get install -y libvips-dev libvips-tools
                    ;;
                fedora|rhel|centos|rocky|alma)
                    sudo dnf install -y vips-devel vips-tools || \
                    sudo yum install -y vips-devel vips-tools
                    ;;
                arch|manjaro|endeavouros)
                    sudo pacman -S --noconfirm libvips
                    ;;
                alpine)
                    sudo apk add vips-dev vips-tools
                    ;;
                *)
                    warn "Unknown distro: $DISTRO"
                    warn "Trying common package names..."
                    if has_cmd apt-get; then
                        sudo apt-get update && sudo apt-get install -y libvips-dev
                    elif has_cmd dnf; then
                        sudo dnf install -y vips-devel
                    elif has_cmd yum; then
                        sudo yum install -y vips-devel
                    elif has_cmd pacman; then
                        sudo pacman -S --noconfirm libvips
                    else
                        error "Cannot determine package manager. Install libvips manually."
                    fi
                    ;;
            esac
            ;;
        windows)
            warn "Windows detected. Please install libvips manually:"
            warn "1. Download from https://github.com/libvips/libvips/releases"
            warn "2. Extract and add bin/ to your PATH"
            warn "3. Then run this script again"
            ;;
    esac

    # Verify installation
    if has_cmd vips; then
        success "libvips installed: $(vips --version 2>/dev/null | head -1)"
    else
        # Check common paths
        for vips_path in /opt/homebrew/bin/vips /usr/local/bin/vips /usr/bin/vips; do
            if [ -x "$vips_path" ]; then
                success "libvips found at: $vips_path"
                return 0
            fi
        done
        warn "libvips command not found in PATH, but library may still be usable"
    fi
}

# Install Python package using uv (preferred) or pip
install_pyvips() {
    info "Installing pyvips Python package..."

    # Try uv first (preferred)
    if has_cmd uv; then
        info "Using uv (preferred package manager)"
        uv pip install pyvips && success "pyvips installed via uv" && return 0
    fi

    # Try uvx
    if has_cmd uvx; then
        info "Using uvx"
        uvx pip install pyvips && success "pyvips installed via uvx" && return 0
    fi

    # Check for uv in common locations
    for uv_path in ~/.cargo/bin/uv ~/.local/bin/uv /opt/homebrew/bin/uv /usr/local/bin/uv; do
        if [ -x "$uv_path" ]; then
            info "Found uv at: $uv_path"
            "$uv_path" pip install pyvips && success "pyvips installed via uv" && return 0
        fi
    done

    # Offer to install uv
    warn "uv not found. uv is recommended for faster, more reliable package management."
    echo -n "Install uv now? [Y/n] "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        info "Skipping uv installation, falling back to pip..."
    else
        info "Installing uv..."
        if has_cmd curl; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        elif has_cmd wget; then
            wget -qO- https://astral.sh/uv/install.sh | sh
        else
            error "Neither curl nor wget found. Install uv manually: https://docs.astral.sh/uv/"
        fi

        # Source the new PATH
        export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

        if has_cmd uv; then
            uv pip install pyvips && success "pyvips installed via uv" && return 0
        fi
    fi

    # Fallback to pip
    info "Falling back to pip..."

    # Try pip3 first, then pip
    for pip_cmd in pip3 pip python3\ -m\ pip python\ -m\ pip; do
        if $pip_cmd --version &>/dev/null; then
            info "Using: $pip_cmd"
            $pip_cmd install pyvips && success "pyvips installed via pip" && return 0
        fi
    done

    error "No suitable pip found. Please install Python with pip."
}

# Verify installation
verify_installation() {
    info "Verifying installation..."

    # Find Python - prefer uv's python or system python
    PYTHON=""

    # Try uv run first
    if has_cmd uv; then
        if uv run python -c "print('ok')" &>/dev/null; then
            PYTHON="uv run python"
        fi
    fi

    # Fallback to system python
    if [ -z "$PYTHON" ]; then
        for py in python3 python; do
            if has_cmd $py; then
                PYTHON="$py"
                break
            fi
        done
    fi

    if [ -z "$PYTHON" ]; then
        error "Python not found"
    fi

    info "Using Python: $PYTHON"

    # Set library paths for macOS
    if [ "$OS" = "macos" ]; then
        # Find libvips library path
        VIPS_LIB_PATH=""
        for lib_path in /opt/homebrew/lib /usr/local/lib; do
            if [ -f "$lib_path/libvips.dylib" ] || [ -f "$lib_path/libvips.42.dylib" ]; then
                VIPS_LIB_PATH="$lib_path"
                break
            fi
        done

        if [ -n "$VIPS_LIB_PATH" ]; then
            export DYLD_LIBRARY_PATH="$VIPS_LIB_PATH:$DYLD_LIBRARY_PATH"
            info "Set DYLD_LIBRARY_PATH=$VIPS_LIB_PATH"
        fi
    fi

    # Test pyvips import
    TEST_CMD="import pyvips; print(f'pyvips {pyvips.__version__}, libvips {pyvips.version(0)}.{pyvips.version(1)}.{pyvips.version(2)}')"

    if $PYTHON -c "$TEST_CMD" 2>/dev/null; then
        success "Installation verified successfully!"
        return 0
    fi

    # If verification failed but libraries exist, show setup instructions
    if [ "$OS" = "macos" ] && [ -n "$VIPS_LIB_PATH" ]; then
        warn "pyvips installed but library linking may need configuration."
        warn ""
        warn "Option 1: Use uv run (recommended):"
        warn "  uv run python scripts/vips_tool.py --help"
        warn ""
        warn "Option 2: Set library path in your shell profile (~/.zshrc or ~/.bashrc):"
        warn "  export DYLD_LIBRARY_PATH=\"$VIPS_LIB_PATH:\$DYLD_LIBRARY_PATH\""
        warn ""
        warn "Option 3: Use Homebrew's Python which has proper linking:"
        warn "  /opt/homebrew/bin/python3 -m pip install pyvips"
        warn ""
        success "Installation complete (library path configuration may be needed)"
        return 0
    fi

    error "pyvips import failed. Please check libvips installation."
}

# Print usage instructions
print_usage() {
    echo ""
    echo "=============================================="
    echo "  libvips-image skill installed successfully!"
    echo "=============================================="
    echo ""
    echo "Usage examples:"
    echo ""
    echo "  # Resize image"
    echo "  python scripts/vips_tool.py resize input.jpg output.jpg --width 800"
    echo ""
    echo "  # Convert to WebP"
    echo "  python scripts/vips_tool.py convert input.jpg output.webp --quality 85"
    echo ""
    echo "  # Create thumbnail"
    echo "  python scripts/vips_tool.py thumbnail input.jpg thumb.jpg --size 200"
    echo ""
    echo "  # Batch process"
    echo "  python scripts/vips_batch.py resize ./input ./output --width 800"
    echo ""
    echo "For more commands, run: python scripts/vips_tool.py --help"
    echo ""
}

# Main
main() {
    echo ""
    echo "========================================"
    echo "  libvips-image Skill Installer"
    echo "========================================"
    echo ""

    detect_os
    install_libvips
    install_pyvips
    verify_installation
    print_usage
}

# Run main
main "$@"
