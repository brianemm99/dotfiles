# dotfile management

One Chezmoi source for machines and devcontainers

- Arch Desktop: Hyprland + Quickshell on a Framework 13, automated monitor dectection for docked or undocked
- devcontainers: same shell, editor and CLI tools, without the compositor.

Mise is used as the package manager

Devcontainer: [devsy](https://github.com/devsy-org/devsy)

## Whats Included

| | Tools | Config location |
| ---- | ---- | ---- |
| Shell | bash, starship prompt | dot_bashrc, dot_config/starship.toml |
| Editor | Neovim with LazyVim | dot_config/nvim |
| Multiplexer | tmux | dot_config/tmux/tmux.conf |
| CLI tools | mise: chezmoi, bat, fzf, lsd, neovim, node, starship | dot_config/mise/config.toml.tmpl |
| Compositor | Hyprland (lua) | dot_config/hypr/ |
| Widgets | Quickshell | dot_config/quickshell/hypr |
| Services | systemd | dot_config/systemd/user/ |
| Containers | Podman rootless (storage on separate LVM) | dot_config/containers/storage.conf |
| System | logind (laptop lid management), sudoers (charge limit toggle) | system/ |

## Install

```bash
git clone https://github.com/brianemm99/dotfiles ~/repos/dotfiles
cd ~/repos/dotfiles
./setup
```

`setup` installs mise only if missing, then runs `chezmoi init --apply` through mise.
The source directory stays where its cloned not the standard `~/.local/share/chezmoi`

Chezmoi is used as normal from the dotfiles directory

``` bash
# see changes that would be made by apply
chezmoi diff
```

```bash
#apply any changes made
chezmoi apply
```

```bash
# git pull, then chezomi apply
chezmoi update
```

### Devcontainers

Point devsy dotfiles at this repo. `setup` script bootstraps repo the same way in a container

## Desktop vs Container

Determined by `.chezmoi.toml.tmpl. If`/.dockerenv`,`/run/.containerenv` or `$REMOTE_CONTAINERS`is found, applies correct environment by setting`container = true`

| | Desktop | Container |
| ---- | ---- | ---- |
| bash, starship, nvim, tmux config | Yes | Yes |
| mise tools | Yes | Yes (not tmux) |
| Hyprland, Quickshell, systemd user instance | Yes | No |
| pacman/yay packages | Yes | No |
| system/ files and services | Yes | No |
| Podman `storage.conf` | Yes | No |
The desktop only sections are skipped if any other distribution than Arch

## Desktop

### Keybinds

`SUPER` = mainMod

| Binds | Action |
| ---- | --- |
| `SUPER + Return` | Terminal (Ghostty) |
| `SUPER + Q` | Close active window |
| `SUPER + B` | Browser (Brave) |
| `SUPER + D` | App Launcher |
| `SUPER + Escape` | Power Menu |
| `SUPER + V` | Toggle floating window |
| `SUPER + 1..0` | Change workspace |
| `SUPER + SHIFT + 1..0` | Move active window to another workspace |
| `SUPER + arrows` | Change active window |
| `SUPER + Left click` | Move active window |
| `SUPER + Right click` | Resize active window |
| `SUPER + Scroll` | Cycle workspaces |
| `SUPER + .` | Screenshot: fullscreen |
| `SUPER + ALT + .` | Screenshot: active window |
| `SUPER + SHIFT + .` | Screenshot: select a region with mouse |
| `SUPER + P` | Toggle display setting if available |
| `SUPER + SHIFT + P` | Automatically detect displays |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + SHIFT + S` | Move wondow to scratchpad |
| `SUPER + M` | Exit Hyprland |

Screenshots are saved to `~/photos/screenshots/` and copied to clipboard.
To change Keybinds:

```bash
nvim ~/repos/dotfiles/dot_config/hypr/hyprland.lua
```

```vim
/KEYBINDS
```

### Displays

`dot_config/hypr/monitors/` picks a layout based on lid state and connected outputs.
  Reads from the kernel rather than from Hyprland.

| Mode | Use |
| --- | --- |
| laptop only | No external disply plugged in |
| dual screen | External display plugged in + lid open |
| external only | External display plugged in + lid closed (or forced laptop off with `SUPER + P`) |

### Quickshell

Started with `quickshell.service` (`qs -c hyprland`).
Setup as part of `graphical-session.target`
The bar appears on each screen and includes:

- Powermenu
- CPU & RAM rings with more detailed menu on click
- workspaces
- calendar and clock, calendar drop down opens on click
- Media player shows and scrolls in bar with more features in drop down opened on click
- Quick settings: volume, wifi, bluetooth, display, notifications, settings menu, battery, system tray

### Manual steps

Tailscale needs interactive login.

```bash
sudo pacman -S tailscale
```

```bash
sudo systemctl enable --now tailscaled
sudo tailscale up
```

To make the tailscale toggle in settings menu in the bar:

```bash
sudo tailscale set --operator=$USER
```

- Wallpaper: set in `~/repos/dotfiles/dot_config/hypr/hyprpaper.conf.tmpl`
  - hyprpaper expects image in `~/photos/wallpapers/`
  - not in the repo BYO
- Font: Quickshell uses JetBrainsMono Nerd Font

### Secrets

`.gitignore` blocks keys, tokens, `.env` files, GPG, cloud credentials, and shell history.
Keep secrets out of this repo.
