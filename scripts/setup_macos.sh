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
    ripgrep
    fd
    fzf
    tmux
    neovim
    starship
    zsh
    direnv
    pre-commit
    watchman
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
    docker
    1password
    rectangle
    firefox
    google-chrome
    zen-browser
    postman
    orbstack
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

ensure_bun_path() {
  local zshrc="$HOME/.zshrc"
  local path_line='export PATH="$HOME/.bun/bin:$PATH"'

  if [[ ! -f "$zshrc" ]]; then
    touch "$zshrc"
  fi

  if ! grep -Fq "$path_line" "$zshrc"; then
    log "Adding Bun global bin path to ~/.zshrc..."
    printf "\n%s\n" "$path_line" >>"$zshrc"
  fi

  export PATH="$HOME/.bun/bin:$PATH"
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
  local target_dir="$HOME/.config/alacritty"
  local target_file="$target_dir/alacritty.toml"

  if [[ ! -f "$source_file" ]]; then
    log "Alacritty config source not found at $source_file; skipping personalization."
    return
  fi

  mkdir -p "$target_dir"

  if [[ -f "$target_file" ]]; then
    cp "$target_file" "$target_file.bak.$(date +%Y%m%d%H%M%S)"
  fi

  cp "$source_file" "$target_file"
  log "Applied Alacritty Catppuccin personalization to $target_file"
}


install_optional_local_agent_tools() {
  if [[ "${INSTALL_LOCAL_AGENT_TOOLS:-0}" != "1" ]]; then
    log "Skipping optional local agent stack install (set INSTALL_LOCAL_AGENT_TOOLS=1 to enable)."
    return
  fi

  log "Installing optional local agent/automation tools..."

  local formulas=(
    ollama
  )

  local casks=(
    lm-studio
  )

  for pkg in "${formulas[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      echo "  - $pkg already installed"
    else
      brew install "$pkg"
    fi
  done

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

main() {
  ensure_xcode_cli_tools
  ensure_homebrew
  install_formulae
  install_casks
  configure_zsh
  configure_git_basics
  configure_mise_runtimes
  ensure_bun_path
  install_js_tooling_with_bun
  apply_alacritty_personalization
  install_optional_local_agent_tools
  post_install_tips
}

main "$@"
