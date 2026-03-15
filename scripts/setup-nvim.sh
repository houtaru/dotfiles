#!/usr/bin/env bash
# nvim-setup.sh — set up the full nvim environment on macOS
#
# What this installs:
#   - Homebrew (if missing)
#   - nvim, git, ripgrep, fzf, node, bash-language-server
#   - nerd-font (JetBrainsMono) for icons in lualine / fzf-lua
#   - Your init.lua config
#   - lazy.nvim plugins (headless)
#   - coc extensions (coc-clangd, coc-json, coc-sh)
#   - treesitter parsers (c, cpp, java, go, rust, python, lua, bash, …)
#
# Safe to re-run: all steps are idempotent.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOU/REPO/main/nvim-setup.sh | bash
#   or:
#   ./nvim-setup.sh              # install everything
#   ./nvim-setup.sh --no-font    # skip nerd font installation
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'
step()  { echo -e "\n${B}▶ $*${N}"; }
ok()    { echo -e "  ${G}✓${N} $*"; }
warn()  { echo -e "  ${Y}⚠${N}  $*"; }
die()   { echo -e "\n${R}✗ $*${N}" >&2; exit 1; }

# ── Flags ─────────────────────────────────────────────────────────────────────
INSTALL_FONT=true
for arg in "$@"; do [[ "$arg" == "--no-font" ]] && INSTALL_FONT=false; done

# ── macOS guard ───────────────────────────────────────────────────────────────
[[ "$(uname)" == "Darwin" ]] || die "This script is for macOS only."

# ── Locate this script's directory (for init.lua sibling path) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_SRC=""
# If init.lua is sitting next to this script (repo layout: nvim/init.lua)
[[ -f "$SCRIPT_DIR/nvim/init.lua"  ]] && NVIM_CONFIG_SRC="$SCRIPT_DIR/nvim/init.lua"
[[ -f "$SCRIPT_DIR/init.lua"       ]] && NVIM_CONFIG_SRC="$SCRIPT_DIR/init.lua"

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  Neovim macOS Setup                         │"
echo "└─────────────────────────────────────────────┘"

# ═════════════════════════════════════════════════════════════════════════════
# 1. HOMEBREW
# ═════════════════════════════════════════════════════════════════════════════
step "Homebrew"
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found — installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this session (Apple Silicon path)
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
ok "brew $(brew --version | head -1)"

# ═════════════════════════════════════════════════════════════════════════════
# 2. CORE TOOLS
# ═════════════════════════════════════════════════════════════════════════════
step "Core tools (nvim, git, ripgrep, fzf, node)"

brew_install() {
  local pkg="$1"; local cmd="${2:-$1}"
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd already installed ($(command -v "$cmd"))"
  else
    echo "  installing $pkg..."
    brew install "$pkg"
    ok "$cmd installed"
  fi
}

brew_install neovim  nvim
brew_install git
brew_install ripgrep rg
brew_install fzf
brew_install node

# Verify nvim version (need 0.11+)
NVIM_VER=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+')
NVIM_MAJOR=$(echo "$NVIM_VER" | cut -d. -f1)
NVIM_MINOR=$(echo "$NVIM_VER" | cut -d. -f2)
if [[ "$NVIM_MAJOR" -lt 1 && "$NVIM_MINOR" -lt 11 ]]; then
  warn "nvim $NVIM_VER detected — version 0.11+ recommended. Run: brew upgrade neovim"
else
  ok "nvim $NVIM_VER"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 3. LANGUAGE SERVERS
# ═════════════════════════════════════════════════════════════════════════════
step "Language servers"

# bash-language-server (needed by coc-sh / languageserver.bash in coc-settings)
if command -v bash-language-server &>/dev/null; then
  ok "bash-language-server already installed"
else
  echo "  installing bash-language-server..."
  npm install -g bash-language-server
  ok "bash-language-server installed"
fi

# clangd — used by coc-clangd for C/C++
# macOS ships clang via Xcode Command Line Tools; clangd is inside it
if command -v clangd &>/dev/null; then
  ok "clangd already available ($(clangd --version 2>&1 | head -1))"
else
  warn "clangd not found — installing llvm via Homebrew (provides clangd)..."
  brew install llvm
  # llvm is keg-only; add to PATH hint
  LLVM_BIN="$(brew --prefix llvm)/bin"
  ok "clangd installed at $LLVM_BIN/clangd"
  warn "Add to your shell profile: export PATH=\"$LLVM_BIN:\$PATH\""
fi

# ═════════════════════════════════════════════════════════════════════════════
# 4. NERD FONT  (for lualine icons and fzf-lua file icons)
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_FONT" == "true" ]]; then
  step "Nerd Font (JetBrainsMono)"
  if ls ~/Library/Fonts/JetBrainsMonoNerd* &>/dev/null 2>&1 || \
     ls /Library/Fonts/JetBrainsMonoNerd*  &>/dev/null 2>&1; then
    ok "JetBrainsMono Nerd Font already installed"
  else
    echo "  installing JetBrainsMono Nerd Font via Homebrew Cask..."
    brew install --cask font-jetbrains-mono-nerd-font
    ok "JetBrainsMono Nerd Font installed"
    warn "Set your terminal font to 'JetBrainsMono Nerd Font' for icons to render"
  fi
else
  step "Nerd Font  (skipped via --no-font)"
fi

# ═════════════════════════════════════════════════════════════════════════════
# 5. NVIM CONFIG
# ═════════════════════════════════════════════════════════════════════════════
step "Neovim config (~/.config/nvim/init.lua)"

CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$CONFIG_DIR"

if [[ -n "$NVIM_CONFIG_SRC" ]]; then
  # init.lua found next to this script — copy it
  if [[ -f "$CONFIG_DIR/init.lua" ]]; then
    if diff -q "$NVIM_CONFIG_SRC" "$CONFIG_DIR/init.lua" &>/dev/null; then
      ok "init.lua already up to date"
    else
      cp "$CONFIG_DIR/init.lua" "$CONFIG_DIR/init.lua.bak.$(date +%Y%m%d_%H%M%S)"
      cp "$NVIM_CONFIG_SRC" "$CONFIG_DIR/init.lua"
      ok "init.lua updated (old version backed up)"
    fi
  else
    cp "$NVIM_CONFIG_SRC" "$CONFIG_DIR/init.lua"
    ok "init.lua installed"
  fi

  # Copy templates dir if present
  TEMPLATES_SRC="$(dirname "$NVIM_CONFIG_SRC")/templates"
  if [[ -d "$TEMPLATES_SRC" ]]; then
    cp -r "$TEMPLATES_SRC" "$CONFIG_DIR/templates"
    ok "templates/ copied"
  fi

else
  # Script run standalone (e.g. curl | bash) — download from repo
  warn "init.lua not found next to this script."
  warn "Place your init.lua at ~/.config/nvim/init.lua before continuing,"
  warn "or re-run this script from the repo root."
  warn ""
  warn "Skipping headless plugin install (requires init.lua to be in place)."
  SKIP_HEADLESS=true
fi

# ═════════════════════════════════════════════════════════════════════════════
# 6. LAZY.NVIM BOOTSTRAP + PLUGINS
# ═════════════════════════════════════════════════════════════════════════════
SKIP_HEADLESS="${SKIP_HEADLESS:-false}"

if [[ "$SKIP_HEADLESS" == "false" ]]; then

  step "lazy.nvim — bootstrap + sync plugins"
  # lazy auto-bootstraps itself on first run (init.lua clones it if missing)
  nvim --headless \
    +"lua require('lazy').sync({wait=true})" \
    +qall 2>&1 | grep -v "^$" | sed 's/^/  /' || true
  ok "plugins synced"

  # ── coc extensions ────────────────────────────────────────────────────────
  step "coc.nvim extensions (coc-clangd, coc-json, coc-sh)"
  nvim --headless \
    +"CocInstall -sync coc-clangd coc-json coc-sh" \
    +qall 2>&1 | grep -v "^$" | sed 's/^/  /' || true
  ok "coc extensions installed"

  # ── treesitter parsers ────────────────────────────────────────────────────
  step "Treesitter parsers"
  nvim --headless \
    +"TSInstall! c cpp java go rust python lua bash json yaml toml cmake" \
    +qall 2>&1 | grep -v "^$" | sed 's/^/  /' || true
  ok "parsers installed"

fi

# ═════════════════════════════════════════════════════════════════════════════
# 7. TMUX (optional but recommended for C-h/j/k/l navigation)
# ═════════════════════════════════════════════════════════════════════════════
step "tmux (optional)"
if command -v tmux &>/dev/null; then
  ok "tmux $(tmux -V | cut -d' ' -f2) already installed"
else
  echo "  installing tmux..."
  brew install tmux
  ok "tmux installed"
fi

# ── tmux true-colour config hint ──────────────────────────────────────────────
TMUX_CONF="$HOME/.tmux.conf"
TMUX_RGB_LINE="set-option -a terminal-features 'screen-256color:RGB'"
TMUX_FOCUS_LINE="set-option -g focus-events on"
if [[ -f "$TMUX_CONF" ]] && grep -q "terminal-features" "$TMUX_CONF"; then
  ok "tmux true-colour already configured"
else
  warn "Add the following to ~/.tmux.conf for true-colour (required for tokyonight theme):"
  warn "  $TMUX_RGB_LINE"
  warn "  $TMUX_FOCUS_LINE"
  # Offer to add it automatically
  if [[ -t 0 ]]; then   # only prompt when running interactively
    echo ""
    read -rp "  Add these lines to ~/.tmux.conf now? [y/N] " REPLY
    if [[ "${REPLY,,}" == "y" ]]; then
      {
        echo ""
        echo "# nvim true-colour support"
        echo "$TMUX_RGB_LINE"
        echo "$TMUX_FOCUS_LINE"
      } >> "$TMUX_CONF"
      ok "tmux.conf updated"
    fi
  fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  Setup complete                             │"
echo "├─────────────────────────────────────────────┤"
printf "│  %-12s %s\n" "nvim:"    "$(nvim --version | head -1)"
printf "│  %-12s %s\n" "node:"    "$(node --version)"
printf "│  %-12s %s\n" "rg:"      "$(rg --version | head -1)"
printf "│  %-12s %s\n" "fzf:"     "$(fzf --version)"
echo "├─────────────────────────────────────────────┤"
echo "│  Run: nvim                                  │"
echo "└─────────────────────────────────────────────┘"
echo ""
