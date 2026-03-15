#!/usr/bin/env bash
# scripts/build.sh
#
# Usage:
#   ./scripts/build.sh [docker] [NVIM_VERSION] [NODE_VERSION]
#
#   (no args)                   build directly on this machine (CI / Linux with deps)
#   docker                      build inside Docker (local dev, clean environment)
#   docker v0.11.0 22.14.0      pin versions when using Docker
#   SKIP_CACHE=1 ./build.sh docker   force a clean Docker image rebuild
#
# Output: dist/nvim-appimage-<commit>-x86_64.AppImage
#         dist/build-info.txt
#
# The workflow calls:  ./scripts/build.sh v0.11.0 22.14.0
# Locally you call:    ./scripts/build.sh docker
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Parse subcommand ──────────────────────────────────────────────────────────
MODE="direct"
if [[ "${1:-}" == "docker" ]]; then
  MODE="docker"
  shift
fi

NVIM_VERSION="${1:-latest}"
NODE_VERSION="${2:-22.14.0}"
OUTPUT_DIR="$REPO_ROOT/dist"

# ── Resolve 'latest' nvim version ────────────────────────────────────────────
if [[ "$NVIM_VERSION" == "latest" ]]; then
  echo "→ Resolving latest Neovim version..."
  NVIM_VERSION=$(curl -sfL \
    https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  echo "  → $NVIM_VERSION"
fi

# ── Metadata ─────────────────────────────────────────────────────────────────
COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u '+%Y-%m-%d %H:%M UTC')
AUTHOR=$(git -C "$REPO_ROOT" log -1 --format='%an <%ae>' 2>/dev/null || echo "unknown")

echo ""
echo "┌──────────────────────────────────────────────────┐"
printf "│  %-10s : %-37s│\n" "Mode"     "$MODE"
printf "│  %-10s : %-37s│\n" "Commit"   "$COMMIT"
printf "│  %-10s : %-37s│\n" "Date"     "$BUILD_DATE"
printf "│  %-10s : %-37s│\n" "Neovim"   "$NVIM_VERSION"
printf "│  %-10s : %-37s│\n" "Node.js"  "v$NODE_VERSION"
printf "│  %-10s : %-37s│\n" "Output"   "dist/"
echo "└──────────────────────────────────────────────────┘"
echo ""

mkdir -p "$OUTPUT_DIR"

# ═════════════════════════════════════════════════════════════════════════════
# DOCKER MODE — re-runs this same script inside a container
# The container mounts the repo read-only at /repo and output at /dist,
# then calls this script again without the 'docker' subcommand.
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$MODE" == "docker" ]]; then
  IMAGE="nvim-appimage-builder"
  BUILD_FLAGS=()
  [[ "${SKIP_CACHE:-0}" == "1" ]] && BUILD_FLAGS+=(--no-cache)

  # Write a minimal Dockerfile into a temp dir (no build context to copy)
  TMP=$(mktemp -d); trap "rm -rf $TMP" EXIT
  cat > "$TMP/Dockerfile" <<'EOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    curl wget file patchelf libfuse2 git build-essential ca-certificates xz-utils \
  && rm -rf /var/lib/apt/lists/*
EOF

  echo "→ Building Docker image ($IMAGE)..."
  docker build "${BUILD_FLAGS[@]}" -t "$IMAGE" "$TMP"

  echo "→ Running build inside container..."
  docker run --rm \
    -v "$REPO_ROOT:/repo:ro" \
    -v "$OUTPUT_DIR:/dist:rw" \
    "$IMAGE" \
    bash /repo/scripts/build.sh "$NVIM_VERSION" "$NODE_VERSION"
    # ↑ same script, no 'docker' subcommand → runs in direct mode inside the container

  exit 0
fi

# ═════════════════════════════════════════════════════════════════════════════
# DIRECT MODE — actual build steps (runs on CI runner or inside Docker)
# INPUT and OUTPUT are the repo root and output dir respectively.
# When running inside Docker they are the bind-mount paths /repo and /dist.
# When running directly on CI they are REPO_ROOT and OUTPUT_DIR.
# ═════════════════════════════════════════════════════════════════════════════
INPUT="$REPO_ROOT"
OUTPUT="$OUTPUT_DIR"
# Inside Docker, the repo is mounted at /repo and output at /dist
[[ -d "/repo" && -f "/repo/nvim/init.lua" ]] && INPUT="/repo"
[[ -d "/dist" ]]                              && OUTPUT="/dist"

WORK=$(mktemp -d); trap "cd / && rm -rf $WORK" EXIT
cd "$WORK"

# ── nvim ─────────────────────────────────────────────────────────────────────
echo "→ Downloading Neovim ${NVIM_VERSION}..."
wget -q \
  "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage" \
  -O nvim.appimage
chmod +x nvim.appimage
./nvim.appimage --appimage-extract
APPDIR="$WORK/squashfs-root"

# ── Node.js ───────────────────────────────────────────────────────────────────
echo "→ Bundling Node.js v${NODE_VERSION}..."
wget -q \
  "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
  -O node.tar.xz
mkdir -p "$APPDIR/usr/lib/node"
tar -xJf node.tar.xz --strip-components=1 -C "$APPDIR/usr/lib/node"
ln -sf ../lib/node/bin/node "$APPDIR/usr/bin/node"
ln -sf ../lib/node/bin/npm  "$APPDIR/usr/bin/npm"
ln -sf ../lib/node/bin/npx  "$APPDIR/usr/bin/npx"
echo "   $("$APPDIR/usr/bin/node" --version)"

# ── rg ────────────────────────────────────────────────────────────────────────
echo "→ Bundling rg..."
RG_URL=$(curl -sfL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest \
  | grep '"browser_download_url"' | grep 'x86_64-unknown-linux-musl.tar.gz' \
  | cut -d'"' -f4 | head -1)
wget -q "$RG_URL" -O rg.tar.gz
tar -xzf rg.tar.gz --wildcards '*/rg' --strip-components=1
install -m755 rg "$APPDIR/usr/bin/rg"

# ── fzf ───────────────────────────────────────────────────────────────────────
echo "→ Bundling fzf..."
FZF_URL=$(curl -sfL https://api.github.com/repos/junegunn/fzf/releases/latest \
  | grep '"browser_download_url"' | grep 'linux_amd64.tar.gz' \
  | cut -d'"' -f4 | head -1)
wget -q "$FZF_URL" -O fzf.tar.gz
tar -xzf fzf.tar.gz fzf
install -m755 fzf "$APPDIR/usr/bin/fzf"

# ── Config ────────────────────────────────────────────────────────────────────
echo "→ Embedding config..."
CFG_DST="$APPDIR/usr/share/nvim-appimage/config"
mkdir -p "$CFG_DST"
cp "$INPUT/nvim/init.lua" "$CFG_DST/init.lua"
[[ -d "$INPUT/nvim/templates" ]] && cp -r "$INPUT/nvim/templates" "$CFG_DST/templates" || true

# ── Headless plugin + parser install ─────────────────────────────────────────
echo "→ Pre-installing plugins + parsers (headless)..."
STAGE="$WORK/staging"
export HOME="$STAGE/home"
export XDG_CONFIG_HOME="$STAGE/config"
export XDG_DATA_HOME="$STAGE/data"
export XDG_STATE_HOME="$STAGE/state"
export XDG_CACHE_HOME="$STAGE/cache"
export COC_NODE_PATH="$APPDIR/usr/bin/node"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp "$INPUT/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"

NVIM="$APPDIR/AppRun"
"$NVIM" --headless +"lua require('lazy').sync({wait=true})" +qall 2>&1 || true
"$NVIM" --headless +"CocInstall -sync coc-clangd coc-json coc-sh" +qall 2>&1 || true
"$NVIM" --headless \
  +"TSInstall! c cpp java go rust python lua bash json yaml toml cmake" \
  +qall 2>&1 || true

mkdir -p "$APPDIR/usr/share/nvim-appimage/data"
cp -r "$XDG_DATA_HOME/nvim/." "$APPDIR/usr/share/nvim-appimage/data/" 2>/dev/null || true
cp -r "$HOME/.config/coc/."   "$APPDIR/usr/share/nvim-appimage/coc/"  2>/dev/null || true

# ── build-info.txt ────────────────────────────────────────────────────────────
cat > "$APPDIR/build-info.txt" <<EOF
Neovim AppImage — custom build
Commit  : ${COMMIT}
Built   : ${BUILD_DATE}
Author  : ${AUTHOR}
Neovim  : ${NVIM_VERSION}
Node.js : ${NODE_VERSION}
EOF

# ── AppRun ────────────────────────────────────────────────────────────────────
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
SELF="$(readlink -f "$0")"
HERE="$(dirname "$SELF")"
export APPDIR="${APPDIR:-$HERE}"
APP_CFG="$APPDIR/usr/share/nvim-appimage"
export XDG_CONFIG_HOME="$APP_CFG/config"
export XDG_DATA_HOME="$APP_CFG/data"
export XDG_STATE_HOME="${HOME}/.local/state/nvim-appimage"
export XDG_CACHE_HOME="${HOME}/.cache/nvim-appimage"
export COC_DATA_HOME="${HOME}/.config/nvim-appimage/coc"
if command -v node &>/dev/null; then
  export COC_NODE_PATH="$(command -v node)"
else
  export COC_NODE_PATH="$APPDIR/usr/bin/node"
fi
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$COC_DATA_HOME"
export PATH="$APPDIR/usr/bin:$PATH"
exec "$APPDIR/usr/bin/nvim" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# ── Repack ────────────────────────────────────────────────────────────────────
echo "→ Repacking AppImage..."
wget -q \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" \
  -O appimagetool
chmod +x appimagetool
OUTFILE="$OUTPUT/nvim-appimage-${COMMIT}-x86_64.AppImage"
ARCH=x86_64 ./appimagetool "$APPDIR" "$OUTFILE"
cp "$APPDIR/build-info.txt" "$OUTPUT/build-info.txt"

echo ""
echo "✓ Done: $(ls -lh "$OUTFILE" | awk '{print $5, $NF}')"
echo ""
cat "$OUTPUT/build-info.txt"
