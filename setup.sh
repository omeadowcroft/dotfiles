#!/bin/bash
set -e

echo "==> Installing dependencies..."
sudo apt update
sudo apt install -y \
  git \
  curl \
  tmux \
  neovim \
  ripgrep \
  gcc \
  make \
  unzip \
  wget

echo "==> Installing gh CLI..."
if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
else
  echo "    gh already installed, skipping"
fi

echo "==> Setting up tmux config..."
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

echo "==> Setting up neovim config..."
if [ -d ~/.config/nvim ]; then
  echo "    ~/.config/nvim already exists, skipping clone"
  echo "    If you want to reset it: rm -rf ~/.config/nvim and re-run"
else
  mkdir -p ~/.config
  git clone git@github.com:omeadowcroft/nvim-config.git ~/.config/nvim
fi

echo ""
echo "Done! Next steps:"
echo "  1. Run 'gh auth login' to authenticate with GitHub (choose SSH)"
echo "  2. Open neovim — lazy.nvim will auto-install plugins on first launch"
echo "  3. Run :Lazy sync inside neovim to ensure everything is up to date"
echo "  4. Mason will auto-install LSP servers on first use"
