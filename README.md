# dotfiles

Personal configuration for an **Arch Linux** workstation, organized for
[GNU Stow](https://www.gnu.org/software/stow/).

- **WM:** Niri
- **Shell desktop / theme:** Noctalia
- **Key remapping:** keyd
- **Shells:** Fish + Bash
- **Terminals:** Alacritty, Kitty, Ghostty, Terminator, Warp

## Layout

Each top-level directory is a **Stow package** whose internal tree mirrors
`$HOME`. Stowing a package symlinks its contents into the right place.

```
dotfiles/
├── fish/.config/fish/            # Fish shell (config.fish, conf.d, functions, completions)
├── bash/                         # .bashrc .bash_profile .profile .bash_logout  -> $HOME
├── git/.config/git/              # git config + global ignore
├── niri/.config/niri/            # Niri WM (config.kdl, init.sh, dms/)
├── keyd/                         # keyd configs (special-cased — see install.sh)
├── alacritty/.config/alacritty/
├── kitty/.config/kitty/
├── ghostty/.config/ghostty/
├── terminator/.config/terminator/
├── warp/.config/warp-terminal/   # settings.toml only (prefs blob excluded)
├── noctalia/.config/noctalia/    # Noctalia settings + colorschemes
├── starship/.config/starship.toml
├── waybar/  btop/  fastfetch/  cava/   # extra .config packages
├── user_scripts/user_scripts/     # personal shell scripts -> ~/user_scripts/
├── install.sh                    # symlink everything via stow
├── bootstrap.sh                  # fresh-machine setup (packages + stow)
├── pkglist.txt                   # pacman -Qqe   (explicitly installed)
├── aurlist.txt                   # pacman -Qqem  (AUR / foreign)
└── .gitignore                    # secret + machine-state exclusions
```

## Install

On a machine that already has your configs, **back up or move** any existing
files first — `stow` will refuse to overwrite real files (it errors rather than
clobbering).

```sh
# install GNU Stow if needed
sudo pacman -S --needed stow

# symlink everything into $HOME
./install.sh

# or only some packages
./install.sh fish git niri

# dry-run a single package to preview what would be linked
stow --no --verbose --target="$HOME" fish
```

`install.sh --adopt` pulls existing files **into** the repo instead of erroring
(review `git diff` afterward). `install.sh --no-keyd` skips the sudo `/etc/keyd`
step.

### keyd (special case)

keyd's real config lives in `/etc/keyd/` (root-owned), which is outside `$HOME`
and can't be a normal stow target. `install.sh` therefore:
- copies `keyd/basic.conf` → `~/.config/keyd/basic.conf`, and
- backs up then installs `keyd/default.conf` → `/etc/keyd/default.conf` (sudo),
  reloading keyd afterward.

## Fresh machine

```sh
git clone <this-repo> ~/dotfiles && cd ~/dotfiles
./bootstrap.sh        # installs stow, repo + AUR packages, then stows
```

## Secrets

This repo is scrubbed of credentials:
- Hardcoded ClickHouse passwords in `config.fish` were **redacted**.
- `.gitignore` blocks `*.pem`, `*.key`, SSH keys, `.env`, `fish_variables`,
  and other secret/state patterns.

> Note: `config.fish` and `user_scripts/es.sh` still contain **internal SSH
> host aliases** (hostnames / IPs for work infrastructure) by choice. Keep this
> repository **private**, or run a further scrub before making it public.

## Not included (intentionally)

- `fish_variables` — machine-local universal variables.
- `*.bak` / `*.backup` files.
- `warp-terminal/user_preferences.json` — large machine-specific state.
- `~/.config/mako` — was a dangling symlink into an old Omarchy theme dir.
- empty `swaync` config.
