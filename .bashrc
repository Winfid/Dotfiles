# .bashrc

(cat ~/.cache/wal/sequences &)

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

alias snvim="sudoedit"
alias ls="ls -a --color=auto"

unset rc
. "$HOME/.cargo/env"

# Open Watcom
export WATCOM=/opt/watcom
export PATH=$PATH:$WATCOM/binl:$WATCOM/binw
export INCLUDE=$WATCOM/h
export EDPATH=$WATCOM/eddat
export WIPFC=$WATCOM/wipfc
