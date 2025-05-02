#!/bin/bash
set -e

echo "[dotfiles] Installing Atuin..."

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
