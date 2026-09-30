#!/bin/zsh
# Weekly system update, run by launchd (com.exarus.sysup). launchd starts a
# bare non-login, non-interactive shell, so load both .zprofile (Homebrew PATH
# via `brew shellenv`) and .zshrc (sysup() from the dotfiles repo's
# oh-my-zsh/custom/functions.zsh) by hand. No `set -u`: .zshrc and oh-my-zsh
# reference unset vars (TMUX, ZSH_CUSTOM) and would abort before sysup runs.
# sysup() uses `emulate -L zsh` + err_return, so its exit status is ours.

source ~/.zprofile
source ~/.zshrc
sysup
