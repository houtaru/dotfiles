# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode disabled  # disable automatic updates

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
zstyle ':vcs_info:git:*' formats '%F{green}%b%f %u%c%m'
zstyle ':vcs_info:git*+set-message:*' hooks git-status

+vi-git-status(){
	if ! git rev-parse --is-inside-work-tree &>/dev/null; then
		return 0
	fi
	staged=$(git diff --cached --numstat | wc -l)
	unstaged=$(git diff --numstat | wc -l)
	untracked=$(git ls-files --others --exclude-standard | wc -l)
	[ $staged -gt 0 ] && hook_com[staged]+="%{$fg[green]%}+$staged%{$reset_color%}"
	[ $unstaged -gt 0 ] && hook_com[staged]+="%{$fg[yellow]%}~$unstaged%{$reset_color%}"
	[ $untracked -gt 0 ] && hook_com[staged]+="%{$fg[blue]%}?$untracked%{$reset_color%}"
}
exitcode() {
	[ ${code:=$?} -ne 0 -a $code -ne 130 ] && echo -e "%B%F{red}${code}%b "
}
setopt prompt_subst
PROMPT='$(exitcode)%* %F{blue}%B%~%b%f ${vcs_info_msg_0_} $ '

plugins=(
    git
    history
    zsh-autosuggestions
    zsh-syntax-highlighting
)

bindkey '^ ' forward-word
bindkey '^[^M' autosuggest-accept

source $ZSH/oh-my-zsh.sh
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.nvm/versions/node/v18.12.1/bin:$PATH"
