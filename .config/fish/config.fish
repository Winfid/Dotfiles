set -g fish_greeting
fish_default_key_bindings

# Environment
set -gx EDITOR nvim
set -gx SUDO_EDITOR $EDITOR
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx MANPAGER "nvim +Man!"
set -gx MPD_HOST "/run/user/"(id -u)"/mpd/socket"

# PATH
fish_add_path ~/.local/bin
fish_add_path ~/.local/scripts

# Keybinds
bind \ck sessionizer

# Tools
starship init fish | source

# Aliases
source ~/.config/fish/aliases.fish
