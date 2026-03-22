# ─────────────────────────────────────────────────────────────────────────────
# ~/.zshrc  —  unified shell config (zsh, macOS + Linux)
# ─────────────────────────────────────────────────────────────────────────────

# ── OH-MY-ZSH ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
zstyle ':omz:update' mode disabled
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
    git
    history
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ── OS DETECTION ─────────────────────────────────────────────────────────────
IS_MAC=false
IS_LINUX=false
[[ $(uname -s) == "Darwin" ]] && IS_MAC=true || IS_LINUX=true

# ── HISTORY ──────────────────────────────────────────────────────────────────
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
# Don't store duplicates, share history across sessions
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# ── LOCALE ───────────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── EDITOR ───────────────────────────────────────────────────────────────────
export EDITOR="vim"
export MANPAGER="less -X"       # Don't clear screen after man page
export LESS_TERMCAP_md="${yellow}"

# ── PATH ─────────────────────────────────────────────────────────────────────
# homebrew (macOS)
$IS_MAC && export PATH="/opt/homebrew/bin:$PATH"

# user bins
[ -d "$HOME/bin" ]        && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# nvm / node — prefer nvm-managed node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]            && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ]   && source "$NVM_DIR/bash_completion"
# fallback pinned node path (only used when nvm isn't active)
[ -d "$HOME/.nvm/versions/node/v18.12.1/bin" ] && \
    export PATH="$HOME/.nvm/versions/node/v18.12.1/bin:$PATH"

# golang
if $IS_MAC && command -v brew &>/dev/null; then
    export GOROOT="$(brew --prefix golang 2>/dev/null)"
fi

# rvm
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# cargo/rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ── COMPILER FLAGS (macOS openssl) ───────────────────────────────────────────
if $IS_MAC; then
    export LDFLAGS="-L/opt/homebrew/opt/openssl/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/openssl/include"
    export SSL_CERT_DIR=/etc/ssl/certs
fi

# ── HOMEBREW ─────────────────────────────────────────────────────────────────
export HOMEBREW_NO_AUTO_UPDATE=1

# ── PROMPT ───────────────────────────────────────────────────────────────────
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '!'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%F{green}%b%f %m'
zstyle ':vcs_info:git*+set-message:*' hooks git-status

+vi-git-status() {
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) != 'true' ]]; then
        return 1
    fi
    local staged=$(git diff --cached --numstat | wc -l | tr -d ' ')
    local unstaged=$(git diff --numstat | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    local res=""
    [ $staged -gt 0 ]   && res+="%F{green}+${staged}%f"
    [ $unstaged -gt 0 ] && res+="%F{yellow}~${unstaged}%f"
    [ $untracked -gt 0 ] && res+="%F{blue}?${untracked}%f"
    hook_com[misc]=$res
}

local exit_code_prompt='%(?..%B%F{red}%?%f%b )'
setopt prompt_subst
PROMPT="${exit_code_prompt}%* %F{blue}%B%~%b%f \${vcs_info_msg_0_} $ "

# ── KEY BINDINGS ─────────────────────────────────────────────────────────────
if $IS_MAC; then
    bindkey '^[[1;3C' forward-word
    bindkey '^[[1;3D' backward-word
    bindkey '^[^M'    autosuggest-accept
else
    bindkey '^ '   forward-word
    bindkey '^[^M' autosuggest-accept
fi

# ── CLIPBOARD HELPER ─────────────────────────────────────────────────────────
# Unified `copy` command: pbcopy on macOS, xclip on Linux
if $IS_MAC; then
    alias copy="pbcopy"
    alias paste="pbpaste"
else
    alias copy="xclip -selection clipboard"
    alias paste="xclip -selection clipboard -o"
    alias clear-clipboard="xclip -sel clipboard < /dev/null"
fi

# ── ALIASES ──────────────────────────────────────────────────────────────────
alias cp="cp -v"
alias mv="mv -v"
alias rm="rm -v"
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls — macOS uses BSD ls (no --color flag), Linux uses GNU ls
if $IS_MAC; then
    alias ls="ls -G"
    alias ll="ls -alGF"
    alias la="ls -AG"
else
    alias ls="ls --color=auto"
    alias ll="ls -alF"
    alias la="ls -A"
fi

alias sortips="sort -u -n -t . -k1,1 -k2,2 -k3,3 -k4,4"
alias dirtime="find . -type f -printf '%TY-%Tm-%Td %TH:%TM %P\n' | sort | tail -n 5"

# open / xdg-open
if $IS_MAC; then
    alias drag="open -R"
    alias ']'='open'
else
    alias ']'='xdg-open'
    alias drag="xdg-open"
fi

# git
alias gs="git status"

# tmux
alias tm="tmux -2"
alias tmkill="tmux kill-session"

# dotfiles manager (bare repo trick)
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# network / system (Linux only)
if $IS_LINUX; then
    alias flushdns="sudo /etc/init.d/nscd restart; sudo /etc/init.d/dns-clean start; sudo service network-manager restart"
    alias audio="pulseaudio -k && sudo alsa force-reload"
fi

# git workflow shortcut
function update_release {
    local CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "current git branch: $CURRENT_BRANCH"
    git stash
    git checkout master
    git pull origin master
    git checkout release
    git pull origin release
    git merge master
    git push origin release
    git checkout "$CURRENT_BRANCH"
    git stash pop
}
alias release=update_release

# kill port 80
kill80() {
    sudo lsof -i :80 | grep 'apache2' | awk '{ print $2 }' | xargs sudo kill -9
    sudo lsof -i :80 | grep 'nginx'   | awk '{ print $2 }' | xargs sudo kill -9
}

# ── FUNCTIONS ─────────────────────────────────────────────────────────────────

# jd — fuzzy jump to a subdirectory
jd() {
    local target="${@:-${PWD}}"
    local dir
    dir=$(find "$target" -name "*" -type d 2>/dev/null \
        | sed 's@^\./@@' \
        | fzf -d / --nth -1 --reverse -0 --cycle --height 100%)
    [[ -n "$dir" ]] && cd "$dir"
}

# gjd — fuzzy jump to a git worktree
gjd() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not inside a git repository." >&2
        return 1
    fi
    local dir
    dir=$(git worktree list | sed 's@^\./@@' \
        | fzf -d / --nth -1 --reverse -0 --cycle --height 100% \
        | cut -d' ' -f1)
    [[ -n "$dir" ]] && cd "$dir"
}

# ── DIRECTORY BOOKMARK STACK ─────────────────────────────────────────────────
# push  — bookmark current directory (or given path) to return to later
# pop   — jump back to the most recently pushed directory
#
# Uses a plain file stack (~/.dir_stack) so it survives across sessions and
# works identically on macOS and Linux.
#
# Usage:
#   push          # bookmark $PWD
#   push /some/path  # bookmark a specific path (cd there first)
#   pop           # jump to the last pushed directory
#   push --list   # show the current stack

_DIR_STACK_FILE="${TMPDIR:-/tmp}/.zsh_dir_stack_$$"

push() {
    if [[ "$1" == "--list" ]]; then
        if [[ ! -s "$_DIR_STACK_FILE" ]]; then
            echo "(stack is empty)"
        else
            local i=0
            while IFS= read -r line; do
                echo "  $i: $line"
                (( i++ ))
            done < "$_DIR_STACK_FILE"
        fi
        return 0
    fi

    local target="${1:-${PWD}}"
    # Resolve to absolute path
    target="$(cd "$target" 2>/dev/null && pwd)" || {
        echo "push: no such directory: $1" >&2
        return 1
    }

    # Prepend to stack file (most-recent first)
    local tmp=$(mktemp)
    { echo "$target"; [[ -f "$_DIR_STACK_FILE" ]] && cat "$_DIR_STACK_FILE"; } > "$tmp"
    mv "$tmp" "$_DIR_STACK_FILE"

    echo "📌 pushed: $target"
}

pop() {
    if [[ ! -s "$_DIR_STACK_FILE" ]]; then
        echo "pop: directory stack is empty" >&2
        return 1
    fi

    # Read top of stack
    local dest
    dest=$(head -n 1 "$_DIR_STACK_FILE")

    # Remove top entry from stack
    local tmp=$(mktemp)
    tail -n +2 "$_DIR_STACK_FILE" > "$tmp"
    mv "$tmp" "$_DIR_STACK_FILE"

    cd "$dest" && echo "📂 returned to: $dest"
}

# path — copy realpath of file/dir to clipboard
path() {
    local target="${1:-${PWD}}"
    realpath "$target" | copy
}

# wlog — fuzzy open a log file
wlog() {
    local dir
    dir=$(find "${LOG_DIR:-.}" -name "*" -type f 2>/dev/null \
        | sed 's@^\./@@' \
        | fzf -d / --nth -1 --reverse -0 --cycle --height 100%)
    [[ -n "$dir" ]] && ${EDITOR:-vim} "$dir"
}

# ── EXTRA / LOCAL OVERRIDES ──────────────────────────────────────────────────
# Source ~/.extra for machine-local config that shouldn't be committed
[ -r "$HOME/.extra" ] && [ -f "$HOME/.extra" ] && source "$HOME/.extra"
