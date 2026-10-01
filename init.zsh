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

# --- Rental-search API keys (~/MEGA/Projects/Housing - Rental Property Search/scripts) ---
# Two Bitwarden Secure Notes, looked up by exact name; reuses the session restore_ssh_key unlocked.
restore_rental_secrets() {
  local dir=~/.config/rental-search
  local sa env

  bw unlock --check &>/dev/null || { print -u2 'bitwarden: locked — run restore_ssh_key first'; return 1 }

  bw_note() {
    bw list items --search "$1" | jq -er --arg n "$1" \
      '[.[] | select(.name == $n)] | if length == 1 then .[0].notes else error("expected one item named \($n), found \(length)") end'
  }
  sa=$(bw_note 'rental-search sheets-sa.json') || { print -u2 'bitwarden: could not read note "rental-search sheets-sa.json"'; return 1 }
  env=$(bw_note 'rental-search .env') || { print -u2 'bitwarden: could not read note "rental-search .env"'; return 1 }

  # Same rule as the SSH key: never write anything that isn't what we expect.
  print -r -- "$sa" | jq -e '.type == "service_account" and (.private_key | startswith("-----BEGIN PRIVATE KEY-----"))' &>/dev/null || {
    print -u2 'bitwarden: sheets note is not a service-account JSON — refusing to write'; return 1
  }
  [[ $env == *GOOGLE_MAPS_API_KEY=?* && $env == *ORS_API_KEY=?* ]] || {
    print -u2 'bitwarden: env note lacks GOOGLE_MAPS_API_KEY / ORS_API_KEY — refusing to write'; return 1
  }

  (umask 077; mkdir -p "$dir" && print -r -- "$sa" > "$dir/sheets-sa.json" && print -r -- "$env" > "$dir/.env") || return 1
  print '==> restored ~/.config/rental-search'
}
restore_rental_secrets || print -u2 'Rental-search keys not restored — the rental scripts will fail until they are.'

chezmoi init --apply git@github.com:exarus/dotfiles.git
ghost-complete install
pnpm setup

# --- Scheduled maintenance (launchd) ---
# Symlinked rather than copied so future edits to launchd/ take effect after
# the next launchctl load, without re-running init.zsh.
mkdir -p ~/.local/share/scheduled-tasks ~/Library/LaunchAgents
ln -sf "$PWD/launchd/sysup.zsh" ~/.local/share/scheduled-tasks/sysup.zsh
ln -sf "$PWD/launchd/com.exarus.sysup.plist" ~/Library/LaunchAgents/com.exarus.sysup.plist
launchctl unload ~/Library/LaunchAgents/com.exarus.sysup.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.exarus.sysup.plist

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
