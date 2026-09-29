#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(dirname "$here")"

mkdir -p ~/.local/bin ~/.local/state ~/config-backup
ln -sfn "$here" ~/rices

for f in rice brave brave-layout; do
  install -Dm755 "$repo/bin/$f" ~/.local/bin/$f
done

# back up any real config folders that the rices are about to replace with links
for rice in "$here"/*/; do
  for d in "$rice"*/; do
    n=$(basename "$d"); t=~/.config/$n
    if [ -e "$t" ] && [ ! -L "$t" ]; then
      mv "$t" ~/config-backup/"$n.$(date +%s)"
    fi
  done
done

grep -q 'log out of Hyprland' ~/.bashrc || cat "$repo/bin/logout.bashrc" >> ~/.bashrc

echo "Installed. Run: rice light   or   rice pip"
