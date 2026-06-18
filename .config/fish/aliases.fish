# ┌─────────┐
# │ Aliases │
# └─────────┘

# ── Listing ──
alias ls 'eza -1 --icons=auto'
alias l 'eza -lh --icons=auto'
alias ll 'eza -lha --icons=auto --sort=name --group-directories-first'
alias ld 'eza -lhD --icons=auto'
alias lt 'eza --icons=auto --tree'
alias ltt 'eza --tree --level=2 --long --icons --git'
alias lta 'lt -a'

# ── Editors ──
abbr -a n nvim

# ── Config files ──
alias bfile 'nvim ~/.bashrc'
alias ffile 'nvim ~/.config/fish/config.fish'

# ── File managers & terminals ──
abbr -a zz yazi
abbr -a open 'thunar .'

# ── Search & history ──
abbr -a h "history | grep "

# ── TTY fonts ──
abbr -a bigfont "setfont ter-132b"
abbr -a regfont "setfont default8x16"

# ── Safety wrappers ──
abbr -a mkdir 'mkdir -p'
abbr -a ping 'ping -c 10'
abbr -a tar "tar -xvf"

# ── Shell switching ──
alias tobash "chsh $USER -s /usr/bin/bash && echo 'Log out and log back in for change to take effect.'"
alias tofish "chsh $USER -s /usr/bin/fish && echo 'Log out and log back in for change to take effect.'"

# ── Misc ──
abbr -a chx 'chmod +x'
abbr -a x exit

# ── GRUB ──
alias grub-up 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg'


