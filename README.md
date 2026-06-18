# Sway Dotfiles (Fedora)

Personal sway configuration and scripts for Fedora. Managed with [GNU Stow](https://www.gnu.org/software/stow/) via `auto-stow.sh`.

---

## Deployment

Use `auto-stow.sh` to deploy everything. Do **not** stow packages manually — the script handles both user configs and system packages (e.g. SDDM themes) that require `sudo`.

```bash
cd ~/dotfiles
./auto-stow.sh
```

The script unstows everything first, then restows cleanly. System packages (those targeting `/` instead of `$HOME`) are stowed with `sudo` automatically.

---

## Scripts

All scripts live in `.local/scripts/` and are stowed to `~/.local/scripts/`.

| Script | Description |
|--------|-------------|
| `cheatsheet` | Paged fuzzel keybinding reference. Categories are read from `# ─── Section ───` comments in your sway config — no hardcoded categories. |
| `fuzzel-emoji` | Fuzzy emoji picker using fuzzel dmenu. Accepts `type` (default), `copy`, or `both` as argument. Emoji list is embedded in the script after `### DATA ###`. |
| `powermenu` | Fuzzel dmenu with Shutdown, Reboot, Suspend, and Logout actions. |
| `sddm-theme-switch` | Interactive TUI for selecting and configuring SDDM themes. Handles per-theme sub-options, fixes permissions for the SDDM system user, and redeploys via stow. |
| `set-wallpaper` | Sets wallpaper via `swaybg` from `~/Pictures/wallpapers/`. Takes `random` or `choose` (fuzzel picker) as argument. |
| `toggle-terminal-transparency` | Toggles background opacity for whichever of Kitty, Ghostty, and Alacritty configs are present. |
| `toggle-waybar` | Kills waybar if running, starts it if not. |
| `toggle-wlsunset` | Toggles `wlsunset` night mode at 4000 K, with a desktop notification on state change. |

---

## Acknowledgments

- [`sddm-theme-switch`](https://github.com/Darkkal44/qylock/blob/main/sddm.sh) — adapted from [qylock/sddm.sh](https://github.com/Darkkal44/qylock/blob/main/sddm.sh) by Darkkal44.
