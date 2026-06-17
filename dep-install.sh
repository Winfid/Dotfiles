#!/usr/bin/env bash

# ==============================================================================
# Dotfiles Dependency Installer
# Supports: Fedora, Debian/Ubuntu, Arch Linux, openSUSE, Alpine
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Text Formatting ---
BOLD='\033[1m'

# --- Package Mapping Dictionary ---
# FORMAT: ["fedora_name"]="debian_name arch_name opensuse_name alpine_name"
declare -A PKG_MAP=(
    ["git"]="git git git git"
    ["neovim"]="neovim neovim neovim neovim"
    ["tmux"]="tmux tmux tmux tmux"
    ["zsh"]="zsh zsh zsh zsh"
)

# FIX: Explicit ordering so interactive prompts appear in a consistent,
# predictable order (associative arrays iterate in undefined order in Bash).
PKG_ORDER=(git neovim tmux zsh)

# --- Configuration Flags ---
INTERACTIVE_MODE=false

# --- Helper Functions ---
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -i, --interactive  Prompt for confirmation before installing each package."
    echo "  -h, --help         Display this help message."
    echo ""
}

# --- Parse Command Line Arguments ---
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# --- Detect Distribution ---
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            fedora)             echo "fedora" ;;
            # FIX: pop-os is the real $ID value for Pop!_OS; the old "pop" was
            # a dead branch since it's also caught by the ID_LIKE fallback.
            debian|ubuntu|pop-os) echo "debian" ;;
            arch|manjaro)        echo "arch" ;;
            opensuse*|sles)      echo "opensuse" ;;
            alpine)              echo "alpine" ;;
            *)
                # Fallback check for derivatives via ID_LIKE
                for like in $ID_LIKE; do
                    case "$like" in
                        fedora) echo "fedora"; return ;;
                        debian|ubuntu) echo "debian"; return ;;
                        arch) echo "arch"; return ;;
                        opensuse|suse) echo "opensuse"; return ;;
                    esac
                done
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

if [ "$DISTRO" = "unknown" ]; then
    log_error "Unsupported distribution. This script only supports Fedora, Debian/Ubuntu, Arch, openSUSE, and Alpine."
    exit 1
fi

log_info "Detected environment: ${BOLD}${DISTRO}${NC}"

# --- Select Package Manager Commands ---
# FIX: Store PM_CMD as an array so the invocation uses "${PM_CMD[@]}" and
# avoids word-splitting bugs (SC2086). Each element is a separate word with
# no glob expansion risk, and paths containing spaces are handled correctly.
case "$DISTRO" in
    fedora)   PM_CMD=(sudo dnf install -y);        PM_NAME="dnf";     PM_INDEX=0 ;;
    debian)   PM_CMD=(sudo apt-get install -y);    PM_NAME="apt-get"; PM_INDEX=0 ;;
    arch)     PM_CMD=(sudo pacman -S --noconfirm); PM_NAME="pacman";  PM_INDEX=1 ;;
    opensuse) PM_CMD=(sudo zypper install -y);     PM_NAME="zypper";  PM_INDEX=2 ;;
    alpine)   PM_CMD=(sudo apk add);               PM_NAME="apk";     PM_INDEX=3 ;;
esac

# Special update phase for Debian/Ubuntu before starting
if [ "$DISTRO" = "debian" ]; then
    log_info "Running apt-get update..."
    sudo apt-get update -y
fi

# --- Warning for Interactive Mode ---
if [ "$INTERACTIVE_MODE" = true ]; then
    echo -e "${RED}${BOLD}"
    echo "====================================================================="
    echo "                               WARNING!"
    echo "====================================================================="
    echo -e "${NC}"
    log_warn "Skipping certain packages may cause severe instability or break features"
    log_warn "within MY SPECIFIC dotfiles configuration."
    log_warn "Only proceed if you know exactly what you are doing and how to debug"
    log_warn "the missing dependencies downstream."
    echo ""
    # FIX: Read from /dev/tty directly so the prompt works even when stdin is
    # a pipe (e.g. curl | bash). If /dev/tty is unavailable (truly headless),
    # fail loudly rather than silently skipping or silently proceeding.
    if ! read -r -p "Do you understand the risks and wish to continue? (y/N): " confirm </dev/tty; then
        log_error "Cannot read from terminal (stdin is not a tty). Aborting."
        log_error "Run the script directly, or omit --interactive for non-interactive use."
        exit 1
    fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Installation aborted by user."
        exit 0
    fi
fi

# --- Target Array Generation ---
PACKAGES_TO_INSTALL=()

# FIX: Iterate over PKG_ORDER instead of "${!PKG_MAP[@]}" to guarantee a
# consistent prompt order in interactive mode. Associative array key iteration
# is non-deterministic in Bash.
for fedora_pkg in "${PKG_ORDER[@]}"; do
    if [ -z "${PKG_MAP[$fedora_pkg]+isset}" ]; then
        log_warn "Package '$fedora_pkg' is listed in PKG_ORDER but missing from PKG_MAP. Skipping."
        continue
    fi

    if [ "$DISTRO" = "fedora" ]; then
        target_pkg="$fedora_pkg"
    else
        read -r -a mapped_array <<< "${PKG_MAP[$fedora_pkg]}"
        target_pkg="${mapped_array[$PM_INDEX]}"
    fi

    # FIX: Distinguish between a genuinely empty mapping vs. an index-out-of-
    # bounds on mapped_array, and emit a clearer error message for the latter.
    if [ -z "$target_pkg" ]; then
        log_warn "PKG_MAP entry for '$fedora_pkg' has no value at index $PM_INDEX (distro: $DISTRO). Skipping."
        continue
    fi

    if [ "$INTERACTIVE_MODE" = true ]; then
        # FIX: Read from /dev/tty directly — same reasoning as the preamble
        # warning above. Fail loudly if no terminal is available.
        if ! read -r -p "Install dependency '$fedora_pkg' (maps to '$target_pkg' on this system)? (y/N): " choice </dev/tty; then
            log_error "Cannot read from terminal (stdin is not a tty). Aborting."
            exit 1
        fi
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            PACKAGES_TO_INSTALL+=("$target_pkg")
        fi
    else
        PACKAGES_TO_INSTALL+=("$target_pkg")
    fi
done

# --- Execute Installation ---
if [ ${#PACKAGES_TO_INSTALL[@]} -eq 0 ]; then
    log_info "No packages selected for installation."
    exit 0
fi

# FIX: Use "${PM_CMD[@]}" (array expansion) instead of unquoted $PM_CMD
# (string) to avoid word-splitting and glob expansion on invocation.
log_info "Installing chosen packages via ${BOLD}${PM_NAME}${NC}..."
"${PM_CMD[@]}" "${PACKAGES_TO_INSTALL[@]}"

log_success "Dependency installation cycle completed!"
