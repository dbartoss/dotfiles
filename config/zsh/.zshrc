# Enable Oh My Posh instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/omp-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/omp-instant-prompt-${(%):-%n}.zsh"
fi

# # Auto-start tmux (BEFORE setting TERM)
if [[ -z "$TMUX" ]] && [[ -z "$EMACS" ]] && [[ -z "$VIM" ]]; then
  exec tmux new-session -A -s main
fi

# Set TERM for alacritty + tmux
if [ -n "$TMUX" ]; then
  export TERM=screen-256color
#   export TERM=tmux-256color
else
  export TERM=alacritty
#   export TERM=xterm-256color
fi

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
# Make sure we're in an emacs-like keymap (common default)
bindkey -e

# If region isn't active, start it (set mark), then move.
_selectify() {
  local widget="$1"
  if (( ! REGION_ACTIVE )); then
    zle set-mark-command
  fi
  zle "$widget"
}

# If a region is active, delete it; otherwise do normal behavior
_delete_or_backspace() {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle backward-delete-char
  fi
}

_delete_or_deletechar() {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle delete-char
  fi
}

# ----- CMD+X (cut) -----
_cut_region_cmd() {
  if (( REGION_ACTIVE )); then
    local s=$MARK e=$CURSOR
    (( s > e )) && { local t=$s; s=$e; e=$t; }
    print -rn -- "${BUFFER[s+1,e]}" | pbcopy
    zle kill-region
  fi
}

# ----- CMD+C (copy) -----
_copy_region_cmd() {
  if (( REGION_ACTIVE )); then
    local s=$MARK e=$CURSOR
    (( s > e )) && { local t=$s; s=$e; e=$t; }
    print -rn -- "${BUFFER[s+1,e]}" | pbcopy
    zle deactivate-region
  fi
}

# ----- CMD+A (select all) -----
_select_all_cmd() {
  # Start selection at beginning, extend to end
  zle beginning-of-line
  zle set-mark-command
  zle end-of-line

  # If you want REALLY everything across newlines too (rare in prompt):
  # zle beginning-of-buffer-or-history
  # zle set-mark-command
  # zle end-of-buffer-or-history
}


# Concrete widgets (must be real functions)
_select_left()   { _selectify backward-char }
_select_right()  { _selectify forward-char }
_select_wleft()  { _selectify backward-word }
_select_wright() { _selectify forward-word }
_select_bol()    { _selectify beginning-of-line }
_select_eol()    { _selectify end-of-line }

# Register as ZLE widgets
zle -N _select_left
zle -N _select_right
zle -N _select_wleft
zle -N _select_wright
zle -N _select_bol
zle -N _select_eol
zle -N _select_all_cmd

zle -N _delete_or_backspace
zle -N _delete_or_deletechar
zle -N _cut_region_cmd
zle -N _copy_region_cmd

# SELECT ALL
bindkey '^[a' _select_all_cmd

# CUT / COPY selected
bindkey '^[w' _copy_region_cmd
bindkey '^[x' _cut_region_cmd

# Optional: Esc cancels selection
bindkey '^[' deactivate-region

# Backspace
bindkey '^?' _delete_or_backspace

# Forward Delete (depends on terminal; keep both)
bindkey '^[[3~' _delete_or_deletechar
bindkey '^[3~'  _delete_or_deletechar

# --- Bind keys that should SELECT ---

# Shift+Left / Shift+Right (most terminals)
bindkey '^[[1;2D' _select_left
bindkey '^[[1;2C' _select_right

# Shift+Alt+Left / Shift+Alt+Right (select by word)
bindkey '^[[1;4D' _select_wleft
bindkey '^[[1;4C' _select_wright

# If your terminal emits these for Shift+Home/End (only if it actually sends them)
bindkey '^[[1;2H' _select_bol
bindkey '^[[1;2F' _select_eol

# Shift+Home / Shift+End (your terminal)
bindkey '^[[1;10D' _select_bol
bindkey '^[[1;10C' _select_eol


# # Enable selection / region
# zle -N select-region


# # SELECTION
# bindkey '^[[1;2D' backward-char        # Shift + Left
# bindkey '^[[1;2C' forward-char         # Shift + Right
# bindkey '^[[1;2A' up-line-or-history   # Shift + Up
# bindkey '^[[1;2B' down-line-or-history # Shift + Down

# bindkey '^[[1;4D' backward-word        # Shift + Alt + Left
# bindkey '^[[1;4C' forward-word         # Shift + Alt + Right
# bindkey '^[^[[D' backward-word         # fallback
# bindkey '^[^[[C' forward-word

# # Shift + Home
# bindkey '^[[1;2H' beginning-of-line
# bindkey '^[[2H'   beginning-of-line

# # Shift + End
# bindkey '^[[1;2F' end-of-line
# bindkey '^[[2F'   end-of-line

# Home / End -> beginning/end of line (use terminfo when available)
[[ -n ${terminfo[khome]} ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n ${terminfo[kend]}  ]] && bindkey "${terminfo[kend]}"  end-of-line


# Fallbacks for common Home/End escape sequences (macOS Terminal, iTerm2, etc.)
bindkey '^[[H'  beginning-of-line   # Home
bindkey '^[[F'  end-of-line         # End
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[7~' beginning-of-line
bindkey '^[[8~' end-of-line

# Alt+Left / Alt+Right -> jump by word
# Many terminals send ESC + b / ESC + f for Option/Alt combos
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Some setups send ESC + Left/Right CSI sequences
bindkey '^[[1;3D' backward-word   # Alt+Left
bindkey '^[[1;3C' forward-word    # Alt+Right
bindkey '^[[1;9D' backward-word   # sometimes (kitty)
bindkey '^[[1;9C' forward-word

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
# bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Bun path
export PATH="$HOME/.bun/bin:$PATH"

# direnv
eval "$(direnv hook zsh)"

# Mise
eval "$(mise activate zsh)"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Oh My Posh initialization (must be last)
if command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/config.toml")"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/dbartosz/.lmstudio/bin"
# End of LM Studio CLI section

