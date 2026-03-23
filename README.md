# dotfiles

Personal dotfiles for tmux (and other tools).

## Setup

On a new machine, run:

```bash
sudo apt install git
git clone git@github.com:omeadowcroft/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

This will install all dependencies (tmux, neovim, gh, ripgrep, etc.), symlink the tmux config, and clone the neovim config.

## Manual tmux setup

If you just want the tmux config:

1. Install tmux:
   ```bash
   sudo apt install tmux
   ```

2. Clone this repo and symlink the config:
   ```bash
   git clone git@github.com:omeadowcroft/dotfiles.git ~/dotfiles
   ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
   ```

3. Reload tmux config:
   ```bash
   tmux source ~/.tmux.conf
   ```

## Key bindings

- Prefix: `Ctrl+A`
- `Prefix + x` — kill pane
- `Prefix + [` — enter copy/scroll mode (use arrow keys or `j/k` to scroll, `q` to exit)
