#!/bin/bash
set -e

# Smart sync a git repo: pull if behind, push if ahead, warn if diverged
sync_repo() {
  local dir=$1
  local name=$2

  if [ ! -d "$dir/.git" ]; then
    echo "  $name: directory not found, skipping"
    return
  fi

  echo "==> Syncing $name..."
  git -C "$dir" fetch --quiet

  local local_ref remote_ref base
  local_ref=$(git -C "$dir" rev-parse HEAD)
  remote_ref=$(git -C "$dir" rev-parse "@{u}" 2>/dev/null || echo "")

  if [ -z "$remote_ref" ]; then
    echo "  $name: no upstream branch, skipping"
    return
  fi

  base=$(git -C "$dir" merge-base HEAD "@{u}")

  if [ "$local_ref" = "$remote_ref" ]; then
    echo "  $name: up to date"
  elif [ "$local_ref" = "$base" ]; then
    echo "  $name: pulling latest..."
    git -C "$dir" pull --quiet
    echo "  $name: done"
  elif [ "$remote_ref" = "$base" ]; then
    echo "  $name: local is ahead, pushing..."
    git -C "$dir" push --quiet
    echo "  $name: done"
  else
    echo "  $name: DIVERGED — resolve manually in $dir"
    echo "    Run: cd $dir && git status"
  fi
}

# Check for uncommitted changes in a repo before syncing
check_clean() {
  local dir=$1
  local name=$2

  if ! git -C "$dir" diff --quiet || ! git -C "$dir" diff --cached --quiet; then
    echo "  WARNING: $name has uncommitted changes — commit or stash before syncing"
    return 1
  fi
  return 0
}

echo ""
echo "==> Checking dotfiles..."
check_clean ~/dotfiles "dotfiles" && sync_repo ~/dotfiles "dotfiles"

echo ""
echo "==> Checking neovim config..."
check_clean ~/.config/nvim "nvim config" && sync_repo ~/.config/nvim "nvim config"

echo ""
echo "==> Checking Neovim version..."
INSTALLED=$(nvim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
LATEST=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | grep -oP '\d+\.\d+\.\d+')

if [ -z "$LATEST" ]; then
  echo "  Could not fetch latest Neovim version, skipping"
elif [ "$INSTALLED" = "$LATEST" ]; then
  echo "  Neovim: up to date ($INSTALLED)"
else
  # Compare versions: only upgrade if latest > installed
  NEWER=$(printf '%s\n%s\n' "$INSTALLED" "$LATEST" | sort -V | tail -1)
  if [ "$NEWER" = "$INSTALLED" ]; then
    echo "  Neovim: local ($INSTALLED) is newer than release ($LATEST), skipping"
  else
    echo "  Neovim: upgrading $INSTALLED → $LATEST..."
    curl -fLo /tmp/nvim-linux-x86_64.tar.gz \
      https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm /tmp/nvim-linux-x86_64.tar.gz
    echo "  Neovim: done"
  fi
fi

echo ""
echo "==> Checking tree-sitter CLI..."
if ! command -v tree-sitter &>/dev/null; then
  echo "  tree-sitter: not installed, installing..."
  curl -fL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /tmp/tree-sitter
  chmod +x /tmp/tree-sitter
  sudo mv /tmp/tree-sitter /usr/local/bin/tree-sitter
  echo "  tree-sitter: done"
else
  echo "  tree-sitter: installed"
fi

echo ""
echo "All done!"
echo "  - To update neovim plugins, run :Lazy update inside nvim"
echo "  - To reload tmux config, run: tmux source ~/.tmux.conf"
