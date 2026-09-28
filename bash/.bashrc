#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# Fallout green palette on the text console
if [ "$TERM" = "linux" ]; then
    printf '\e]P007130b\e]P767d97a\e]P29dffae\e]P1e0a33a\e]PFc8ffd2'
    clear
fi

# Console font sized for this machine's display (scripts/rice-profile)
[ -r ~/.config/rice/profile ] && . ~/.config/rice/profile
[ "$TERM" = "linux" ] && setfont "${RICE_CONSOLE_FONT:-fallout-16x34}" 2>/dev/null
