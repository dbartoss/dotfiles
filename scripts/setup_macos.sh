#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup script is for macOS only."
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "Warning: this script is tuned for Apple Silicon (arm64). Continuing..."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() {
  printf "\n[%s] %s\n" "$(date +%H:%M:%S)" "$*"
}

ensure_xcode_cli_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
  else
    log "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    log "If a GUI prompt appeared, finish installation and re-run this script."
  fi
}

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log "Updating Homebrew..."
  brew update
}

install_formulae() {
  local formulae=(
    git
    gh
    curl
    wget
    jq
    fd
    fzf
    tmux
    neovim
    oh-my-posh
    zoxide
    zsh
    direnv
    pre-commit
    mise
  )

  log "Installing Homebrew formulae..."
  for pkg in "${formulae[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      echo "  - $pkg already installed"
    else
      brew install "$pkg"
    fi
  done
}

install_casks() {
  local casks=(
    alacritty
    visual-studio-code
    karabiner-elements
#    docker
   #  1password
    rectangle
 #   firefox
    google-chrome
 #   zen-browser
    postman
  )

  log "Installing Homebrew casks..."
  for app in "${casks[@]}"; do
    if brew list --cask "$app" >/dev/null 2>&1; then
      echo "  - $app already installed"
    else
      brew install --cask "$app"
    fi
  done
}

configure_zsh() {
  local homebrew_zsh=""

  if [[ -x /opt/homebrew/bin/zsh ]]; then
    homebrew_zsh="/opt/homebrew/bin/zsh"
  elif [[ -x /usr/local/bin/zsh ]]; then
    homebrew_zsh="/usr/local/bin/zsh"
  fi

  if [[ -n "$homebrew_zsh" ]]; then
    if ! grep -q "$homebrew_zsh" /etc/shells; then
      log "Adding Homebrew zsh to /etc/shells (requires sudo)..."
      echo "$homebrew_zsh" | sudo tee -a /etc/shells >/dev/null
    fi

    if [[ "$SHELL" != "$homebrew_zsh" ]]; then
      log "Changing default shell to $homebrew_zsh..."
      chsh -s "$homebrew_zsh"
    fi
  fi
}

configure_git_basics() {
  log "Applying sane default git settings..."

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global fetch.prune true
  git config --global core.editor "code --wait"

  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config --global user.name "$GIT_USER_NAME"
  fi

  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.email "$GIT_USER_EMAIL"
  fi
}

configure_mise_runtimes() {
  log "Configuring runtimes with mise (Bun + Go + Rust)..."
  mise use -g bun@latest
  mise use -g go@latest
  mise use -g rust@stable
}

configure_zshrc() {
  local zshrc="$HOME/.zshrc"
  local source_file="$REPO_ROOT/config/zsh/.zshrc"

  if [[ ! -f "$source_file" ]]; then
    log "Zsh config source not found at $source_file; skipping."
    return
  fi

  # Backup existing .zshrc if it exists
  if [[ -e "$zshrc" || -L "$zshrc" ]]; then
    mv "$zshrc" "$zshrc.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing .zshrc"
  fi

  # Create symlink to repo-managed config
  ln -sfn "$source_file" "$zshrc"
  log "Linked Zsh config -> $zshrc"
}

install_js_tooling_with_bun() {
  log "Installing global JavaScript tooling with Bun..."

  if command -v bun >/dev/null 2>&1; then
    bun add -g @anthropic-ai/claude-code || true
    bun add -g @openai/codex || true
  else
    log "bun not found. Skipping JS CLI installs. Re-run after Bun install."
  fi
}


apply_alacritty_personalization() {
  local source_file="$REPO_ROOT/config/alacritty/alacritty.toml"

  if [[ ! -f "$source_file" ]]; then
    log "Alacritty config source not found at $source_file; skipping personalization."
    return
  fi

  local target_home
  if [[ -n "${SUDO_USER:-}" ]]; then
    target_home=$(eval echo "~${SUDO_USER}")
    log "Script running under sudo; targeting home of ${SUDO_USER}: ${target_home}"
  else
    target_home="$HOME"
  fi

  local target_dir="$target_home/.config/alacritty"
  local target_file="$target_dir/alacritty.toml"

  mkdir -p "$target_dir"

  # Use absolute path for symlink (simpler and more reliable)
  local link_target="$source_file"

  # If an existing target exists and isn't already the desired link, back it up.
  if [[ -e "$target_file" || -L "$target_file" ]]; then
    local already_linked=false
    if [[ -L "$target_file" ]]; then
      # Check if symlink points to the source file
      local existing_target
      existing_target=$(readlink "$target_file" 2>/dev/null || echo "")
      if [[ "$existing_target" == "$link_target" ]]; then
        already_linked=true
      fi
    fi

    if [[ "$already_linked" == true ]]; then
      log "Alacritty config already linked to repo source; nothing to do"
      return
    fi

    mv "$target_file" "$target_file.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing Alacritty config to $target_file.bak.*"
  fi

  # Create the symlink
  ln -sfn "$link_target" "$target_file"
  log "Linked Alacritty config -> $target_file"
}

apply_omp_personalization() {
  local source_file="$REPO_ROOT/config/omp/config.toml"

  if [[ ! -f "$source_file" ]]; then
    log "Oh My Posh config source not found at $source_file; skipping."
    return
  fi

  local target_home
  if [[ -n "${SUDO_USER:-}" ]]; then
    target_home=$(eval echo "~${SUDO_USER}")
  else
    target_home="$HOME"
  fi

  local target_dir="$target_home/.config/omp"
  local target_file="$target_dir/config.toml"

  mkdir -p "$target_dir"

  if [[ -e "$target_file" || -L "$target_file" ]]; then
    mv "$target_file" "$target_file.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing Oh My Posh config"
  fi

  ln -sfn "$source_file" "$target_file"
  log "Linked Oh My Posh config -> $target_file"
}

apply_tmux_personalization() {
  local source_file="$REPO_ROOT/config/tmux/tmux.conf"

  if [[ ! -f "$source_file" ]]; then
    log "Tmux config source not found at $source_file; skipping."
    return
  fi

  local target_home
  if [[ -n "${SUDO_USER:-}" ]]; then
    target_home=$(eval echo "~${SUDO_USER}")
  else
    target_home="$HOME"
  fi

  local target_dir="$target_home/.config/tmux"
  local target_file="$target_dir/tmux.conf"

  mkdir -p "$target_dir"

  if [[ -e "$target_file" || -L "$target_file" ]]; then
    mv "$target_file" "$target_file.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing Tmux config"
  fi

  ln -sfn "$source_file" "$target_file"
  log "Linked Tmux config -> $target_file"
}

apply_karabiner_personalization() {
  local source_file="$REPO_ROOT/config/karabiner/karabiner.json"

  if [[ ! -f "$source_file" ]]; then
    log "Karabiner config source not found at $source_file; skipping."
    return
  fi

  local target_home
  if [[ -n "${SUDO_USER:-}" ]]; then
    target_home=$(eval echo "~${SUDO_USER}")
  else
    target_home="$HOME"
  fi

  local target_dir="$target_home/.config/karabiner"
  local target_file="$target_dir/karabiner.json"

  mkdir -p "$target_dir"

  if [[ -e "$target_file" || -L "$target_file" ]]; then
    mv "$target_file" "$target_file.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing Karabiner config"
  fi

  ln -sfn "$source_file" "$target_file"
  log "Linked Karabiner config -> $target_file"
}

install_orbstack_from_dmg() {
  log "Installing OrbStack from DMG..."

  local arch="arm64"
  if [[ "$(uname -m)" == "x86_64" ]]; then
    arch="x86_64"
  fi

  local dmg_url="https://orbstack.dev/download/stable/latest/$arch"
  local temp_dmg="/tmp/orbstack.dmg"
  local mount_point="/tmp/orbstack_mount"

  # Check if already installed
  if [[ -d "/Applications/OrbStack.app" ]]; then
    log "OrbStack already installed"
    return
  fi

  # Download DMG
  log "Downloading OrbStack DMG for $arch..."
  if ! curl -L --fail -o "$temp_dmg" "$dmg_url"; then
    log "Failed to download OrbStack DMG from $dmg_url"
    return 1
  fi

  # Mount the DMG
  log "Mounting OrbStack DMG..."
  mkdir -p "$mount_point"
  if ! hdiutil attach "$temp_dmg" -mountpoint "$mount_point"; then
    log "Failed to mount OrbStack DMG"
    rm -f "$temp_dmg"
    return 1
  fi

  # Copy app to Applications
  log "Installing OrbStack to /Applications..."
  cp -R "$mount_point"/*.app /Applications/ 2>/dev/null || true

  # Unmount and clean up
  log "Cleaning up..."
  hdiutil detach "$mount_point" 2>/dev/null || true
  rm -f "$temp_dmg"
  rm -rf "$mount_point"

  log "OrbStack installation complete"
}

install_optional_local_agent_tools() {
  if [[ "${INSTALL_LOCAL_AGENT_TOOLS:-0}" != "1" ]]; then
    log "Skipping optional local agent stack install (set INSTALL_LOCAL_AGENT_TOOLS=1 to enable)."
    return
  fi

  log "Installing optional local agent/automation tools..."

  # Install Ollama pinned to a known-good version (default 0.12.4).
  # Allow overriding via the OLLAMA_VERSION env var if the user needs a different pinned release.
  local ollama_version="${OLLAMA_VERSION:-0.12.4}"

  if command -v ollama >/dev/null 2>&1; then
    echo "  - ollama already installed"
  else
    log "Installing Ollama ${ollama_version} via official installer..."
    # The official installer supports OLLAMA_VERSION env var; use it to pin the version.
    export OLLAMA_VERSION="$ollama_version" 
    curl -fsSL https://ollama.com/install.sh | sh || {
      log "Ollama installer failed for ${ollama_version}. Please install manually or adjust OLLAMA_VERSION."
    }
  fi

  local casks=(
    lm-studio
  )

  for app in "${casks[@]}"; do
    if brew list --cask "$app" >/dev/null 2>&1; then
      echo "  - $app already installed"
    else
      brew install --cask "$app"
    fi
  done
}

post_install_tips() {
  cat <<'EOT'

Setup complete.

Next steps:
1) Restart terminal to ensure shell/runtime path changes are loaded.
2) Open Docker Desktop once and complete any permission prompts.
3) Authenticate CLIs and GitHub:
   - claude login
   - codex login
   - gh auth login
4) Optional git identity (if not set via env vars):
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
5) Verify:
   brew --version
   git --version
   zsh --version
   code --version
   docker --version
   bun --version
   go version
   rustc --version
   cargo --version

Optional compatibility mode for legacy projects:
   mise use -g node@lts

Optional local agent stack:
   INSTALL_LOCAL_AGENT_TOOLS=1 ./scripts/setup_macos.sh
   brew services start ollama
   ollama pull qwen2.5-coder:7b

EOT
}


# Cleanup function for temporary files
cleanup_temp_files() {
  rm -f /tmp/orbstack.dmg
  rm -rf /tmp/orbstack_mount
}

# Set trap to cleanup on exit (both success and error)
trap cleanup_temp_files EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup script is for macOS only."
  exit 1
fi


main() {
  ensure_xcode_cli_tools
  ensure_homebrew
  install_formulae
  install_casks
  configure_zsh
  configure_git_basics
  configure_mise_runtimes
  configure_zshrc
  apply_omp_personalization
  apply_tmux_personalization
  apply_karabiner_personalization
  install_js_tooling_with_bun
  apply_alacritty_personalization
  install_orbstack_from_dmg
  install_optional_local_agent_tools
  post_install_tips
}

main "$@"
