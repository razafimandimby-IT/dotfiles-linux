# =============================================================================
#  .bashrc — Main Bash Configuration
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================

# ── If not running interactively, don't do anything ─────────────────────────
[[ $- != *i* ]] && return

# ── Editor ─────────────────────────────────────────────────────────────────
EDITOR="vim"
VISUAL="vim"
export EDITOR VISUAL

# ── Path ────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ── Color support ──────────────────────────────────────────────────────────
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume ls and grep support --color=auto
    color_prompt=yes
else
    color_prompt=
fi

# Load colors for prompt
if [ "$color_prompt" = yes ]; then
    # Reset
    Reset='\[\e[0m\]'       # Text Reset

    # Regular Colors
    Black='\[\e[0;30m\]'   # Black
    Red='\[\e[0;31m\]'     # Red
    Green='\[\e[0;32m\]'   # Green
    Yellow='\[\e[0;33m\]'  # Yellow
    Blue='\[\e[0;34m\]'    # Blue
    Purple='\[\e[0;35m\]'  # Purple
    Cyan='\[\e[0;36m\]'    # Cyan
    White='\[\e[0;37m\]'   # White

    # Bold
    BRed='\[\e[1;31m\]'    # Red
    BGreen='\[\e[1;32m\]'  # Green
    BYellow='\[\e[1;33m\]' # Yellow
    BBlue='\[\e[1;34m\]'   # Blue
    BPurple='\[\e[1;35m\]' # Purple
    BCyan='\[\e[1;36m\]'   # Cyan
    BWhite='\[\e[1;37m\]'  # White
fi

# ── LS Colors ──────────────────────────────────────────────────────────────
if [ "$color_prompt" = yes ]; then
    eval "$(dircolors -b 2>/dev/null)" || true
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
fi

# ── Git Branch in Prompt ───────────────────────────────────────────────────
__git_ps1() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        # Check dirty status
        if git diff --quiet --ignore-submodules HEAD 2>/dev/null; then
            echo " ($branch)"
        else
            echo " ($branch*)"
        fi
    fi
}

# ── Custom Prompt ──────────────────────────────────────────────────────────
if [ "$color_prompt" = yes ]; then
    PS1="${BGreen}\u${Reset}@${BBlue}\h${Reset}:${BYellow}\w${Reset}\$(__git_ps1)${Reset}\n${BWhite}\$${Reset} "
else
    PS1='\u@\h:\w$(__git_ps1)\n\$ '
fi
unset color_prompt

# ── Prompt exit status coloring ────────────────────────────────────────────
# Shows exit code in red when last command failed
__check_exit_status() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\[\e[0;31m\]✗ [$exit_code]\[\e[0m\] "
    fi
}

# ── History settings ───────────────────────────────────────────────────────
HISTCONTROL=ignoreboth          # Ignore duplicates and lines starting with space
HISTSIZE=10000                  # Number of lines kept in memory
HISTFILESIZE=20000              # Number of lines kept in history file
HISTTIMEFORMAT="%F %T "        # Timestamp format for history
HISTFILE="$HOME/.bash_history"
shopt -s histappend             # Append to history, don't overwrite
shopt -s cmdhist                # Save multi-line commands as one line
shopt -s checkwinsize          # Check window size after each command

# ── Completion ─────────────────────────────────────────────────────────────
# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# ── Shell options ──────────────────────────────────────────────────────────
shopt -s autocd                 # Type dir name to cd into it
shopt -s dirspell               # Spell-check directory names on cd
shopt -s extglob                # Extended pattern matching
shopt -s globstar               # ** globbing for recursive matching

# ── Source custom files ────────────────────────────────────────────────────
if [ -f "$HOME/.bash_aliases" ]; then
    source "$HOME/.bash_aliases"
fi

if [ -f "$HOME/.bash_functions" ]; then
    source "$HOME/.bash_functions"
fi

# ── Language ───────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ── Less / Man ─────────────────────────────────────────────────────────────
export LESS='-R -F -X -i'
export LESSOPEN='| /usr/bin/lesspipe %s 2>/dev/null'
export PAGER='less'

# ── FZF (if installed) ────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null)" || source /usr/share/doc/fzf/examples/key-bindings.bash 2>/dev/null || true
fi

# ── Miscellaneous ──────────────────────────────────────────────────────────
# Automatically correct simple typos in cd
shopt -s cdspell

# Don't clear the screen after quitting less
export LESSHISTFILE=-

# Show human-friendly sizes in df/du
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Safer rm / cp / mv
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Reload .bashrc
alias reload='source ~/.bashrc'

# Tree (if not installed, use find)
if ! command -v tree &>/dev/null; then
    alias tree='find . -print | sed -e "s;[^/]*/;|____;g;s;____|; |;g"'
fi
