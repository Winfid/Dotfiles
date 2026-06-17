# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi

alias ls="ls -a --color=auto"

unset rc
. "$HOME/.cargo/env"

# Open Watcom
export WATCOM=/opt/watcom
export PATH=$PATH:$WATCOM/binl:$WATCOM/binw
export INCLUDE=$WATCOM/h
export EDPATH=$WATCOM/eddat
export WIPFC=$WATCOM/wipfc

export LXQT_WAYLAND_COMPOSITOR="labwc"
