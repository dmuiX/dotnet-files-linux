ZSH_DISABLE_COMPFIX=true
zstyle ':omz:update' mode auto
export ZSH="$HOME/.oh-my-zsh"

plugins=(
    git
    zsh-autosuggestions
    dirhistory
    fasd
    history-substring-search
    zsh-syntax-highlighting
    zsh-completions
    z
    thor
    docker
    docker-compose
    kubectl
    aws
    ansible
    terraform
    python
    rails
    ruby
)

#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi

ZSH_THEME="powerlevel10k/powerlevel10k"

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTSIZE=1000000000000
SAVEHIST=$HISTSIZE

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.0

alias ll="ls -alsh"
alias llrt="ll -rt" #reversesort Time
alias llrs="ll -rS" #reversesort Size
alias cat="batcat -pp --theme=TwoDark"
alias history="history -E -10000000"
alias update="sudo nala upgrade && sudo nala autopurge && sudo nala autoremove && sudo nala clean"
alias cdmergefs="cd /srv/mergerfs/NAS"
alias ifconfig="ip -c -f inet a"
alias k="kubectl"
alias m4b-tool='docker run -it --rm -u $(id -u):$(id -g) -v "$(pwd)":/mnt sandreas/m4b-tool:latest'
#alias install='install -t bookworm-backports'
#alias kubectl="kubecolor"

alias cp='cp -i'   # Prompt before overwriting files with cp
alias mv='mv -i'   # Prompt before overwriting files with mv
alias rm='rm -i'   # Prompt before removing files with rm

autoload -Uz compinit; compinit -u

zstyle ':completion:*' menu select
fpath+=~/.zfunc
PATH=/opt/docker-credential-pass:$PATH
