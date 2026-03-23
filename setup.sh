#!/bin/bash
set -e

echo "==> Installing dependencies..."
sudo apt update
sudo apt install -y \
  git \
  curl \
  tmux \
  ripgrep \
  gcc \
  make \
  unzip \
  wget \
  xclip \
  wl-clipboard

echo "==> Installing Neovim (latest stable)..."
if nvim --version 2>/dev/null | grep -q "^NVIM v0\.1[0-9]"; then
  echo "    Neovim 0.10+ already installed, skipping"
else
  curl -fLo /tmp/nvim-linux-x86_64.tar.gz \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm /tmp/nvim-linux-x86_64.tar.gz
fi

echo "==> Installing tree-sitter CLI..."
if command -v tree-sitter &>/dev/null; then
  echo "    tree-sitter already installed, skipping"
else
  curl -fL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
    | gunzip > /tmp/tree-sitter
  chmod +x /tmp/tree-sitter
  sudo mv /tmp/tree-sitter /usr/local/bin/tree-sitter
fi

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

echo "==> Installing JetBrains Mono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if fc-list | grep -qi "JetBrainsMono"; then
  echo "    JetBrains Mono Nerd Font already installed, skipping"
else
  curl -fLo /tmp/JetBrainsMono.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono" '*.ttf'
  fc-cache -fv "$FONT_DIR"
  rm /tmp/JetBrainsMono.zip
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

echo "==> Installing Claude Code..."
if command -v claude &>/dev/null; then
  echo "    Claude Code already installed, skipping"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Setting up Claude memory..."
MEMORY_KEY=$(echo "$DOTFILES_DIR" | sed 's|/|-|g')
MEMORY_TARGET="$HOME/.claude/projects/$MEMORY_KEY/memory"
mkdir -p "$(dirname "$MEMORY_TARGET")"
if [ -L "$MEMORY_TARGET" ]; then
  echo "    Claude memory symlink already exists, skipping"
elif [ -d "$MEMORY_TARGET" ]; then
  echo "    WARNING: $MEMORY_TARGET exists as a real directory — back it up and replace with a symlink to $DOTFILES_DIR/claude-memory"
else
  ln -sf "$DOTFILES_DIR/claude-memory" "$MEMORY_TARGET"
  echo "    Claude memory symlinked"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Run 'gh auth login' to authenticate with GitHub (choose SSH)"
echo "  2. Configure git identity:"
echo "       git config --global user.email 'you@example.com'"
echo "       git config --global user.name 'Your Name'"
echo "  3. Open neovim — lazy.nvim will auto-install plugins on first launch"
echo "  4. Run :Lazy sync inside neovim to ensure everything is up to date"
echo "  5. Mason will auto-install LSP servers on first use"
echo "  6. Run ./update.sh any time to keep everything current"
