#!/bin/bash
# Bootstrap this machine: dev tools + the Fallout rice.
#
#   ./setup.sh                 everything
#   ./setup.sh --rice-only     just the rice (configs, fonts, icons, SDDM, GRUB)
#   ./setup.sh --no-system     skip the sudo parts (SDDM + GRUB)
#   ./setup.sh --profile 4k    force a display profile (4k | 1440p | 1080p)
#
# Safe to re-run. Existing files that would be replaced are moved to
# ~/.dotfiles-backup/<timestamp>/ first.
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
RICE_ONLY=0
NO_SYSTEM=0
PROFILE_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --rice-only) RICE_ONLY=1 ;;
    --no-system) NO_SYSTEM=1 ;;
    --profile)   PROFILE_ARGS+=("$2"); shift ;;
    -h|--help)   sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if ! command -v pacman &>/dev/null; then
  echo "This script targets Arch Linux (pacman not found)."
  exit 1
fi

HAS_NVIDIA=0
if lspci 2>/dev/null | grep -qi 'vga.*nvidia\|3d.*nvidia'; then HAS_NVIDIA=1; fi

# =============================================================================
# Dev environment
# =============================================================================
if [ "$RICE_ONLY" = 0 ]; then
  echo "==> Updating package database..."
  sudo pacman -Syu --noconfirm

  echo "==> Installing dev dependencies..."
  sudo pacman -S --needed --noconfirm \
    git curl tmux ripgrep gcc make unzip wget xclip wl-clipboard \
    neovim tree-sitter github-cli noto-fonts-emoji ttf-jetbrains-mono-nerd \
    fontconfig base-devel stow

  echo "==> Setting up Neovim config..."
  if [ -d ~/.config/nvim ]; then
    echo "    ~/.config/nvim already exists, skipping clone"
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
  elif command -v yay &>/dev/null; then
    sudo pacman -S --needed --noconfirm \
      qt6-quicktimeline qt6-virtualkeyboard qt6-lottie libatomic_ops qt6-3d qt6-scxml
    yay -S --noconfirm expressvpn
    sudo systemctl enable --now expressvpn
  else
    echo "    yay not installed, skipping (AUR package)"
  fi
fi

# =============================================================================
# Rice: packages
# =============================================================================
echo "==> Installing rice packages..."
RICE_PKGS=(
  hyprland hyprlock hyprpaper hyprlauncher hyprshot uwsm
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent
  waybar swaync kitty thunar tumbler fastfetch btop
  sddm grub os-prober efibootmgr
  adw-gtk-theme papirus-icon-theme gtk-update-icon-cache
  ttf-jetbrains-mono-nerd noto-fonts-emoji fontconfig
  pipewire-audio pipewire-pulse wireplumber pavucontrol network-manager-applet
  wl-clipboard grim slurp brightnessctl playerctl
  python stow xz
)
sudo pacman -S --needed --noconfirm "${RICE_PKGS[@]}"
if [ "$HAS_NVIDIA" = 1 ]; then
  echo "    NVIDIA GPU detected: installing driver packages"
  sudo pacman -S --needed --noconfirm nvidia-open-dkms nvidia-utils lib32-nvidia-utils \
    libva-nvidia-driver nvidia-settings linux-headers || \
    echo "    (NVIDIA packages failed; is multilib enabled? Continuing.)"
fi

# =============================================================================
# Rice: symlink configs with stow
# =============================================================================
STOW_PKGS=(bash cursor fonts gtk hypr kitty tmux waybar)
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Move anything in the way to BACKUP_DIR, and undo old "folded" directory
# symlinks (e.g. ~/.config/hypr -> ~/dotfiles/...), since we stow with
# --no-folding so per-machine files can live next to the symlinks.
prepare_target() {
  local pkg=$1 rel target parent
  while IFS= read -r rel; do
    target="$HOME/$rel"
    parent=$(dirname "$target")
    while [ "$parent" != "$HOME" ] && [ "$parent" != "/" ]; do
      if [ -L "$parent" ] && [[ "$(readlink -f "$parent")" == "$DOTFILES_DIR"/* ]]; then
        echo "    unfolding $parent"
        rm "$parent"
      fi
      parent=$(dirname "$parent")
    done
    if [ -L "$target" ] && [[ "$(readlink -f "$target")" == "$DOTFILES_DIR"/* ]]; then
      continue  # already ours
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      echo "    backed up ~/$rel"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . \( -type f -o -type l \) | sed 's|^\./||')
}

echo "==> Linking configs..."
for pkg in "${STOW_PKGS[@]}"; do
  prepare_target "$pkg"
  stow --no-folding -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg"
  echo "    $pkg"
done
[ -d "$BACKUP_DIR" ] && echo "    old files saved in $BACKUP_DIR"

mkdir -p ~/.local/bin
ln -sf "$DOTFILES_DIR/scripts/rice-profile" ~/.local/bin/rice-profile

# =============================================================================
# Rice: icons, cursor, fonts
# =============================================================================
echo "==> Installing icon and cursor themes..."
mkdir -p ~/.local/share/icons
for tarball in "$DOTFILES_DIR"/system/icons/*.tar.xz; do
  name=$(basename "$tarball" .tar.xz)
  rm -rf ~/.local/share/icons/"$name"
  tar -xJf "$tarball" -C ~/.local/share/icons
  [ -f ~/.local/share/icons/"$name"/index.theme ] && \
    gtk-update-icon-cache -q -f ~/.local/share/icons/"$name" 2>/dev/null || true
  echo "    $name"
done

echo "==> Refreshing font cache..."
fc-cache -f >/dev/null

# =============================================================================
# Rice: per-machine sizing (fonts, bar, monitor scale)
# =============================================================================
"$DOTFILES_DIR/scripts/rice-profile" "${PROFILE_ARGS[@]}"
# shellcheck source=/dev/null
. ~/.config/rice/profile

# =============================================================================
# Rice: SDDM login screen and GRUB (needs sudo)
# =============================================================================
if [ "$NO_SYSTEM" = 0 ]; then
  echo "==> Installing SDDM theme..."
  sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
  sudo rm -rf /usr/share/sddm/themes/fallout-terminal
  sudo cp -r "$DOTFILES_DIR/system/sddm/themes/fallout-terminal" /usr/share/sddm/themes/
  sudo cp "$DOTFILES_DIR/system/sddm/conf.d/theme.conf" /etc/sddm.conf.d/theme.conf
  if [ -f "$DOTFILES_DIR/system/sddm/Xsetup" ]; then
    sudo cp "$DOTFILES_DIR/system/sddm/conf.d/x11.conf" /etc/sddm.conf.d/x11.conf
    [ -f /etc/sddm/Xsetup ] && sudo cp /etc/sddm/Xsetup /etc/sddm/Xsetup.bak
    sudo install -Dm755 "$DOTFILES_DIR/system/sddm/Xsetup" /etc/sddm/Xsetup
  fi
  current_dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)
  if [ -z "$current_dm" ] || [ "$current_dm" = "display-manager.service" ]; then
    sudo systemctl enable sddm
    echo "    enabled sddm"
  elif [ "$current_dm" != "sddm.service" ]; then
    echo "    NOTE: $current_dm is your login manager. To switch to SDDM:"
    echo "          sudo systemctl disable ${current_dm%.service} && sudo systemctl enable sddm"
  fi

  echo "==> Installing console fonts..."
  sudo install -Dm644 -t /usr/share/kbd/consolefonts "$DOTFILES_DIR"/system/consolefonts/*.psfu.gz

  echo "==> Installing GRUB theme ($RICE_GRUB_THEME)..."
  if [ -f /etc/default/grub ] && [ -d /boot/grub ]; then
    sudo mkdir -p /boot/grub/themes
    for t in "$DOTFILES_DIR"/system/grub/themes/*; do
      sudo rm -rf "/boot/grub/themes/$(basename "$t")"
      sudo cp -r "$t" /boot/grub/themes/
    done

    sudo cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)"
    set_grub() {  # set_grub KEY VALUE  (replaces an existing or commented line, else appends)
      if grep -qE "^#?\s*$1=" /etc/default/grub; then
        sudo sed -i -E "s|^#?\s*$1=.*|$1=$2|" /etc/default/grub
      else
        echo "$1=$2" | sudo tee -a /etc/default/grub >/dev/null
      fi
    }
    # native resolution of the largest connected display, so the theme isn't scaled
    native=$(for d in /sys/class/drm/card*-*; do
               [ "$(cat "$d/status" 2>/dev/null)" = connected ] && head -n1 "$d/modes"
             done | sort -t x -k2 -n | tail -1)
    set_grub GRUB_THEME "\"/boot/grub/themes/$RICE_GRUB_THEME/theme.txt\""
    set_grub GRUB_GFXMODE "${native:-auto},auto"
    set_grub GRUB_TIMEOUT_STYLE "menu"
    set_grub GRUB_DISABLE_OS_PROBER "false"

    # Fallout green palette for the text console, from the first line of boot
    VT="vt.default_red=7,224,157,184,47,79,88,103,47,255,184,217,79,126,126,200 vt.default_grn=19,163,255,217,138,184,196,217,138,200,255,217,184,232,232,255 vt.default_blu=11,58,174,103,69,102,108,122,69,87,196,103,102,147,147,210"
    if ! grep -q 'vt.default_red' /etc/default/grub; then
      sudo sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"|\1 $VT\"|" /etc/default/grub
    fi
    if [ "$HAS_NVIDIA" = 1 ] && ! grep -q 'nvidia-drm.modeset' /etc/default/grub; then
      sudo sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"|\1 nvidia-drm.modeset=1\"|" /etc/default/grub
    fi

    sudo grub-mkconfig -o /boot/grub/grub.cfg
  else
    echo "    GRUB not found (systemd-boot?), skipping. Themes are in system/grub/themes/."
  fi
fi

echo ""
echo "Done! Profile: $RICE_PROFILE (font ${RICE_FONT_PT}pt)."
echo "  - Log out and back in (or reboot) to start Hyprland from SDDM."
echo "  - Monitors/GPU: ~/.config/hypr/machine.lua (per-machine, not in git)."
echo "    On the desktop, run once: rice-profile --machine desktop"
echo "  - Different display? Run: rice-profile [4k|1440p|1080p]"
if [ "$RICE_ONLY" = 0 ]; then
  echo "  - Run 'gh auth login' (choose SSH), then set your git name/email."
  echo "  - Open Neovim; lazy.nvim installs plugins on first launch."
fi
