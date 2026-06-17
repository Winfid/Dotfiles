#!/usr/bin/env bash

# ==============================================================================
# Dotfiles Dependency Installer
# Supports: Fedora, Debian/Ubuntu, Arch Linux, openSUSE, Alpine
#
# Package manager deps are installed in one batch via the system PM.
# Non-PM deps (starship, mpd-discord-rpc, rmpc, swaync on Fedora) are handled
# in a separate phase. Post-install setup (services, shell config) runs last.
# ==============================================================================

set -e

# --- Color / Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

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
    echo "  -n, --dry-run      Show what would be installed without making any changes."
    echo "  -h, --help         Display this help message."
    echo ""
    echo -e "${BOLD}Notes:${NC}"
    echo "  starship is installed via the official curl installer."
    echo "  mpd-discord-rpc and rmpc are installed via 'cargo install'."
    echo "  swaync on Fedora requires a COPR repo enable before install."
    echo "  All non-PM installs require internet access."
    echo ""
}

# --- Parse Arguments ---
INTERACTIVE_MODE=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive) INTERACTIVE_MODE=true; shift ;;
        -n|--dry-run)     DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# ==============================================================================
# PACKAGE MAP
# ==============================================================================
# FORMAT: ["fedora_key"]="fedora_name debian_name arch_name opensuse_name alpine_name"
#
# Index:                          0        1           2       3             4
#
# Notes per package:
#   dosbox-staging  — Fedora/Arch have dosbox-staging; Debian only has 'dosbox'
#                     (staging is newer fork). openSUSE/Alpine: 'dosbox' only.
#   fuzzel          — Wayland launcher; not in Alpine repos (left blank → skip).
#   kanshi          — Wayland output mgmt; not in Alpine repos.
#   labwc           — NOT included: confirmed sway is the active compositor.
#   mako            — Wayland notification daemon.
#   mpd             — Music Player Daemon.
#   mpc             — CLI client for mpd (companion tool, no config needed).
#   mpv             — Video/audio player.
#   neovim          — Text editor; no config dir yet but intentionally included.
#   rmpc            — Rust TUI for mpd; not in distro repos → installed via cargo.
#   sway            — Wayland compositor.
#   swayidle        — Idle management for sway.
#   swaylock        — Screen locker for sway.
#   swaync          — Notification centre for sway.
#                     Fedora: requires COPR, handled separately in Phase 2.
#                     Debian/Ubuntu: 'sway-notification-center' (in repos since Lunar/Bookworm).
#                     Arch: 'swaync' (official repos).
#                     openSUSE: 'SwayNotificationCenter' (official repos).
#                     Alpine: not packaged (left blank).
#   ulauncher       — App launcher.
#                     Fedora: 'ulauncher' (official repos).
#                     Debian/Ubuntu: 'ulauncher' (official repos).
#                     Arch: AUR only (left blank — use yay or equivalent).
#                     openSUSE: requires an OBS community repo (left blank).
#                     Alpine: not packaged (left blank).
#   waybar          — Wayland bar.
#   yazi            — Terminal file manager.
#   fastfetch       — System info tool.
#   fish            — Fish shell.
#   kitty           — GPU terminal emulator.
#   stow            — GNU Stow, for managing the dotfiles themselves.
#   curl            — Used by the starship installer; almost always pre-installed.
#   cargo           — Rust toolchain; needed for mpd-discord-rpc and rmpc.
#                     Package is 'cargo' on all supported distros.
# ==============================================================================

declare -A PKG_MAP=(
# key                  fedora                 debian                   arch             opensuse   alpine
["stow"]="             stow                   stow                     stow             stow       stow"
["curl"]="             curl                   curl                     curl             curl       curl"
["cargo"]="            cargo                  cargo                    cargo            cargo      cargo"
["neovim"]="           neovim                 neovim                   neovim           neovim     neovim"
["fish"]="             fish                   fish                     fish             fish       fish"
["kitty"]="            kitty                  kitty                    kitty            kitty      kitty"
["fastfetch"]="        fastfetch              fastfetch                fastfetch        fastfetch  fastfetch"
["fuzzel"]="           fuzzel                 fuzzel                   fuzzel           fuzzel     "
["kanshi"]="           kanshi                 kanshi                   kanshi           kanshi     "
["mako"]="             mako                   mako                     mako             mako       mako"
["mpd"]="              mpd                    mpd                      mpd              mpd        mpd"
["mpc"]="              mpc                    mpc                      mpc              mpc        mpc"
["mpv"]="              mpv                    mpv                      mpv              mpv        mpv"
["sway"]="             sway                   sway                     sway             sway       sway"
["swayidle"]="         swayidle               swayidle                 swayidle         swayidle   swayidle"
["swaylock"]="         swaylock               swaylock                 swaylock         swaylock   swaylock"
["swaync"]="                               sway-notification-center swaync           SwayNotificationCenter "
["waybar"]="           waybar                 waybar                   waybar           waybar     waybar"
["yazi"]="             yazi                   yazi                     yazi             yazi       yazi"
["dosbox-staging"]="   dosbox-staging         dosbox                   dosbox-staging   dosbox     dosbox"
["ulauncher"]="        ulauncher              ulauncher                                             "
)

# Explicit order — determines prompt order in interactive mode and install order.
# swaync and ulauncher are at the end as they're the most distro-variable.
PKG_ORDER=(
    stow
    curl
    cargo
    neovim
    fish
    kitty
    fastfetch
    fuzzel
    kanshi
    mako
    mpd
    mpc
    mpv
    sway
    swayidle
    swaylock
    waybar
    yazi
    dosbox-staging
    swaync
    ulauncher
)

# ==============================================================================
# DISTRO DETECTION
# ==============================================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            fedora)                echo "fedora"   ;;
            debian|ubuntu|pop-os)  echo "debian"   ;;
            arch|manjaro)          echo "arch"     ;;
            opensuse*|sles)        echo "opensuse" ;;
            alpine)                echo "alpine"   ;;
            *)
                for like in $ID_LIKE; do
                    case "$like" in
                        fedora)         echo "fedora";   return ;;
                        debian|ubuntu)  echo "debian";   return ;;
                        arch)           echo "arch";     return ;;
                        opensuse|suse)  echo "opensuse"; return ;;
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
    log_error "Unsupported distribution. Supported: Fedora, Debian/Ubuntu, Arch, openSUSE, Alpine."
    exit 1
fi

log_info "Detected distro family: ${BOLD}${DISTRO}${NC}"

# ==============================================================================
# PACKAGE MANAGER SETUP
# ==============================================================================
# PM_INDEX: which column of PKG_MAP to read for this distro.
# Columns:   fedora=0  debian=1  arch=2  opensuse=3  alpine=4
#
# Skip-if-installed behaviour:
#   dnf:     --skip-installed (skips already-installed packages; dnf5 / Fedora 41+)
#   pacman:  --needed         (skips packages already at the correct version)
#   apt-get: default behaviour — already-installed packages are a no-op
#   zypper:  default behaviour — already-installed packages are a no-op
#   apk:     default behaviour — already-installed packages are a no-op
case "$DISTRO" in
    fedora)   PM_CMD=(sudo dnf install -y --skip-installed); PM_NAME="dnf";     PM_INDEX=0 ;;
    debian)   PM_CMD=(sudo apt-get install -y);              PM_NAME="apt-get"; PM_INDEX=1 ;;
    arch)     PM_CMD=(sudo pacman -S --noconfirm --needed);  PM_NAME="pacman";  PM_INDEX=2 ;;
    opensuse) PM_CMD=(sudo zypper install -y);               PM_NAME="zypper";  PM_INDEX=3 ;;
    alpine)   PM_CMD=(sudo apk add);                         PM_NAME="apk";     PM_INDEX=4 ;;
esac

if [ "$DISTRO" = "debian" ]; then
    log_info "Running apt-get update..."
    sudo apt-get update -y
fi

# ==============================================================================
# INTERACTIVE MODE WARNING
# ==============================================================================
if [ "$INTERACTIVE_MODE" = true ]; then
    echo -e "${RED}${BOLD}"
    echo "====================================================================="
    echo "                            WARNING!"
    echo "====================================================================="
    echo -e "${NC}"
    log_warn "Skipping certain packages may cause severe instability or break features"
    log_warn "within this specific dotfiles configuration."
    log_warn "Only proceed if you know exactly what you are doing."
    echo ""
    if ! read -r -p "Do you understand the risks and wish to continue? (y/N): " confirm </dev/tty; then
        log_error "Cannot read from terminal. Run the script directly, or omit --interactive."
        exit 1
    fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Installation aborted by user."
        exit 0
    fi
fi

# ==============================================================================
# PHASE 1 — PACKAGE MANAGER INSTALLS
# ==============================================================================
if [ "$DRY_RUN" = true ]; then
    log_info "--- Phase 1: Package Manager Installs (DRY RUN) ---"
else
    log_info "--- Phase 1: Package Manager Installs ---"
fi

PACKAGES_TO_INSTALL=()
SKIPPED_NO_PKG=()

for key in "${PKG_ORDER[@]}"; do
    if [ -z "${PKG_MAP[$key]+isset}" ]; then
        log_warn "'$key' is in PKG_ORDER but missing from PKG_MAP. Skipping."
        continue
    fi

    # Read the correct column for this distro.
    # sed strips any leading whitespace first, then tr -s collapses internal
    # runs of spaces, so PM_INDEX 0 reliably lands on the first package name
    # regardless of the visual alignment padding used in PKG_MAP above.
    read -r -a cols <<< "$(echo "${PKG_MAP[$key]}" | sed 's/^[[:space:]]*//' | tr -s ' ')"
    target_pkg="${cols[$PM_INDEX]}"

    if [ -z "$target_pkg" ]; then
        SKIPPED_NO_PKG+=("$key")
        log_warn "'$key' has no package mapping for $DISTRO — skipping (see manual steps below)."
        continue
    fi

    if [ "$INTERACTIVE_MODE" = true ] && [ "$DRY_RUN" = false ]; then
        if ! read -r -p "Install '$key' (as '$target_pkg' on $DISTRO)? (y/N): " choice </dev/tty; then
            log_error "Cannot read from terminal. Aborting."
            exit 1
        fi
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            PACKAGES_TO_INSTALL+=("$target_pkg")
        fi
    else
        PACKAGES_TO_INSTALL+=("$target_pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -eq 0 ]; then
    log_info "No packages selected for installation. Skipping Phase 1."
elif [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "  ${BOLD}Would install via ${PM_NAME}:${NC}"
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        echo "    + $pkg"
    done
    echo ""
else
    log_info "Installing via ${BOLD}${PM_NAME}${NC}: ${PACKAGES_TO_INSTALL[*]}"
    "${PM_CMD[@]}" "${PACKAGES_TO_INSTALL[@]}"
    log_success "Phase 1 complete."
fi

# ==============================================================================
# PHASE 2 — NON-PACKAGE-MANAGER INSTALLS
# ==============================================================================
# These tools either have no distro package, or their official install method
# is preferred over any distro-packaged version.
# ==============================================================================
if [ "$DRY_RUN" = true ]; then
    log_info "--- Phase 2: Non-PM Installs (DRY RUN) ---"
    echo ""
    echo -e "  ${BOLD}Would install via non-PM methods:${NC}"
    echo "    + swaync          (Fedora only: dnf after enabling COPR erikreider/SwayNotificationCenter)"
    echo "    + rmpc            (cargo install rmpc)"
    echo "    + mpd-discord-rpc (cargo install mpd-discord-rpc)"
    echo "    + starship        (curl https://starship.rs/install.sh)"
    echo ""
    log_info "--- Phase 3: Post-Install Setup (DRY RUN) ---"
    echo ""
    echo -e "  ${BOLD}Would perform:${NC}"
    echo "    * systemctl --user enable --now mpd"
    echo "    * systemctl --user enable --now mpd-discord-rpc  (only if unit file exists)"
    echo "    * Append 'starship init fish | source' to ~/.config/fish/config.fish"
    echo ""
    log_info "Dry run complete. No changes were made."
    exit 0
fi

log_info "--- Phase 2: Non-PM Installs ---"

# ------------------------------------------------------------------------------
# rmpc — Rust TUI client for mpd. Not in any major distro repo; install via cargo.
# ------------------------------------------------------------------------------
install_rmpc() {
    if command -v rmpc &>/dev/null; then
        log_info "rmpc is already installed ($(rmpc --version 2>/dev/null || echo 'version unknown')). Skipping."
        return
    fi
    if ! command -v cargo &>/dev/null; then
        log_error "cargo is not available. Cannot install rmpc. Install cargo first (it should have been installed in Phase 1)."
        return 1
    fi
    log_info "Installing rmpc via cargo..."
    cargo install rmpc
    log_success "rmpc installed."
}

# ------------------------------------------------------------------------------
# mpd-discord-rpc — Discord Rich Presence for mpd. Install via cargo.
# ------------------------------------------------------------------------------
install_mpd_discord_rpc() {
    if command -v mpd-discord-rpc &>/dev/null; then
        log_info "mpd-discord-rpc is already installed. Skipping."
        return
    fi
    if ! command -v cargo &>/dev/null; then
        log_error "cargo is not available. Cannot install mpd-discord-rpc."
        return 1
    fi
    log_info "Installing mpd-discord-rpc via cargo..."
    cargo install mpd-discord-rpc
    log_success "mpd-discord-rpc installed."
}

# ------------------------------------------------------------------------------
# starship — Cross-shell prompt. Official installer is the recommended method.
# After install, add the following to ~/.config/fish/config.fish:
#   starship init fish | source
# ------------------------------------------------------------------------------
install_starship() {
    if command -v starship &>/dev/null; then
        log_info "starship is already installed ($(starship --version)). Skipping."
        return
    fi
    if ! command -v curl &>/dev/null; then
        log_error "curl is not available. Cannot install starship."
        return 1
    fi
    log_info "Installing starship via official installer..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    log_success "starship installed."
    log_warn "Remember to add 'starship init fish | source' to ~/.config/fish/config.fish"
}

# ------------------------------------------------------------------------------
# swaync — On Fedora, swaync is not in the official repos; it requires enabling
# the author's COPR before installing. On all other supported distros it is in
# PKG_MAP and installed in Phase 1 already.
# ------------------------------------------------------------------------------
install_swaync() {
    if [ "$DISTRO" != "fedora" ]; then
        log_info "swaync is handled via the package manager on $DISTRO. Skipping Phase 2 step."
        return
    fi
    if command -v swaync &>/dev/null; then
        log_info "swaync is already installed. Skipping."
        return
    fi
    log_info "Enabling SwayNotificationCenter COPR and installing swaync on Fedora..."
    sudo dnf copr enable -y erikreider/SwayNotificationCenter
    sudo dnf install -y SwayNotificationCenter
    log_success "swaync installed."
}

# Run each non-PM installer (respecting interactive mode)
NON_PM_INSTALLS=(
    "swaync:install_swaync"
    "rmpc:install_rmpc"
    "mpd-discord-rpc:install_mpd_discord_rpc"
    "starship:install_starship"
)

for entry in "${NON_PM_INSTALLS[@]}"; do
    name="${entry%%:*}"
    fn="${entry##*:}"

    if [ "$INTERACTIVE_MODE" = true ]; then
        if ! read -r -p "Install '$name' (non-PM method)? (y/N): " choice </dev/tty; then
            log_error "Cannot read from terminal. Aborting."
            exit 1
        fi
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            $fn
        fi
    else
        $fn
    fi
done

log_success "Phase 2 complete."

# ==============================================================================
# PHASE 3 — POST-INSTALL SETUP
# ==============================================================================
log_info "--- Phase 3: Post-Install Setup ---"

# ------------------------------------------------------------------------------
# Enable mpd as a systemd user service.
# ------------------------------------------------------------------------------
if command -v mpd &>/dev/null && command -v systemctl &>/dev/null; then
    log_info "Enabling and starting mpd user service..."
    systemctl --user enable --now mpd
    log_success "mpd user service enabled."
else
    log_warn "mpd or systemctl not found; skipping mpd service setup."
fi

# ------------------------------------------------------------------------------
# Enable mpd-discord-rpc as a systemd user service.
# cargo installs the binary but does NOT install a systemd unit file — the user
# must create ~/.config/systemd/user/mpd-discord-rpc.service themselves.
# This step only enables the service if that unit file already exists.
# ------------------------------------------------------------------------------
MPD_RPC_UNIT="${HOME}/.config/systemd/user/mpd-discord-rpc.service"
if [ -f "$MPD_RPC_UNIT" ] && command -v systemctl &>/dev/null; then
    log_info "Enabling and starting mpd-discord-rpc user service..."
    systemctl --user enable --now mpd-discord-rpc
    log_success "mpd-discord-rpc user service enabled."
elif command -v mpd-discord-rpc &>/dev/null; then
    log_warn "mpd-discord-rpc is installed but no user service unit was found at:"
    log_warn "  ${MPD_RPC_UNIT}"
    log_warn "Create that file and re-run, or enable the service manually."
fi

# ------------------------------------------------------------------------------
# Add starship initialisation to fish config.
# Guards against duplicate appends if the script is run more than once.
# ------------------------------------------------------------------------------
FISH_CONFIG="${HOME}/.config/fish/config.fish"
STARSHIP_INIT_LINE="starship init fish | source"

if command -v starship &>/dev/null; then
    if [ -f "$FISH_CONFIG" ] && grep -qF "$STARSHIP_INIT_LINE" "$FISH_CONFIG"; then
        log_info "Starship init line already present in ${FISH_CONFIG}. Skipping."
    else
        mkdir -p "$(dirname "$FISH_CONFIG")"
        echo "$STARSHIP_INIT_LINE" >> "$FISH_CONFIG"
        log_success "Added '$STARSHIP_INIT_LINE' to ${FISH_CONFIG}."
    fi
else
    log_warn "starship not found; skipping fish config update."
fi

log_success "Phase 3 complete."

# ==============================================================================
# SUMMARY
# ==============================================================================
echo ""
echo -e "${BOLD}====================================================================="
echo -e "  Installation Summary"
echo -e "=====================================================================${NC}"
log_success "Phase 1 (PM): ${#PACKAGES_TO_INSTALL[@]} package(s) installed via ${PM_NAME}."

if [ ${#SKIPPED_NO_PKG[@]} -gt 0 ]; then
    log_warn "The following had no package for ${DISTRO} and were skipped:"
    for p in "${SKIPPED_NO_PKG[@]}"; do
        echo "    - $p"
    done
fi

echo ""
log_info "Manual steps that this script does NOT handle:"
echo "  - ulauncher on Arch:     AUR only — use 'yay -S ulauncher' or equivalent."
echo "  - ulauncher on openSUSE: requires an OBS community repo — see https://software.opensuse.org/package/ulauncher"
echo "  - ulauncher on Alpine:   no package available."
echo "  - mpd-discord-rpc service: create ~/.config/systemd/user/mpd-discord-rpc.service"
echo "    then run: systemctl --user enable --now mpd-discord-rpc"
echo ""
log_success "All done!"
