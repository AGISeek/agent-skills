#!/usr/bin/env bash
#
# gemini-watermark installer
# Downloads pre-built binary from GitHub Releases
# Supports: macOS (ARM64/x86_64), Linux (x86_64/ARM64), Windows (MSYS/Git Bash)
#
# Usage:
#   ./install.sh                    # Install latest version (interactive)
#   ./install.sh --yes              # Skip confirmation prompt
#   VERSION=v0.1.1 ./install.sh    # Install specific version
#
# Security note:
#   This script downloads a pre-built binary from a third-party GitHub repository.
#   To build from source instead (recommended for security-sensitive environments):
#     cargo install gemini-watermark-removal
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

# ─── Security warning + explicit consent ───────────────────────────
security_prompt() {
    local auto_yes="${1:-}"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SECURITY NOTICE — Third-Party Binary Download"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  This installer will download a pre-built binary from:"
    echo "  https://github.com/${REPO}/releases"
    echo ""
    echo "  The '${REPO%%/*}' GitHub organization is a third party"
    echo "  not affiliated with this skill's publisher."
    echo ""
    echo "  Recommended alternatives before proceeding:"
    echo "    1. Review source:   https://github.com/${REPO}"
    echo "    2. Build yourself:  cargo install gemini-watermark-removal"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ "$auto_yes" == "--yes" || "$auto_yes" == "-y" || "${YES:-}" == "1" ]]; then
        warn "Proceeding without confirmation (--yes / YES=1 set)."
        return 0
    fi

    read -r -p "Continue with binary download? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) ;;
        *) echo "Aborted. No changes made."; exit 0 ;;
    esac
}

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
# Sanitizes the tag_name to prevent path traversal or injection via
# a malicious API response (must match vX.Y.Z or vX.Y.Z-suffix).
get_latest_version() {
    local raw version=""

    if command -v curl &>/dev/null; then
        raw=$(curl -fsSL "${GITHUB_API}/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    elif command -v wget &>/dev/null; then
        raw=$(wget -qO- "${GITHUB_API}/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    # Strict allowlist: vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-prerelease
    if [[ "$raw" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
        version="$raw"
    else
        error "GitHub API returned an unexpected version string: '${raw}'\n\n  Specify a version manually: VERSION=v0.1.1 ./install.sh\n  Or install from source: cargo install gemini-watermark-removal"
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

# ─── Verify SHA256 checksum (mandatory) ───────────────────────────
verify_checksum() {
    local file="$1" checksum_file="$2"
    local expected actual

    expected=$(awk '{print $1}' "$checksum_file")

    if command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        error "No SHA256 tool found (sha256sum or shasum required).\n  Install one and retry, or build from source:\n    cargo install gemini-watermark-removal"
    fi

    if [ "$expected" != "$actual" ]; then
        error "Checksum mismatch — binary may be corrupted or tampered with.\n  Expected: $expected\n  Actual:   $actual\n\n  Do NOT use the downloaded file. Install from source instead:\n    cargo install gemini-watermark-removal"
    fi

    success "SHA256 checksum verified: ${actual:0:16}…"
}

# ─── Main ──────────────────────────────────────────────────────────
main() {
    local auto_yes="${1:-}"

    echo "=== ${BINARY_NAME} Installer ==="
    echo ""

    # 0. Security warning + explicit consent
    security_prompt "$auto_yes"

    # 1. Detect platform
    local target
    target=$(detect_platform)
    info "Platform: ${target}"

    # 2. Determine version
    local version="${VERSION:-}"
    if [ -z "$version" ]; then
        info "Fetching latest version from GitHub API..."
        version=$(get_latest_version)
    else
        # Validate user-supplied version too
        if ! [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
            error "Invalid VERSION format: '${version}'. Expected vX.Y.Z"
        fi
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

    info "Downloading ${archive} from:"
    info "  ${url}"
    if ! download "$url" "${tmp_dir}/${archive}"; then
        error "Download failed: ${url}\n\n  Fallback: cargo install gemini-watermark-removal"
    fi

    # 5. Verify checksum (mandatory — abort if unavailable)
    info "Downloading checksum..."
    if download "${url}.sha256" "${tmp_dir}/${archive}.sha256" 2>/dev/null; then
        verify_checksum "${tmp_dir}/${archive}" "${tmp_dir}/${archive}.sha256"
    else
        error "Checksum file not available for this release.\n  Cannot verify binary integrity — aborting for safety.\n\n  Install from source instead:\n    cargo install gemini-watermark-removal"
    fi

    # 6. Extract
    info "Extracting..."
    case "$ext" in
        tar.gz) tar xzf "${tmp_dir}/${archive}" -C "${tmp_dir}" ;;
        zip)    unzip -qo "${tmp_dir}/${archive}" -d "${tmp_dir}" ;;
    esac

    # 7. Install binary
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

    # 8. Instructions (do NOT auto-execute the downloaded binary)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "Installation complete!"
    echo ""
    echo "  Verify:  ${dst} --version"
    echo "  Usage:   ${dst} <image.jpg>"
    echo "           ${dst} <image.jpg> -o output.jpg"
    echo "           ${dst} <input_dir> -o <output_dir>"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    warn "The binary was NOT automatically executed. Run the verify command above when ready."
}

main "$@"
