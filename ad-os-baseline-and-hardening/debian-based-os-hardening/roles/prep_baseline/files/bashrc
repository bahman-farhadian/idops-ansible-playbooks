# ~/.bashrc (Linux)

# If not running interactively, bail
case $- in
    *i*) ;;
      *) return;;
esac

# Start tmux automatically. Set NO_AUTO_TMUX=1 to skip it. tmux is run rather
# than exec'd so that a broken tmux config drops you at a usable shell instead
# of closing the terminal.
#
# Every SSH login lands in a tmux session of its own, ssh1, ssh2 and so on, for
# whichever account is logging in. One session shared between two connections
# mirrors them: both clients see the same windows, and tmux sizes them for the
# smaller, which crops one and leaves an unpainted band in the other. The same
# argument separates remote sessions from local ones.
#
# A dropped connection is the exception worth having. Reconnecting attaches to a
# detached ssh session rather than opening yet another, so the work survives a
# lost link — which is the reason for running tmux over SSH in the first place.
#
# "Am I already inside tmux, on this machine?" $TMUX answers it outright, but
# sudo -i and su - scrub the environment, so a shell that really is in a pane
# can arrive with it unset. Walking up the process tree answers it anyway:
# those commands change the environment, not who the parent is.
#
# $TERM is no help and was actively wrong here. ssh carries the client's TERM
# across, so a login from a tmux window on another machine arrives reading
# tmux-256color with no tmux running on this one — and a test on $TERM then
# skips every SSH session it exists to serve.
#
# Over SSH it asks first, apt-style: Enter takes the default and starts tmux, n
# declines. tmux repaints the whole screen as it starts, which wipes the
# pre-authentication banner before anyone can read it, so taking the terminal
# outright would make that banner pointless on exactly the logins it is for.
# There is deliberately no timeout — a prompt that gave up on its own would
# clear the banner while it was still being read, which is the thing it exists
# to prevent. Local terminals are not asked: no banner is shown there.
_in_mux=""
if [ -n "$TMUX" ]; then
    _in_mux=1
else
    _p=$PPID
    while [ "${_p:-0}" -gt 1 ]; do
        read -r _pcomm < "/proc/$_p/comm" 2>/dev/null || break
        case "$_pcomm" in tmux*) _in_mux=1; break ;; esac
        _p=$(awk '/^PPid:/{print $2}' "/proc/$_p/status" 2>/dev/null)
    done
    unset _p _pcomm
fi
if [ -z "$TMUX" ] && [ -z "$_in_mux" ] && [ -z "$NO_AUTO_TMUX" ] && command -v tmux &>/dev/null; then
    if [ -n "$SSH_CONNECTION" ]; then
        _tmux_orphan=$(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null \
                       | awk '$1 ~ /^ssh[0-9]+$/ && $2 == 0 { print $1; exit }')
        if [ -n "$_tmux_orphan" ]; then
            _tmux_prompt="Reattach to tmux session $_tmux_orphan?"
        else
            _n=1
            while tmux has-session -t "=ssh$_n" 2>/dev/null; do _n=$((_n + 1)); done
            _tmux_prompt="Start tmux session ssh$_n?"
        fi
        # No terminal on stdin means no tmux either: it would fail to open one.
        if [ -t 0 ]; then
            printf '%s [Y/n] ' "$_tmux_prompt"
            read -r _reply || { _reply=n; printf '\n'; }
        else
            _reply=n
        fi
        case "$_reply" in
            [Nn]*) printf 'No tmux. Run `tmux` to start one, or log in again.\n' ;;
            *)
                if [ -n "$_tmux_orphan" ]; then
                    tmux attach-session -t "$_tmux_orphan" && exit
                else
                    # Recomputed rather than reused: the wait for an answer is
                    # long enough for another login to have taken the name.
                    _n=1
                    while tmux has-session -t "=ssh$_n" 2>/dev/null; do _n=$((_n + 1)); done
                    tmux new-session -s "ssh$_n" && exit
                fi
                ;;
        esac
        unset _tmux_orphan _tmux_prompt _reply _n
    else
        _tmux_detached=$(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null \
                         | awk '$1 !~ /^ssh[0-9]*$/ && $2 == 0 { print $1; exit }')
        if [ -n "$_tmux_detached" ]; then
            tmux attach-session -t "$_tmux_detached" && exit
        else
            tmux new-session && exit
        fi
        unset _tmux_detached
    fi
fi
unset _in_mux

# History. ignoreboth is ignoredups plus ignorespace, so a command typed with a
# leading space is never written to the file — that is the way to keep a
# password or a token out of it. erasedups drops older copies of a repeat.
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend
shopt -s checkwinsize

# PATH extras. Debian gives root the sbin directories but leaves them out for
# everyone else, so sysctl, swapon and efibootmgr read as "command not found"
# for a user who can run them under sudo anyway. Adding them here makes this
# user's PATH cover the same directories as root's. The case test stops a
# re-sourced .bashrc from stacking duplicate entries.
_path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}
_path_prepend /sbin
_path_prepend /usr/sbin
_path_prepend /usr/local/sbin
_path_prepend /usr/local/bin
_path_prepend "$HOME/.local/bin"
unset -f _path_prepend
export PATH

# Editor
export EDITOR=vim
export VISUAL=vim

# Prevent venv from overwriting our custom prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Gruvbox dark — foreground colours only, no badges. Published values, used as
# they ship. The bright variants carry the prompt because the normal ones sit
# too dark on bg0: blue is 3.48:1 normal against 5.48:1 bright, purple the same,
# red 2.69:1 against 4.29:1.
#
# Bright red is the one value under 4.5:1, at 4.29:1. It is Gruvbox's own
# pairing of bright red on bg0 and it only ever draws the single-character marks
# — the dirty asterisk, the root hash, the failed prompt symbol — all in bold.
#
# The colour lives here, in the prompt. The tmux bar uses the bg ramp so the two
# do not compete.

_C_GREEN='\[\e[38;2;184;187;38m\]'  # #b8bb26 bright green 7.14:1
_C_RED='\[\e[38;2;251;73;52m\]'  # #fb4934 bright red 4.29:1
_C_YELLOW='\[\e[38;2;250;189;47m\]'  # #fabd2f bright yellow 8.69:1
_C_BLUE='\[\e[38;2;131;165;152m\]'  # #83a598 bright blue 5.48:1
_C_PEACH='\[\e[38;2;254;128;25m\]'  # #fe8019 orange 5.84:1
_C_MAUVE='\[\e[38;2;211;134;155m\]'  # #d3869b bright purple 5.37:1
_C_SKY='\[\e[38;2;142;192;124m\]'  # #8ec07c bright aqua 7.01:1
_C_FLAMINGO='\[\e[38;2;213;196;161m\]'  # #d5c4a1 fg2 8.59:1
_C_GREY='\[\e[38;2;146;131;116m\]'  # #928374 gray 4.02:1
_C_RST='\[\e[0m\]'

# Segments are spread around the wheel so no two neighbours share a hue: green
# user, yellow host, blue path, orange branch, magenta venv, cyan k8s. The user
# name carries the privilege colour and is the only thing that changes; the host
# keeps its own so it never moves. Everything after the path is conditional and
# absent when it has nothing to say.
#
# The _C_PEACH, _C_MAUVE, _C_SKY and _C_FLAMINGO names are left over from an
# earlier palette. They now hold Gruvbox orange, bright purple, bright aqua and
# fg2; the names are kept only so the prompt builder below did not have to be
# rewritten for a colour change.
_set_prompt() {
    local exit_code=$?
    local line sym sym_col user_col
    local branch marks counts ahead behind stash kctx

    if [ "$(id -u)" -eq 0 ]; then
        user_col="$_C_RED"; sym='#'
    else
        user_col="$_C_GREEN"; sym='$'
    fi

    line="${user_col}\u${_C_RST} ${_C_GREY}@${_C_RST} ${_C_YELLOW}\h${_C_RST} ${_C_BLUE}\w${_C_RST}"

    if git -C "$PWD" rev-parse --is-inside-work-tree &>/dev/null; then
        branch=$(git -C "$PWD" symbolic-ref --quiet --short HEAD 2>/dev/null \
                 || git -C "$PWD" rev-parse --short HEAD 2>/dev/null)
        marks=""
        git -C "$PWD" diff --quiet 2>/dev/null          || marks+="${_C_RED}*"
        git -C "$PWD" diff --staged --quiet 2>/dev/null || marks+="${_C_GREEN}+"
        counts=$(git -C "$PWD" rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null)
        if [ -n "$counts" ]; then
            ahead=${counts%%[!0-9]*}
            behind=${counts##*[!0-9]}
            [ "${ahead:-0}" -gt 0 ]  && marks+="${_C_SKY}⇡${ahead}"
            [ "${behind:-0}" -gt 0 ] && marks+="${_C_SKY}⇣${behind}"
        fi
        stash=$(git -C "$PWD" stash list 2>/dev/null | wc -l | tr -d '[:space:]')
        [ "${stash:-0}" -gt 0 ] && marks+="${_C_FLAMINGO}{${stash}}"
        line+=" ${_C_PEACH}${branch}${marks}${_C_RST}"
    fi

    [ -n "$VIRTUAL_ENV" ] && \
        line+=" ${_C_MAUVE}venv:${VIRTUAL_ENV_PROMPT:-$(basename "$VIRTUAL_ENV")}${_C_RST}"

    if command -v kubectl &>/dev/null; then
        kctx=$(kubectl config current-context 2>/dev/null)
        [ -n "$kctx" ] && line+=" ${_C_SKY}k8s:${kctx}${_C_RST}"
    fi

    if [ "$exit_code" -eq 0 ]; then sym_col="$_C_GREEN"; else sym_col="$_C_RED"; fi
    PS1="${line} ${sym_col}${sym}${_C_RST} "
}
# history -a appends this shell's new lines to the file at every prompt rather
# than only at exit, so a tmux pane that is killed still keeps its history.
PROMPT_COMMAND='history -a; _set_prompt'

# ls colours — Linux uses --color=auto and LS_COLORS (set by dircolors)
alias ls='ls --color=auto'
command -v dircolors &>/dev/null && eval "$(dircolors -b)"

# bash-completion — package name varies by distro:
#   Debian/Ubuntu: bash-completion   Fedora/RHEL: bash-completion
_bc=""
for _p in /usr/share/bash-completion/bash_completion \
           /etc/bash_completion; do
    [ -r "$_p" ] && { _bc="$_p"; break; }
done
[ -n "$_bc" ] && . "$_bc"
unset _bc _p

# Strip tab-separated descriptions from COMPREPLY (cobra/kubectl/docker output)
_strip_comp_descriptions() {
    local i
    for i in "${!COMPREPLY[@]}"; do
        COMPREPLY[$i]="${COMPREPLY[$i]%%$'\t'*}"
    done
}

# CLI tool completions
_bash_load_completions() {
    type _get_comp_words_by_ref &>/dev/null || return 0

    local tool output comp_fn wrapper_fn
    for tool in kubectl helm flux kind k3d docker; do
        if command -v "$tool" &>/dev/null; then
            output=$("$tool" completion bash 2>/dev/null)
            if [ -n "$output" ]; then
                eval "$output"
                comp_fn=$(complete -p "$tool" 2>/dev/null | sed -n 's/.*-F \([^ ]*\).*/\1/p')
                if [ -n "$comp_fn" ]; then
                    wrapper_fn="_nodesc_${tool}"
                    eval "
${wrapper_fn}() {
    { ${comp_fn} \"\$@\"; } > /dev/null
    _strip_comp_descriptions
}
"
                    complete -F "$wrapper_fn" "$tool"
                fi
            fi
        fi
    done
    command -v kubectl &>/dev/null && complete -o default -F __start_kubectl k
    type _nodesc_docker &>/dev/null && complete -F _nodesc_docker d || true

    local _bcd="/usr/share/bash-completion/completions"
    if [ -r "$_bcd/git" ]; then
        . "$_bcd/git"
        type __git_complete &>/dev/null && __git_complete g __git_main || true
    fi
    # Debian ships no tmux completion, so install.sh fetches one into the user
    # directory. Upstream names its function _tmux; Debian's convention would be
    # _comp_cmd_tmux. Load whichever exists and bind the t alias to it.
    for _tc in "$HOME/.local/share/bash-completion/completions/tmux" "$_bcd/tmux"; do
        [ -r "$_tc" ] || continue
        . "$_tc"
        type _tmux          &>/dev/null && complete -F _tmux          t 2>/dev/null
        type _comp_cmd_tmux &>/dev/null && complete -F _comp_cmd_tmux t 2>/dev/null
        break
    done
    unset _tc
    [ -r "$_bcd/python3" ] && . "$_bcd/python3" && complete -F _comp_cmd_python py 2>/dev/null || true
}
_bash_load_completions
unset -f _bash_load_completions

# Ollama completion
if command -v ollama &>/dev/null; then
    _ollama_bash() {
        local cur prev
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        local subcmds="serve create show run pull push list ps cp rm help"
        if [ "$COMP_CWORD" -eq 1 ]; then
            COMPREPLY=($(compgen -W "$subcmds" -- "$cur"))
            return
        fi
        case "$prev" in
            run|show|cp|rm|push)
                local models
                models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')
                COMPREPLY=($(compgen -W "$models" -- "$cur"))
                ;;
        esac
    }
    complete -F _ollama_bash ollama
fi

# Aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# tmux shortcut
alias t='tmux'

# readline — set AFTER all completion loading so nothing can override these
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set completion-ignore-case on'
bind 'set mark-symlinked-directories on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
