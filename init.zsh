#!/bin/zsh

# --- Package managers & shell ---
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# --- SSH (also doubles as the git commit/tag signing key — see README) ---
# Wrapped in a function so a failure can `return` without killing the shell —
# this file gets pasted into a live session as often as it gets executed.
restore_ssh_key() {
  local item=521ec851-33f7-481e-a5af-b2df01245606
  local key

  # The Bitwarden CLI's auth state is its own, separate from the desktop app,
  # and it does get dropped (an interrupted command is enough). Check both
  # states rather than assuming: `bw get item` on a logged-out or locked CLI
  # prints an error to stderr and nothing to stdout, `jq -r` turns that into
  # the literal string "null", and the redirect below would happily write it
  # into ~/.ssh/id_ed25519. The failure then surfaces several steps later at
  # the chezmoi clone, looking like a network or GitHub problem.
  bw login --check &>/dev/null || bw login || {
    print -u2 'bitwarden: login failed'; return 1
  }
  bw unlock --check &>/dev/null || {
    BW_SESSION=$(bw unlock --raw) || { print -u2 'bitwarden: unlock failed'; return 1 }
    export BW_SESSION
  }

  key=$(bw get item "$item" | jq -er '.sshKey.privateKey') || {
    print -u2 "bitwarden: could not read sshKey.privateKey from item $item"; return 1
  }

  # Last line of defence: never write anything that isn't a private key.
  if [[ $key != '-----BEGIN OPENSSH PRIVATE KEY-----'* ]]; then
    print -u2 'bitwarden: fetched value is not an OpenSSH private key — refusing to write ~/.ssh/id_ed25519'
    return 1
  fi

  mkdir -p ~/.ssh
  (umask 077; print -r -- "$key" > ~/.ssh/id_ed25519) || return 1
  chmod 600 ~/.ssh/id_ed25519
  print '==> restored ~/.ssh/id_ed25519'
}
restore_ssh_key || print -u2 'SSH key not restored — fix the above before continuing.'

chezmoi init --apply git@github.com:exarus/dotfiles.git
ghost-complete install
pnpm setup

# --- iTerm2 color schemes ---
git clone --depth 1 https://github.com/mbadolato/iTerm2-Color-Schemes.git
./iTerm2-Color-Schemes/tools/import-scheme.sh 'Catppuccin Latte' 'Catppuccin Frappe' 'Catppuccin Macchiato' 'Catppuccin Mocha' Dracula+ Dracula 'Solarized Dark Patched'
rm -rf ./iTerm2-Color-Schemes

# --- Keka (interactive) ---
brew install --cask kekaexternalhelper
open -W /Applications/KekaExternalHelper.app
brew uninstall --cask kekaexternalhelper

# --- Battle.net (interactive) ---
open /opt/homebrew/Caskroom/battle-net/latest/Battle.net-Setup.app

# --- GitHub CLI ---
gh auth login
