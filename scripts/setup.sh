#!/usr/bin/env bash
# =============================================================================
# setup.sh — Dotfiles bootstrap
# Usage:  ./setup.sh [--setup-nvim]
# =============================================================================
set -euo pipefail

# ─── Flags ───────────────────────────────────────────────────────────────────
SETUP_NVIM=false
for arg in "$@"; do
    [[ "$arg" == "--setup-nvim" ]] && SETUP_NVIM=true
done

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ─── Helpers ─────────────────────────────────────────────────────────────────

# Print a coloured section header
info()  { printf '\n\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m   ✓ %s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m   ! %s\033[0m\n' "$*"; }
die()   { printf '\033[0;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Resolve a privilege-escalation command (doas > sudo > none)
find_sudo() {
    if command -v doas &>/dev/null; then echo "doas"
    elif command -v sudo &>/dev/null; then echo "sudo"
    else echo ""
    fi
}

# confirm_download URL PURPOSE
#   Shows the URL and why it is needed, then prompts the user to continue.
#   Exits non-zero (fast-fail) if the user declines.
confirm_download() {
    local url="$1"
    local purpose="$2"

    printf '\n\033[1;33m[Download Needed]\033[0m\n'
    printf '  Purpose : %s\n' "$purpose"
    printf '  URL     : %s\n' "$url"
    printf 'Proceed? [Y/n] '

    local reply
    read -r reply
    case "${reply:-Y}" in
        [Yy]* | "") return 0 ;;
        *)           die "Aborted by user." ;;
    esac
}

# ─── OS Detection ─────────────────────────────────────────────────────────────

detect_distro() {
    local os
    os="$(uname -s)"

    case "$os" in
        Darwin) echo "macos" ;;
        Linux)
            if   [[ -f /etc/alpine-release ]];  then echo "alpine"
            elif [[ -f /etc/debian_version ]];  then echo "debian"
            else echo "linux_unknown"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

DISTRO="$(detect_distro)"
[[ "$DISTRO" == "unknown" ]]        && die "Unsupported OS: $(uname -s)"
[[ "$DISTRO" == "linux_unknown" ]]  && die "Unsupported Linux distribution. Please install dependencies manually."

# ─── Per-distro package install ───────────────────────────────────────────────

install_packages_alpine() {
    local SUDO; SUDO="$(find_sudo)"
    info "Detected Alpine Linux — installing packages"
    $SUDO apk update
    $SUDO apk add git zsh tmux neovim ripgrep fzf alacritty curl \
        build-base xclip wl-clipboard nodejs npm clang clang-extra-tools \
        unzip fontconfig
}

install_packages_debian() {
    local SUDO; SUDO="$(find_sudo)"
    info "Detected Debian/Ubuntu — installing packages"
    $SUDO apt-get update
    $SUDO apt-get install -y git zsh tmux neovim ripgrep fzf alacritty curl \
        build-essential xclip wl-clipboard nodejs npm clangd unzip fontconfig
}

install_packages_macos() {
    info "Detected macOS — checking Homebrew"

    if ! command -v brew &>/dev/null; then
        local brew_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
        confirm_download "$brew_url" "Install Homebrew (macOS package manager)"
        /bin/bash -c "$(curl -fsSL "$brew_url")"
        # Make brew available in the current shell immediately
        [[ -d /opt/homebrew/bin ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    info "Installing formulae"
    brew update
    # llvm provides clangd
    brew install git zsh tmux neovim ripgrep fzf node llvm unzip

    info "Installing casks"
    brew list --cask font-jetbrains-mono-nerd-font &>/dev/null \
        || brew install --cask font-jetbrains-mono-nerd-font

    brew list --cask alacritty &>/dev/null \
        || brew install --cask alacritty
}

install_nerd_font_linux() {
    local FONT_DIR="$HOME/.local/share/fonts"

    ls "$FONT_DIR"/JetBrainsMonoNerd* &>/dev/null \
        && { ok "JetBrainsMono Nerd Font already installed."; return; }

    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    confirm_download "$font_url" "JetBrainsMono Nerd Font (terminal / Neovim icons)"

    info "Installing JetBrainsMono Nerd Font"
    mkdir -p "$FONT_DIR"
    curl -fLo "/tmp/JetBrainsMono.zip" "$font_url"
    unzip -q -o "/tmp/JetBrainsMono.zip" -d "$FONT_DIR"
    rm -f "/tmp/JetBrainsMono.zip"
    command -v fc-cache &>/dev/null && fc-cache -f "$FONT_DIR"
    ok "Font installed."
}

# ─── Main ─────────────────────────────────────────────────────────────────────

info "Starting dotfiles setup (distro: $DISTRO)"

case "$DISTRO" in
    macos)
        install_packages_macos
        ;;
    alpine)
        install_packages_alpine
        install_nerd_font_linux
        ;;
    debian)
        install_packages_debian
        install_nerd_font_linux
        ;;
esac

# ─── bash-language-server (npm global) ───────────────────────────────────────

if command -v npm &>/dev/null; then
    if command -v bash-language-server &>/dev/null; then
        ok "bash-language-server already installed."
    else
        info "Installing bash-language-server"
        local_sudo="$(find_sudo)"
        ${local_sudo:+$local_sudo} npm install -g bash-language-server \
            || warn "Failed to install bash-language-server — install manually."
    fi
fi

# ─── Symlinks ────────────────────────────────────────────────────────────────

info "Setting up symlinks"
ln -sf "$DOTFILES_DIR/.zshrc"        "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.tmux.conf"    "$HOME/.tmux.conf"
ln -sf "$DOTFILES_DIR/.gitconfig"    "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/.editorconfig" "$HOME/.editorconfig"
ln -sf "$DOTFILES_DIR/.alacritty.toml" "$HOME/.alacritty.toml"

mkdir -p "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# Symlink the entire bin directory
if [[ -L "$HOME/bin" ]] && [[ "$(readlink "$HOME/bin")" == "$DOTFILES_DIR/bin" ]]; then
    ok "$HOME/bin is already correctly symlinked."
elif [[ -e "$HOME/bin" ]] || [[ -L "$HOME/bin" ]]; then
    warn "$HOME/bin already exists and is not the correct symlink! Skipping."
else
    ln -sfn "$DOTFILES_DIR/bin" "$HOME/bin"
    ok "Symlink $DOTFILES_DIR/bin -> $HOME/bin done."
fi

# ─── Neovim headless bootstrap ───────────────────────────────────────────────

if [[ "$SETUP_NVIM" == true ]]; then
    info "Bootstrapping Neovim plugins (headless)"
    command -v nvim &>/dev/null || die "nvim not found — install it first."

    echo "  Syncing lazy.nvim plugins..."
    nvim --headless "+Lazy! sync" +qa || true

    echo "  Updating Treesitter parsers..."
    nvim --headless "+TSUpdateSync" +qa || true

    ok "Neovim bootstrap complete."
fi

# ─── Default shell ────────────────────────────────────────────────────────────

ZSH_PATH="$(command -v zsh || true)"
if [[ -n "$ZSH_PATH" && "$SHELL" != "$ZSH_PATH" ]]; then
    info "Changing default shell to zsh"
    command -v chsh &>/dev/null \
        && chsh -s "$ZSH_PATH" \
        || warn "chsh not found — change your shell manually: chsh -s $ZSH_PATH"
fi

info "Setup complete! Please restart your terminal."
