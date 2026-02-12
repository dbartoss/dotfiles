# macOS Ventura (Apple Silicon) dotfiles bootstrap

This repository contains an opinionated setup for an Apple M1 Pro (16 GB RAM) on macOS Ventura 13.7.8.

## Philosophy

- **Bun-first JavaScript toolchain**: Bun is installed and used as the package manager/runtime by default.
- **Node/npm are optional**: they are **not** installed by default. You can enable Node later only when required by specific projects.
- **Go and Rust are first-class runtimes**: both are installed globally via `mise` for backend/systems development.
- **Includes foundational machine setup**: Xcode CLI Tools, Homebrew, Git defaults, and GitHub CLI auth guidance are covered.
- **Idempotent setup**: script can be safely re-run.
- **Personalized terminal UX**: applies a bundled Alacritty config with Catppuccin Mocha theme and sensible defaults.

---

## Basic setup included

Before app/tool install, the script handles foundational machine prerequisites:

1. **Xcode Command Line Tools** (`xcode-select --install`) because many build tools and Homebrew formulas depend on Apple toolchains.
2. **Homebrew bootstrap + update** so package/cask installation works on Apple Silicon (`/opt/homebrew`).
3. **Git defaults** (global) for practical day-to-day usage:
   - `init.defaultBranch=main`
   - `fetch.prune=true`
   - `pull.rebase=false`
   - `core.editor="code --wait"`
4. **Optional Git identity via environment variables**:
   - `GIT_USER_NAME`
   - `GIT_USER_EMAIL`

Example:

```bash
GIT_USER_NAME="Your Name" GIT_USER_EMAIL="you@example.com" ./scripts/setup_macos.sh
```

---

## What gets installed (with explanations)

### Shell, terminal, and editor

- **`zsh`**: modern shell with better completion and scripting ergonomics than legacy shells; installed from Homebrew for newer versioning than macOS system zsh.
- **`alacritty`**: GPU-accelerated terminal emulator, fast startup and rendering.
- **`visual-studio-code`**: mainstream IDE/editor for web, backend, and infra workflows.

### AI developer tooling

- **`@anthropic-ai/claude-code`**: Claude CLI for coding tasks and repo workflows.
- **`@openai/codex`**: Codex CLI for coding assistance and automation.

> These CLIs are installed using **Bun** global packages (`bun add -g ...`), not npm.

### Containers/virtualization

- **`orbstack`**: lighter alternative to Docker Desktop for containers/VMs on macOS (optional). Note: docker cask is commented out by default in `install_casks()` but can be enabled if needed.

### Core command-line engineering utilities

- **`git`**: version control.
- **`gh`**: GitHub CLI for PRs/issues/actions.
- **`curl` / `wget`**: HTTP download/test tooling.
- **`jq`**: JSON parsing/transformation in shell pipelines.
- **`fd`**: faster/simpler `find` alternative.
- **`fzf`**: fuzzy finder for interactive shell workflows.
- **`zoxide`**: smarter directory jumping with command history.
- **`tmux`**: terminal multiplexer for persistent sessions.
- **`neovim`**: modal terminal editor.
- **`oh-my-posh`**: fast cross-shell prompt with customizable segments (Catppuccin Mocha theme).

### Runtime/version management + language stack

- **`mise`**: runtime manager (replaces juggling version managers); used here to pin Bun, Go, and Rust globally.
- **`bun`**: JavaScript runtime, package manager, and task runner.
- **`go`**: Go toolchain for backend services, CLIs, and cloud-native software.
- **`rust`** (`rustc` + `cargo`): systems and backend language with excellent tooling and performance.

### Environment quality and automation

- **`direnv`**: per-project environment variable loading.
- **`pre-commit`**: git hook framework for lint/format/secret checks.
- **`watchman`**: efficient file watching for large projects.

### Security and UX extras

- **`rectangle`**: window management shortcuts.
- **`1password`**: credential/secret manager (commented out by default in `install_casks()` but can be enabled if needed).

### Browsers and API testing

- **`google-chrome`**: cross-browser verification.
- **`firefox`** and **`zen-browser`**: commented out by default in `install_casks()` but can be enabled if needed.
- **`postman`**: API development/testing UI.

---

## Alacritty personalization included

The setup script automatically deploys `config/alacritty/alacritty.toml` to `~/.config/alacritty/alacritty.toml`.

It includes:

- **Catppuccin Mocha color theme** (dark, high-contrast but soft palette).
- **macOS-friendly window settings** (`Buttonless` decorations, slight opacity, padding, Option-as-Alt).
- **Editor-friendly defaults** (beam cursor, large scrollback, copy selection to clipboard).
- **Useful keybindings** for font scaling (`⌘+`, `⌘-`, `⌘0`). Note: window management keybindings (`⌘N`, `⌘W`) are disabled in favor of tmux session management.
- **Safe overwrite behavior**: existing `alacritty.toml` is backed up with a timestamp before applying updates.

---

## Additional useful developer tools (suggested, optional)

If you want to expand beyond the default install set:

- **`lazygit`**: terminal Git UI for staging/commit/rebase workflows.
- **`httpie`**: cleaner API testing from terminal than raw `curl`.
- **`hyperfine`**: benchmark CLI commands/scripts.
- **`bat`**: `cat` with syntax highlighting and paging.
- **`eza`**: modern `ls` replacement.
- **`pnpm`** (via Corepack or Bun-compatible workflow): useful for monorepos where teams standardize on pnpm.

---

## Local agents / automations you can run on your own machine

Recommended apps:

- **Ollama** (local LLM runner): easiest way to run models locally on macOS.
- **LM Studio** (GUI local model manager): simple model download + chat/testing UI.
- **n8n** (automation workflows): self-hostable automation engine (can run via Docker).
- **Open WebUI** (local chat UI): browser UI connected to local model runtimes (often paired with Ollama).

This repo now supports optional installation of local-agent base tools:

```bash
INSTALL_LOCAL_AGENT_TOOLS=1 ./scripts/setup_macos.sh
brew services start ollama
ollama pull qwen2.5-coder:7b
```

If you want, I can also add an n8n + Open WebUI Docker Compose profile to this repo.

---

## Quick start

```bash
chmod +x scripts/setup_macos.sh
./scripts/setup_macos.sh
```

After install:

1. Restart terminal session.
2. Open Docker Desktop once to finish privileged helper setup.
3. Authenticate accounts:

```bash
gh auth login
claude login
codex login
```

4. Run checks:

```bash
brew --version
git --version
mise doctor
mise ls
bun --version
go version
rustc --version
cargo --version
```

5. Verify tools:

```bash
zsh --version
alacritty --version
code --version
docker --version
bun --version
```

---

## Optional: enable Node later (only if needed)

Some legacy projects still require Node/npm directly. If needed:

```bash
mise use -g node@lts
```

This keeps the default environment Bun-first while still allowing compatibility when required.

## Notes

- Script expects Homebrew at `/opt/homebrew` (Apple Silicon default).
- Bun global installs generally place binaries under `~/.bun/bin`; script ensures this path is exported in `~/.zshrc`.
- `claude` and `codex` may require authentication after installation.
- Config files (alacritty, tmux, zsh, karabiner, oh-my-posh) are automatically symlinked from the repo to `~/.config/` during setup.
- Zsh is configured to auto-start tmux on new terminal sessions; use `TMUX='' zsh` or set `$TMUX` to bypass if needed.
- Terminal TERM is set to `screen-256color` when inside tmux for best compatibility with clear command and other utilities.


## Keybindings Reference

### Alacritty (Terminal Emulator)
These keybindings work globally in Alacritty and don't conflict with tmux/zsh:

| Keybinding | Action |
|---|---|
| `⌘+` | Increase font size |
| `⌘-` | Decrease font size |
| `⌘0` | Reset font size to default |
| `⌘C` | Copy selection |
| `⌘V` | Paste from clipboard |

### Tmux (Terminal Multiplexer)
All tmux commands use `Ctrl+Space` as the prefix. Press `Ctrl+Space` then the key:

#### Pane Navigation
| Keybinding | Action |
|---|---|
| `C-Space h` | Select left pane |
| `C-Space j` | Select down pane |
| `C-Space k` | Select up pane |
| `C-Space l` | Select right pane |

#### Pane Resizing (repeatable - hold after prefix)
| Keybinding | Action |
|---|---|
| `C-Space H` | Resize pane left (5 cells) |
| `C-Space J` | Resize pane down (5 cells) |
| `C-Space K` | Resize pane up (5 cells) |
| `C-Space L` | Resize pane right (5 cells) |

#### Window Management
| Keybinding | Action |
|---|---|
| `C-Space c` | Create new window (opens in current path) |
| `C-Space \|` | Split window vertically (current path) |
| `C-Space -` | Split window horizontally (current path) |
| `C-Space ,` | Rename current window |
| `C-Space Tab` | Jump to last active window |
| `C-Space s` | Choose session |
| `C-Space r` | Reload tmux config file |

#### Copy Mode (Vi-like)
| Keybinding | Action |
|---|---|
| `C-Space [` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Copy selection and exit copy mode (macOS clipboard) |
| `C-Space p` | Paste from macOS clipboard |
| `Escape` | Cancel copy mode |

### Vim/Neovim (if used within tmux)
Standard vim keybindings apply. Note: `Ctrl+Space` is reserved for tmux, so it won't reach vim.

### Karabiner-Elements (External Keyboard Support)
For Dell WK717 keyboards and other external keyboards, Karabiner maps navigation keys to macOS conventions. Configuration is managed in `config/karabiner/karabiner.json` and automatically symlinked to `~/.config/karabiner/karabiner.json`.

Key mappings include:

| Physical Key | Maps To | Behavior |
|---|---|---|
| `Home` | `⌘Left` | Jump to line start |
| `Home+Shift` | `⌘Shift+Left` | Select to line start |
| `End` | `⌘Right` | Jump to line end |
| `End+Shift` | `⌘Shift+Right` | Select to line end |
| `Page Up` | `Option+Up` | Page up |
| `Page Down` | `Option+Down` | Page down |
| `Ctrl+Home` | `⌘Up` | Jump to document start |
| `Ctrl+End` | `⌘Down` | Jump to document end |

---

## Startup Behavior

1. **Alacritty opens** → launches a new terminal instance
2. **Zsh initializes** → automatically starts/attaches to tmux session named `main`
3. **Tmux session active** → you can now use all `C-Space` prefix commands

To manually manage tmux sessions:

```bash
# List sessions
tmux list-sessions

# Create named session
tmux new-session -s work

# Attach to session
tmux attach -t main

# Kill session
tmux kill-session -t main
```

---

## No Conflicts

- **Alacritty keybindings** use `⌘` (Command) modifier → won't trigger in app
- **Tmux prefix** is `C-Space` (Ctrl+Space) → doesn't overlap with terminal emulator or vim
- **Karabiner** only affects external keyboards, not built-in MacBook keyboard
