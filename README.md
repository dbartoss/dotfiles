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

- **`docker` (Docker Desktop)**: local container build/run tooling with Docker Engine + Compose UX.
- **`orbstack`**: lighter alternative to Docker Desktop for containers/VMs on macOS (optional, but useful for performance).

### Core command-line engineering utilities

- **`git`**: version control.
- **`gh`**: GitHub CLI for PRs/issues/actions.
- **`curl` / `wget`**: HTTP download/test tooling.
- **`jq`**: JSON parsing/transformation in shell pipelines.
- **`ripgrep`** (`rg`): extremely fast project text search.
- **`fd`**: faster/simpler `find` alternative.
- **`fzf`**: fuzzy finder for interactive shell workflows.
- **`tmux`**: terminal multiplexer for persistent sessions.
- **`neovim`**: modal terminal editor.
- **`starship`**: fast cross-shell prompt.

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

- **`1password`**: credential/secret manager.
- **`rectangle`**: window management shortcuts.

### Browsers and API testing

- **`firefox`**, **`google-chrome`**, and **`zen-browser`**: cross-browser verification, including Zen Browser.
- **`postman`**: API development/testing UI.

---

## Alacritty personalization included

The setup script automatically deploys `config/alacritty/alacritty.toml` to `~/.config/alacritty/alacritty.toml`.

It includes:

- **Catppuccin Mocha color theme** (dark, high-contrast but soft palette).
- **macOS-friendly window settings** (`Buttonless` decorations, slight opacity, padding, Option-as-Alt).
- **Editor-friendly defaults** (beam cursor, large scrollback, copy selection to clipboard).
- **Useful keybindings** for new window and font scaling (`⌘N`, `⌘+`, `⌘-`, `⌘0`).
- **Safe overwrite behavior**: existing `alacritty.toml` is backed up with a timestamp before applying updates.

---

## Additional useful developer tools (suggested, optional)

If you want to expand beyond the default install set:

- **`lazygit`**: terminal Git UI for staging/commit/rebase workflows.
- **`httpie`**: cleaner API testing from terminal than raw `curl`.
- **`hyperfine`**: benchmark CLI commands/scripts.
- **`bat`**: `cat` with syntax highlighting and paging.
- **`eza`**: modern `ls` replacement.
- **`zoxide`**: smarter directory jumping.
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
