# dotfiles

Arch + Hyprland, themed as a green-phosphor Fallout terminal: kitty, Pip-Boy
Waybar, Pip-Boy notifications (swaync), GTK, Fixedsys Excelsior everywhere, Papirus-Fallout icons, Fallout-Pixel
cursor, an SDDM terminal login and a GRUB theme. Plus tmux and dev tools.

## New machine

```bash
sudo pacman -S --needed git
git clone https://github.com/omeadowcroft/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

`./setup.sh --rice-only` skips the dev tools (Neovim config, Claude Code,
ExpressVPN). `--no-system` skips the sudo parts (SDDM, GRUB, console fonts).
Anything the script replaces is moved to `~/.dotfiles-backup/<timestamp>/`.

## Scaling (4K / 1440p / 1080p)

`scripts/rice-profile` (linked to `~/.local/bin`) detects the largest connected
display and writes per-machine files that are **not** in git:

| profile | monitor scale | font | Waybar height | GRUB theme | console font |
|---|---|---|---|---|---|
| 4k | 1.5 | 17pt (34 px) | 36 | fallout-4k | fallout-32x68 |
| 1440p | 1 | 12.75pt (17 px) | 27 | fallout-1080p | fallout-16x34 |
| 1080p | 1 | 12.75pt (17 px) | 27 | fallout-1080p | fallout-16x34 |

Fixedsys is only crisp at multiples of 17 physical pixels, which is where these
numbers come from; 4K and 1080p end up with the same text size relative to the
screen. The SDDM theme scales itself.

Generated files: `~/.config/hypr/{machine.lua,hyprpaper.conf,hyprtoolkit.conf,hyprlauncher.conf}`,
`~/.config/kitty/local.conf`, `~/.config/waybar/local.{jsonc,css}`, `~/.config/swaync/local.css`,
`~/.config/gtk-{3,4}.0/settings.ini`, `~/.config/rice/profile`.

```bash
rice-profile                    # re-detect
rice-profile 1080p              # force a profile
rice-profile --machine desktop  # use hypr/.config/hypr/machines/desktop.lua as machine.lua
rice-profile --force-monitors   # regenerate machine.lua from connected outputs
```

`machine.lua` holds monitor rules and NVIDIA env vars (added automatically when an
NVIDIA GPU is present), so the shared Hyprland config works on any GPU.

The wallpaper (the `wallpapers` package, linked into `~/Pictures/wallpapers/`) is a
scanline pattern, so each profile gets a pixel-exact version rather than a
resampled one: `fallout-wallpaper-4k.png` or `fallout-wallpaper-1080p.png`.

## Layout

- `bash cursor fonts gtk hypr kitty swaync tmux wallpapers waybar/`: stow packages (stowed with `--no-folding`)
- `scripts/rice-profile`: per-machine sizing
- `system/`: installed with sudo (SDDM theme and config, GRUB themes, console fonts) and icon tarballs
- `packages/`: full package lists from the desktop, for reference

## Notifications

swaync, started by Hyprland. `Super+N` opens the notification centre (history,
Clear, Do Not Disturb). Popups use the same bracketed panel style as Waybar;
critical ones are amber.

## tmux

- Prefix: `Ctrl+A`
- `Prefix + x`: kill pane
- `Prefix + [`: copy/scroll mode (`q` to exit)
