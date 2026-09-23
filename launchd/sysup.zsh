#!/bin/zsh
# Weekly system update, run by launchd (com.exarus.sysup). Sources .zshrc to
# get sysup() from the dotfiles repo (oh-my-zsh/custom/functions.zsh), since
# launchd doesn't start a login/interactive shell on its own.
set -euo pipefail

source ~/.zshrc
sysup
