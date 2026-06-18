#!/bin/bash

set -e

DOTFILES_DIR="$(dirname "$(readlink -f "$0")")"
cd "$DOTFILES_DIR"

SYS_PKGS=("sddm-themes")

echo "=================================================="
echo "Deploying Dotfiles via GNU Stow"
echo "=================================================="

echo "Removing existing symlinks..."

stow -D -t "$HOME" . 2>/dev/null || true

for pkg in "${SYS_PKGS[@]}"; do
    if [ -d "$pkg" ]; then
        sudo stow -D -t / "$pkg" 2>/dev/null || true
    fi
done

echo "Re-stowing packages..."

echo "  -> Stowing user configurations"
stow -R -t "$HOME" .

for pkg in "${SYS_PKGS[@]}"; do
    if [ -d "$pkg" ]; then
        echo "  -> Stowing system package: $pkg (requires sudo)"
        sudo stow -R -t / "$pkg"
    fi
done

echo "=================================================="
echo "Dotfiles successfully stowed!"
echo "=================================================="
