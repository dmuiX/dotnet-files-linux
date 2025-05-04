#!/usr/bin/env bash

set -euo pipefail
trap 'echo "[dotfiles] ERROR in line $LINENO"; exit 1' ERR

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[dotfiles] Using dotfiles directory: $DOTFILES_DIR"

###############################################################################
# 1. Dotfiles kopieren (. & .config) – immer überschreiben
###############################################################################

shopt -s dotglob nullglob

echo "[dotfiles] Copying top‑level dotfiles (overwrite mode)…"
for src in "$DOTFILES_DIR"/.*; do
  name=$(basename "$src")
  [[ "$name" =~ ^(\.|\.{2}|\.git|\.DS_Store)$ ]] && continue
  echo "[dotfiles] Copy $name"
  cp -a "$src" "$HOME/$name"
done

CFG_SRC="$DOTFILES_DIR/.config"
CFG_DST="$HOME/.config"
if [[ -d "$CFG_SRC" ]]; then
  echo "[dotfiles] Copying .config (overwrite mode)…"
  rsync -a --delete "$CFG_SRC"/ "$CFG_DST"/
fi
shopt -u dotglob nullglob
echo "[dotfiles] Dotfiles copy complete."

###############################################################################
# 2. Paket‑Abhängigkeiten (curl, git, zsh, gnupg)
###############################################################################

need_pkgs=(curl git zsh gnupg)

install_pkgs() {
  if command -v apt-get &>/dev/null; then                # Debian/Ubuntu
    sudo -n true 2>/dev/null || { echo "[dotfiles] sudo required"; exit 1; }
    sudo apt-get update -qq
    sudo apt-get install -y "${need_pkgs[@]}"

  elif command -v apk &>/dev/null; then                  # Alpine
    sudo apk add --no-cache "${need_pkgs[@]}"

  elif command -v pacman &>/dev/null; then               # Arch
    sudo pacman -Sy --noconfirm "${need_pkgs[@]}"

  elif [[ $(uname -s) == Darwin ]]; then                 # macOS
    if ! command -v brew &>/dev/null; then
      echo "[dotfiles] Installing Homebrew…"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    brew update
    brew install "${need_pkgs[@]}"

  else
    echo "[dotfiles] Unsupported OS: $(uname -s)" >&2
    exit 1
  fi
}

for p in "${need_pkgs[@]}"; do
  command -v "$p" &>/dev/null || { echo "[dotfiles] Installing $p…"; install_pkgs; break; }
done

###############################################################################
# 3. Oh‑My‑Zsh + Plugins
###############################################################################

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "[dotfiles] Installing Oh‑My‑Zsh…"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

echo "[dotfiles] Ensuring Zsh plugins…"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
echo "[dotfiles] Zsh plugins ready."

###############################################################################
# 4. Atuin‑Installation + .zshrc‑Patch (ohne Marker)
###############################################################################

if ! command -v atuin &>/dev/null; then
  echo "[dotfiles] Installing Atuin…"
  curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
fi

ZSHRC="$HOME/.zshrc"

# Atuin‑Initialisierung hinzufügen, falls nicht vorhanden
if ! grep -q 'atuin init zsh' "$ZSHRC" 2>/dev/null; then
  {
    echo ''
    echo 'eval "$(atuin init zsh)"'
  } >> "$ZSHRC"
  echo "[dotfiles] Added Atuin eval to .zshrc"
fi

# Atuin‑Environment‑Script einbinden, falls nicht vorhanden
if ! grep -q '\. "\$HOME/.atuin/bin/env"' "$ZSHRC" 2>/dev/null; then
  echo '. "$HOME/.atuin/bin/env"' >> "$ZSHRC"
  echo "[dotfiles] Added Atuin env include to .zshrc"
fi

###############################################################################

echo "[dotfiles] Setup finished successfully."
