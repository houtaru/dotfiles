# Dotfiles

> [!WARNING]  
> **Highly Personalized Configuration**  
> These dotfiles are strictly tailored to my personal workflow and preferences. My Neovim, Zsh, and Tmux configurations contain aggressive customizations, bespoke keybindings, and architectural decisions (like remote container LSP integrations). If you are looking to fork or clone this, please review the configurations carefully as they are not intended to be a generic starter kit!

This repository contains my personal configurations for a high-performance terminal workflow on macOS and Linux (Debian & Alpine).

## Quick Start

1. Clone this repository anywhere on your machine (e.g. `~/.dotfiles`):
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the automated setup script:
   ```bash
   ./scripts/setup.sh --setup-nvim
   ```

## Repository Structure

- `nvim/`: Complete Neovim 0.12+ configuration written in Lua, leveraging native LSP and tree-sitter.
- `bin/`: Custom standalone shell scripts and executables.
- `scripts/`: Bootstrapping and installation scripts.
- `.tmux.conf`: Unified, minimalist tmux configuration.
- `.alacritty.toml`: Hardware-accelerated terminal configuration.
- `.zshrc`: High-performance Zsh configuration.

## Key Features

The included `setup.sh` is designed to be completely turnkey and idempotent (safe to re-run). Upon running, it will automatically:
- **Cross-OS Support**: Safely checks `uname` and OS release files to bootstrap package managers (Homebrew on Mac, APT on Debian/Ubuntu, APK on Alpine).
- **Core Dependencies**: Installs `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fzf`, and `alacritty`.
- **System Clipboard**: Installs native clipboard integrations for Linux (`xclip` and `wl-clipboard`).
- **LSP Tooling**: Installs `nodejs`, `clangd`/`llvm`, and `bash-language-server` so language features work immediately.
- **Nerd Fonts**: Automatically fetches, unzips, and caches `JetBrainsMono` Nerd Font to render terminal icons properly.
- **Smart Symlinking**: Safely creates symbolic links from this repository directly to your `$HOME` directory so everything stays dynamically synced:
   - `~/.zshrc`
   - `~/.tmux.conf`
   - `~/.alacritty.toml`
   - `~/.gitconfig`
   - `~/.editorconfig`
   - `~/.config/nvim/init.lua`
   - `bin/*` → `~/bin/` (Making your custom shell scripts globally executable!)
- **Neovim Bootstrapping**: By passing `--setup-nvim`, it spins up a headless Neovim instance to automatically clone `lazy.nvim`, download all your plugins, and natively compile Treesitter parsers (`:TSUpdateSync`).

## Architecture Highlights
- **Neovim (v0.12.2+)**: Highly optimized, async-first setup featuring native LSP container file caching without relying on external plugins. See `nvim/init.lua` for the custom "fast-fail" remote file jump integration.
- **Terminal & Multiplexing**: Alacritty and Tmux configured for hardware-accelerated speed, clean aesthetics.

