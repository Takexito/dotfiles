#!/usr/bin/env bash
# Разворачивает дотфайлы. Вызывается devcontainer CLI через
# --dotfiles-install-command, но безопасен и при запуске руками на хосте.
#
# Идемпотентен и ничего не затирает: подключается к существующим ~/.gitconfig
# и ~/.bashrc через include/source, а не заменяет их.
set -euo pipefail

DOTFILES=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)

link_git_config() {
    # include.path вместо симлинка: если ~/.gitconfig уже есть (например,
    # инструмент дописал в него credential.helper), он останется на месте.
    if ! git config --global --get-all include.path 2>/dev/null | grep -qx "$DOTFILES/git/config"; then
        git config --global --add include.path "$DOTFILES/git/config"
        echo ">> подключён $DOTFILES/git/config"
    fi
    git config --global core.excludesFile "$DOTFILES/git/ignore"
    git config --global core.hooksPath "$DOTFILES/git/hooks"
    chmod +x "$DOTFILES/git/hooks/"* 2>/dev/null || true
}

link_shell() {
    local rc="$HOME/.bashrc" marker="# >>> dotfiles >>>"
    [ -f "$rc" ] || touch "$rc"
    if ! grep -qF "$marker" "$rc"; then
        {
            echo ""
            echo "$marker"
            echo "[ -f \"$DOTFILES/shell/rc.sh\" ] && . \"$DOTFILES/shell/rc.sh\""
            echo "# <<< dotfiles <<<"
        } >> "$rc"
        echo ">> подключён $DOTFILES/shell/rc.sh"
    fi
}

link_tmux() {
    local rc="$HOME/.tmux.conf" marker="# >>> dotfiles >>>"
    [ -f "$rc" ] || touch "$rc"
    if ! grep -qF "$marker" "$rc"; then
        {
            echo "$marker"
            echo "source-file $DOTFILES/tmux/tmux.conf"
            echo "# <<< dotfiles <<<"
        } >> "$rc"
        echo ">> подключён $DOTFILES/tmux/tmux.conf"
    fi
}

setup_gh_credentials() {
    # Без этого git не умеет ходить в приватные репозитории: gh становится
    # credential helper. Авторизация (gh auth login) — отдельный разовый шаг.
    command -v gh >/dev/null 2>&1 || return 0
    if ! git config --global --get-regexp 'credential\..*github\.com\.helper' >/dev/null 2>&1; then
        gh auth setup-git 2>/dev/null && echo ">> gh подключён как credential helper для git"
    fi
}

link_git_config
link_shell
link_tmux
setup_gh_credentials

if command -v gitleaks >/dev/null 2>&1; then
    echo ">> gitleaks: $(gitleaks version 2>&1 | head -1)"
else
    echo ">> gitleaks не найден — pre-commit пропустит проверку секретов" >&2
fi

echo ">> дотфайлы установлены: $DOTFILES"
