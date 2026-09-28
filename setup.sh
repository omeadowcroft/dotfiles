#!/bin/bash
set -e

echo "==> Updating package database..."
sudo pacman -Syu --noconfirm

echo "==> Installing dependencies..."
sudo pacman -S --needed --noconfirm \
  git \
  curl \
  tmux \
  ripgrep \
  gcc \
  make \
  unzip \
  wget \
  xclip \
  wl-clipboard \
  neovim \
  tree-sitter \
  github-cli \
  noto-fonts-emoji \
  ttf-jetbrains-mono-nerd \
  fontconfig \
  base-devel

echo "==> Checking Neovim version..."
if nvim --version 2>/dev/null | grep -q "^NVIM v0\.1[0-9]"; then
  echo "    Neovim 0.10+ already installed"
else
  echo "    Installed Neovim may be too old. Updating..."
  sudo pacman -S --needed --noconfirm neovim
fi

echo "==> Checking tree-sitter CLI..."
if command -v tree-sitter &>/dev/null; then
  echo "    tree-sitter already installed"
else
  echo "    tree-sitter missing; installing..."
  sudo pacman -S --needed --noconfirm tree-sitter
fi

echo "==> Checking gh CLI..."
if command -v gh &>/dev/null; then
  echo "    gh already installed"
else
  echo "    gh missing; installing..."
  sudo pacman -S --needed --noconfirm github-cli
fi

echo "==> Checking JetBrains Mono Nerd Font..."
if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
  echo "    JetBrains Mono Nerd Font already installed"
else
  echo "    Installing JetBrains Mono Nerd Font..."
  sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd
  fc-cache -fv
fi

echo "==> Setting up tmux config..."
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ln -sf "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

echo "==> Setting up Neovim config..."
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
if [ -d ~/.claude-memory/.git ]; then
  echo "    Claude memory repo already exists, skipping"
else
  git clone git@github.com:omeadowcroft/claude-memory.git ~/.claude-memory
fi

MEMORY_KEY=$(echo "$DOTFILES_DIR" | sed 's|/|-|g')
MEMORY_TARGET="$HOME/.claude/projects/$MEMORY_KEY/memory"
mkdir -p "$(dirname "$MEMORY_TARGET")"

if [ -L "$MEMORY_TARGET" ]; then
  echo "    Claude memory symlink already exists, skipping"
elif [ -d "$MEMORY_TARGET" ]; then
  echo "    WARNING: $MEMORY_TARGET exists as a real directory — back it up and replace with a symlink to ~/.claude-memory"
else
  ln -sf "$HOME/.claude-memory" "$MEMORY_TARGET"
  echo "    Claude memory symlinked"
fi

echo "==> Installing ExpressVPN..."
if command -v expressvpn &>/dev/null; then
  echo "    ExpressVPN already installed, skipping"
else
  echo "    Installing AUR dependencies..."
  sudo pacman -S --needed --noconfirm \
    qt6-quicktimeline qt6-virtualkeyboard qt6-lottie libatomic_ops qt6-3d qt6-scxml
  echo "    Installing expressvpn from AUR..."
  yay -S --noconfirm expressvpn
  echo "    Enabling expressvpn service..."
  sudo systemctl enable --now expressvpn
fi


echo ""
echo "Done! Next steps:"
echo "  1. Run 'gh auth login' to authenticate with GitHub (choose SSH)"
echo "  2. Configure git identity:"
echo "       git config --global user.email 'you@example.com'"
echo "       git config --global user.name 'Your Name'"
echo "  3. Open Neovim — lazy.nvim will auto-install plugins on first launch"
echo "  4. Run :Lazy sync inside Neovim to ensure everything is up to date"
echo "  5. Mason will auto-install LSP servers on first use"
echo "  6. Re-run this script any time to keep everything current"
