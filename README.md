# The Dependency Installer

A Bash script that installs all dependencies for my dotfiles. It detects your Linux distro, resolves the correct package names for your package manager, installs everything in one batch, and handles post-install setup automatically.

> **Recommended platform: Fedora.** This script is written and tested on Fedora. It has cross-distro support for Debian/Ubuntu, Arch Linux, openSUSE Tumbleweed, and Alpine Linux, but these are provided on a best-effort basis and are not tested. If you are on a supported non-Fedora distro, things will likely work, but you will need to handle edge cases yourself.

---

## Requirements

- Bash 4.0 or later
- `sudo` privaleges
- `curl` — used by the starship installer
- `cargo`

---

## Quick Start

```bash
chmod +x dep-install.sh

# If you want to preview what would be installed on your system
./dep-install.sh --dry-run

# Run the full install
./dep-install.sh
```

---

## Usage

| Flag | Description |
|---|---|
| `-n` / `--dry-run` | Show what would be installed without making any changes |
| `-i` / `--interactive` | Prompt for confirmation before each package |
| `-h` / `--help` | Display help and exit |

### Examples

```bash
# See exactly what the script would install
./dep-install.sh --dry-run

# Confirm each package individually before installing
./dep-install.sh --interactive

# Flags can be combined
./dep-install.sh --dry-run --interactive
```

---

## What Gets Installed

The script works in three separate phases:

### Phase 1 — Package Manager

All packages that are available in official distro repositories are installed in a single batch call. Already-installed packages are skipped automatically.

| Package | Description |
|---|---|
| `stow` | GNU Stow — used to manage symlinks |
| `curl` | Used by the starship installer |
| `cargo` | Rust toolchain — required for Phase 2 installs |
| `neovim` | Text editor |
| `fish` | Fish shell |
| `kitty` | My terminal emulator of choice |
| `fastfetch` | System info display |
| `fuzzel` | Wayland application launcher |
| `kanshi` | Wayland output management daemon |
| `mako` | Wayland notification daemon |
| `mpd` | Music Player Daemon |
| `mpc` | CLI client for mpd |
| `mpv` | Video/audio player |
| `sway` | Wayland compositor |
| `swayidle` | Idle timeout management for sway |
| `swaylock` | Screen locker for sway |
| `waybar` | Wayland status bar |
| `yazi` | Terminal file manager |
| `dosbox-staging` | DOSBox fork (Debian/Ubuntu/openSUSE/Alpine use `dosbox` instead) |
| `ulauncher` | Application launcher (Fedora and Debian/Ubuntu only — see [Distro Notes](#distro-notes)) |
| `swaync` | Notification centre for sway (all distros except Fedora and Alpine — see [Distro Notes](#distro-notes)) |

### Phase 2 — Non-Package-Manager Installs

These tools are either unavailable in distro repos or have a preferred official install method.

| Tool | Method | Notes |
|---|---|---|
| `swaync` | `dnf` + COPR | **Fedora only.** The script enables the `erikreider/SwayNotificationCenter` COPR automatically, then installs. Other distros install swaync in Phase 1. |
| `rmpc` | `cargo install rmpc` | Rust TUI client for mpd. Not in any major distro repo. |
| `mpd-discord-rpc` | `cargo install mpd-discord-rpc` | Discord Rich Presence for mpd. |
| `starship` | `curl` official installer | Cross-shell prompt. The official installer is preferred over distro packages. |

### Phase 3 — Post-Install Setup

Runs automatically after all installs, with no user interaction required.

- **mpd** — enabled and started as a systemd user service (`systemctl --user enable --now mpd`)
- **mpd-discord-rpc** — enabled as a systemd user service if a unit file exists at `~/.config/systemd/user/mpd-discord-rpc.service`. See [mpd-discord-rpc](#mpd-discord-rpc-service) below.
- **starship** — appends `starship init fish | source` to `~/.config/fish/config.fish`. Skips safely if the line is already present.

---

## Distro Notes

### Fedora is Recommended

All packages are available. swaync requires a COPR repo which the script enables automatically. Everything else installs from official Fedora repositories. Already installed packages are also skipped.

`* = kinda...`

### Debian / Ubuntu is *Supported* *

Most packages install cleanly. A few version notes:

- `swaync` (`sway-notification-center`) requires Ubuntu 23.04 (Lunar) or Debian 12 (Bookworm) or later. Earlier releases do not have it in their repos.
- `dosbox-staging` is not available; `dosbox` is installed instead (older upstream fork).

Already-installed packages are a noop by default with `apt-get`.

### Arch Linux (Along with Arch-based distros) *Supported* *

Most packages are in the official repos. Two exceptions:

- `ulauncher` is **AUR only** — the script skips it and prints a reminder. Install manually with `yay -S ulauncher` or your preferred AUR helper.
- `swaync` (`swaync`) is in the official community repo and installs normally.

Already-installed packages are skipped via `pacman --needed`.

### openSUSE Tumbleweed *Supported* *

Most packages are available. Two exceptions:

- `ulauncher` requires an OBS community repository and is not installed by the script. See [software.opensuse.org/package/ulauncher](https://software.opensuse.org/package/ulauncher) to add the repo manually.
- `fuzzel` and `kanshi` are not available in Alpine repos and will be skipped.
- `swaync` is available as `SwayNotificationCenter` in the official repos and installs normally.

Already-installed packages are a no-op by default with `zypper`.

### Alpine Linux *Supported* (but limited) *

Alpine is the most limited target. Several packages are missing from Alpine's repos and will be skipped:

- `fuzzel` — not packaged
- `kanshi` — not packaged
- `swaync` — not packaged
- `ulauncher` — not packaged

Already-installed packages are a no-op by default with `apk`.

---

## Manual Steps

A few things the script intentionally does not handle:

### ulauncher on **unsupported** distros

- **Arch**: `yay -S ulauncher` (or equivalent AUR helper)
- **openSUSE**: add the OBS community repo first — see [software.opensuse.org/package/ulauncher](https://software.opensuse.org/package/ulauncher)
- **Alpine**: no package available

### mpd-discord-rpc service

`cargo install` drops the binary into `~/.cargo/bin` but does not create a systemd unit file. You need to create one yourself at `~/.config/systemd/user/mpd-discord-rpc.service`. A minimal example:

```ini
[Unit]
Description=MPD Discord Rich Presence
After=mpd.service

[Service]
ExecStart=%h/.cargo/bin/mpd-discord-rpc
Restart=on-failure

[Install]
WantedBy=default.target
```

Once created, re-run the script (Phase 3 will pick it up), or enable it manually:

```bash
systemctl --user enable --now mpd-discord-rpc
```
