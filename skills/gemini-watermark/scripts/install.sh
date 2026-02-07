#!/usr/bin/env bash
#
# gemini-watermark installer
# Downloads pre-built binary from GitHub Releases
# Supports: macOS (ARM64/x86_64), Linux (x86_64/ARM64), Windows (MSYS/Git Bash)
#
# Usage:
#   ./install.sh                    # Install latest version
#   VERSION=v0.1.1 ./install.sh    # Install specific version
#

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────
REPO="easynote-cc/gemini-watermark-removal"
BINARY_NAME="gemini-watermark"
GITHUB_API="https://api.github.com/repos/${REPO}/releases"
GITHUB_DL="https://github.com/${REPO}/releases/download"

# ─── Colors ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Detect platform ───────────────────────────────────────────────
detect_platform() {
    local os arch target

    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Darwin)
            case "$arch" in
                arm64|aarch64) target="aarch64-apple-darwin" ;;
                x86_64)        target="x86_64-apple-darwin" ;;
                *)             error "Unsupported macOS architecture: $arch" ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64|amd64)  target="x86_64-unknown-linux-musl" ;;
                aarch64|arm64) target="aarch64-unknown-linux-musl" ;;
                *)             error "Unsupported Linux architecture: $arch" ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*)
            case "$arch" in
                x86_64|amd64) target="x86_64-pc-windows-msvc" ;;
                *)            error "Unsupported Windows architecture: $arch" ;;
            esac
            ;;
        *)
            error "Unsupported OS: $os\n\n  Fallback: cargo install gemini-watermark-removal"
            ;;
    esac

    echo "$target"
}

# ─── Get latest version from GitHub API ────────────────────────────
get_latest_version() {
    local version=""

    if command -v curl &>/dev/null; then
        version=$(curl -fsSL "${GITHUB_API}/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    elif command -v wget &>/dev/null; then
        version=$(wget -qO- "${GITHUB_API}/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    if [ -z "$version" ]; then
        error "Failed to fetch latest version from GitHub.\n\n  Check network or install manually:\n    cargo install gemini-watermark-removal"
    fi

    echo "$version"
}

# ─── Download file ─────────────────────────────────────────────────
download() {
    local url="$1" dest="$2"

    if command -v curl &>/dev/null; then
        curl -fsSL -o "$dest" "$url"
    elif command -v wget &>/dev/null; then
        wget -qO "$dest" "$url"
    fi
}

# ─── Verify SHA256 checksum ────────────────────────────────────────
verify_checksum() {
    local file="$1" checksum_file="$2"
    local expected actual

    expected=$(awk '{print $1}' "$checksum_file")

    if command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        warn "No checksum tool found. Skipping verification."
        return 0
    fi

    if [ "$expected" != "$actual" ]; then
        error "Checksum mismatch!\n  Expected: $expected\n  Actual:   $actual"
    fi

    success "SHA256 checksum verified"
}

# ─── Main ──────────────────────────────────────────────────────────
main() {
    echo "=== ${BINARY_NAME} Installer ==="
    echo ""

    # 1. Detect platform
    local target
    target=$(detect_platform)
    info "Platform: ${target}"

    # 2. Determine version
    local version="${VERSION:-}"
    if [ -z "$version" ]; then
        info "Fetching latest version..."
        version=$(get_latest_version)
    fi
    info "Version: ${version}"

    # 3. Archive format
    local ext="tar.gz"
    if [[ "$target" == *windows* ]]; then
        ext="zip"
    fi
    local archive="${BINARY_NAME}-${target}.${ext}"

    # 4. Download archive + checksum
    local url="${GITHUB_DL}/${version}/${archive}"
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "${TMP_DIR:-}"' EXIT
    local tmp_dir="$TMP_DIR"

    info "Downloading ${archive}..."
    if ! download "$url" "${tmp_dir}/${archive}"; then
        error "Download failed: ${url}\n\n  Fallback: cargo install gemini-watermark-removal"
    fi

    info "Downloading checksum..."
    if download "${url}.sha256" "${tmp_dir}/${archive}.sha256" 2>/dev/null; then
        verify_checksum "${tmp_dir}/${archive}" "${tmp_dir}/${archive}.sha256"
    else
        warn "Checksum file not available. Skipping verification."
    fi

    # 5. Extract
    info "Extracting..."
    case "$ext" in
        tar.gz) tar xzf "${tmp_dir}/${archive}" -C "${tmp_dir}" ;;
        zip)    unzip -qo "${tmp_dir}/${archive}" -d "${tmp_dir}" ;;
    esac

    # 6. Install binary
    local bin_name="$BINARY_NAME"
    if [[ "$target" == *windows* ]]; then
        bin_name="${BINARY_NAME}.exe"
    fi

    local src="${tmp_dir}/${bin_name}"
    local dst="${SCRIPT_DIR}/${BINARY_NAME}"

    if [ ! -f "$src" ]; then
        error "Binary '${bin_name}' not found in archive."
    fi

    cp "$src" "$dst"
    chmod +x "$dst"
    success "Installed to ${dst}"

    # 7. Verify
    if "$dst" --version >/dev/null 2>&1; then
        success "Verified: $("$dst" --version)"
    else
        error "Binary verification failed"
    fi

    echo ""
    echo "Usage:"
    echo "  ${dst} <image.jpg>                    # Auto-detect and remove watermark"
    echo "  ${dst} <image.jpg> -o output.jpg      # Specify output path"
    echo "  ${dst} <input_dir> -o <output_dir>    # Batch process directory"
    echo ""
    success "Installation complete!"
}

main "$@"
