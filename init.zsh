#!/bin/zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
chmod 600 ~/.ssh/id_ed25519
ssh-keygen -f ~/.ssh/id_ed25519 -y > ~/.ssh/id_ed25519.pub
chezmoi init --apply git@github.com:exarus/dotfiles.git

# GPG.
# Copy GPG key to clipboard
pbpaste | gpg --pinentry-mode loopback --import
pinentry-touchid -fix

# iterm2
git clone --depth 1 https://github.com/mbadolato/iTerm2-Color-Schemes.git
./iTerm2-Color-Schemes/tools/import-scheme.sh ./iTerm2-Color-Schemes/schemes/*
rm -rf ./iTerm2-Color-Schemes

# keka (interactive)
brew install --cask kekaexternalhelper
open -W /Applications/KekaExternalHelper.app
brew uninstall --cask kekaexternalhelper

# Battle.net
open /opt/homebrew/Caskroom/battle-net/latest/Battle.net-Setup.app # interactive

# google-chrome (interactive)
# before doing enable VPN. See more at https://github.com/bpc-clone/bypass-paywalls-chrome-clean?tab=readme-ov-file#installation
curl -o bypass-paywalls-chrome-clean-master.zip https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw\?file\=bypass-paywalls-chrome-clean-master.zip
unzip bypass-paywalls-chrome-clean-master.zip
open .
# add to chrome
rm -rf bypass-paywalls-chrome-clean-master bypass-paywalls-chrome-clean-master.zip

# firefox
# See more at https://github.com/bpc-clone/bypass-paywalls-chrome-clean?tab=readme-ov-file#installation
curl -o bypass_paywalls_clean-latest.xpi https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-latest.xpi
open .
rm bypass_paywalls_clean-latest.xpi

# gh
gh auth login

