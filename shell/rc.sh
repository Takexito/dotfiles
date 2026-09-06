# Подключается из ~/.bashrc — см. install.sh.
# Рассчитано на контейнеры: ничего не завязано на хостовые пути и mise-шимы.

alias ll='ls -alF'
alias la='ls -A'
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# Когда открыто несколько контейнеров, легко забыть, в каком ты сидишь.
# Поэтому в приглашении — имя проекта и текущая ветка.
__dev_ctx() {
    local name="${PROJECT_NAME:-${DEVCONTAINER_NAME:-}}"
    [ -n "$name" ] && printf '(%s) ' "$name"
}
__dev_branch() {
    local b
    b=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return
    printf '[%s] ' "$b"
}
if [ -n "${BASH_VERSION:-}" ] && [[ $- == *i* ]]; then
    PS1='\[\033[36m\]$(__dev_ctx)\[\033[33m\]$(__dev_branch)\[\033[32m\]\w\[\033[0m\]\$ '
fi

# Поиск по истории стрелками вверх/вниз с учётом уже набранного префикса.
if [[ $- == *i* ]]; then
    bind '"\e[A": history-search-backward' 2>/dev/null || true
    bind '"\e[B": history-search-forward' 2>/dev/null || true
fi

export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend 2>/dev/null || true
