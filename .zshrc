export ZSH="$HOME/.oh-my-zsh"

zstyle ':omz:update' mode disabled  # disable automatic updates

DISABLE_UNTRACKED_FILES_DIRTY="true"

autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '!'
zstyle ':vcs_info:*' stagedstr '+'

zstyle ':vcs_info:git:*' formats '%F{green}%b%f %m'
zstyle ':vcs_info:git*+set-message:*' hooks git-status

+vi-git-status(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
        return 1
    fi

    # macOS Fix: use 'tr -d " "' to strip whitespace from 'wc -l' output
    local staged=$(git diff --cached --numstat | wc -l | tr -d ' ')
    local unstaged=$(git diff --numstat | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

    local res=""

    [ $staged -gt 0 ] && res+="%F{green}+${staged}%f"
    [ $unstaged -gt 0 ] && res+="%F{yellow}~${unstaged}%f"
    [ $untracked -gt 0 ] && res+="%F{blue}?${untracked}%f"

    # Inject into %m (misc)
    hook_com[misc]=$res
}

# Exit Code Logic (Native Zsh)
# %(?..code) checks if exit code is not 0. If so, prints it in red.
local exit_code_prompt='%(?..%B%F{red}%?%f%b )'
setopt prompt_subst
PROMPT="${exit_code_prompt}%* %F{blue}%B%~%b%f \${vcs_info_msg_0_} $ "

plugins=(
    git
    history
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

if [[ $(uname -s) == "Darwin" ]]; then
	bindkey '^[[1;3C' forward-word
	bindkey '^[[1;3D' backward-word
	bindkey '^[^M' autosuggest-accept
else
	bindkey '^ ' forward-word
	bindkey '^[^M' autosuggest-accept
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.nvm/versions/node/v18.12.1/bin:$PATH"
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
