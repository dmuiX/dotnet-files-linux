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

need_pkgs=(curl git zsh gnupg bat fontconfig direnv btop lsof)

install_pkgs() {
  local pkgs=("${need_pkgs[@]}")

  if command -v apt-get &>/dev/null; then                # Debian/Ubuntu
    pkgs+=(dnsutils netcat-openbsd nala)
    sudo apt-get update -qq
    sudo apt-get install -y "${pkgs[@]}"

  elif command -v apk &>/dev/null; then                  # Alpine
    pkgs+=(bind-tools netcat-openbsd shadow)
    sudo apk add --no-cache "${pkgs[@]}"

  elif command -v pacman &>/dev/null; then               # Arch
    pkgs+=(bind-tools gnu-netcat)
    sudo pacman -Sy --noconfirm "${pkgs[@]}"
  
  elif command -v dnf &>/dev/null; then                   # Fedora/RHEL 8+
    pkgs+=(bind-utils nmap-ncat) 
    sudo dnf install -y "${pkgs[@]}"

  elif command -v yum &>/dev/null; then                   # RHEL 7, CentOS 7
    pkgs+=(bind-utils nmap-ncat)
    sudo yum install -y "${pkgs[@]}"
  
  elif [[ $(uname -s) == Darwin ]]; then                 # macOS
    if ! command -v brew &>/dev/null; then
      echo "[dotfiles] Installing Homebrew…"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    brew update
    brew install "${pkgs[@]}"

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

install_plugin() {
  local repo="$1"                                     # zsh-users/zsh-autosuggestions
  local dir="$ZSH_CUSTOM/plugins/$(basename "$repo")"

  if [[ -d "$dir/.git" ]]; then                       # schon geklont → update
    echo "[dotfiles] Updating $(basename "$dir")…"
    git -C "$dir" pull --ff-only --quiet
  else                                                # noch nicht da → clone
    echo "[dotfiles] Cloning $(basename "$dir")…"
    git clone --depth 1 "https://github.com/$repo" "$dir"
  fi
}

echo "[dotfiles] Ensuring Z‑sh plugins…"
for repo in \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions
do
  install_plugin "$repo"
done
echo "[dotfiles] Z‑sh plugins ready."

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
# 5. Meslo LGS NF im Container ablegen
###############################################################################

if [[ $(uname -s) == Linux ]]; then
  FONT_DIR="$HOME/.local/share/fonts"
  if [[ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]]; then
    echo "[dotfiles] Installing Meslo LGS NF fonts (container‑local)…"
    MESLO_URL_BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
    mkdir -p "$FONT_DIR"
    for font in \
      'MesloLGS NF Regular.ttf' \
      'MesloLGS NF Bold.ttf' \
      'MesloLGS NF Italic.ttf' \
      'MesloLGS NF Bold Italic.ttf'
    do
      curl -fsSL "$MESLO_URL_BASE/${font// /%20}" -o "$FONT_DIR/$font"
    done
    fc-cache -f
  fi
fi

###############################################################################
# 6. Powerlevel10k installieren
###############################################################################

if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo "[dotfiles] Installing Powerlevel10k…"
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ZSH_THEME setzen/ersetzen
if grep -q '^ZSH_THEME=' ~/.zshrc; then
  sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
fi

###############################################################################
# 7. Change default shell to zsh
###############################################################################

if [[ "$SHELL" != *"zsh"* ]]; then
  ZSH_PATH=$(command -v zsh)
  
  # Ensure zsh is in /etc/shells
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null 2>&1
  
  echo "[dotfiles] Changing shell to zsh..."
  chsh -s "$ZSH_PATH"
  
  echo "[dotfiles] Shell changed to zsh. Please log out/in to activate."
fi

###############################################################################

echo "[dotfiles] Setup finished successfully."
