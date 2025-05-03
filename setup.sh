#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "[dotfiles] Copying dotfiles from $DOTFILES_DIR to $HOME..."

# Schleife über alle versteckten Dateien (beginnend mit .), aber keine .git oder .DS_Store etc.
shopt -s dotglob nullglob
for file in "$DOTFILES_DIR"/.*; do
  filename=$(basename "$file")

  # Ignoriere .git, ., .. und .DS_Store etc.
  if [[ "$filename" == "." || "$filename" == ".." || "$filename" == ".git" || "$filename" == ".DS_Store" ]]; then
    continue
  fi

  echo "[dotfiles] Copy $filename"
  cp -rf "$file" "$HOME/$filename"
  echo "[dotfiles] Copy $filename complete"
done
shopt -u dotglob nullglob

echo "[dotfiles] All dotfiles copied."

# Install dependencies
if command -v apt &> /dev/null; then
  sudo apt-get update
  sudo apt-get install -y curl gnupg2
fi

# Install Atuin
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash

# Add Atuin init to .zshrc (only if not already present)
if ! grep -q 'atuin init zsh' ~/.zshrc; then
  echo '' >> ~/.zshrc
  echo '# Initialize Atuin history sync' >> ~/.zshrc
  echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
fi

echo "[dotfiles] Atuin installation complete."

# Installiere Oh-My-Zsh nur, wenn es nicht existiert
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[dotfiles] Installing Oh-My-Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# clone plugins
echo "[dotfiles] Start cloning zsh plugins."

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

echo "[dotfiles] Cloning zsh plugins complete.
