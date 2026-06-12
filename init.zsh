#!/bin/zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# SSH, GPG
mkdir -p ~/.ssh
bw get item 521ec851-33f7-481e-a5af-b2df01245606 | jq -r .sshKey.privateKey > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
bw get item ad501fa8-3b2e-4dce-92dc-b2ad00998c1c | jq -r .notes | gpg --pinentry-mode loopback --import
pinentry-touchid -fix

chezmoi init --apply git@github.com:exarus/dotfiles.git
ghost-complete install

# iterm2
git clone --depth 1 https://github.com/mbadolato/iTerm2-Color-Schemes.git
./iTerm2-Color-Schemes/tools/import-scheme.sh 'Catppuccin Latte' 'Catppuccin Frappe' 'Catppuccin Macchiato' 'Catppuccin Mocha' Dracula+ Dracula 'Solarized Dark Patched'
rm -rf ./iTerm2-Color-Schemes

# keka (interactive)
brew install --cask kekaexternalhelper
open -W /Applications/KekaExternalHelper.app
brew uninstall --cask kekaexternalhelper

# Battle.net
open /opt/homebrew/Caskroom/battle-net/latest/Battle.net-Setup.app # interactive

gh auth login
