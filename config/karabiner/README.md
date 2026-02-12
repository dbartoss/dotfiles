# Karabiner configuration (repo-managed)

This directory is intended to be symlinked to `~/.config/karabiner` so your Karabiner-Elements configuration is managed from this repo.

Steps

1) Back up any existing Karabiner config and create the symlink:

```bash
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
if [ -e "$HOME/.config/karabiner" ]; then
  echo "Backing up existing ~/.config/karabiner -> ~/.config/karabiner.backup.$TIMESTAMP"
  mv "$HOME/.config/karabiner" "$HOME/.config/karabiner.backup.$TIMESTAMP"
fi
mkdir -p "$HOME/.config"
ln -sfn "$(pwd)/config/karabiner" "$HOME/.config/karabiner"
echo "Symlink created: ~/.config/karabiner -> $(pwd)/config/karabiner
```