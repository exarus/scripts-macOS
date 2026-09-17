# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Ruslan's personal macOS machine setup: a `Brewfile`, a one-shot bootstrap script (`init.zsh`), and a `README.md`
with the manual steps that can't be scripted. There is no app code, build step, or test suite — this is
infrastructure-as-a-dotfile for taking a fresh Mac to a fully configured one. Mac-only; do not add
cross-platform abstractions.

Dotfiles themselves (shell config, `.gitconfig`, etc.) live in a separate repo, `exarus/dotfiles`, applied via
`chezmoi` from `init.zsh` — not here.

## Commands

```zsh
# Verify the Brewfile matches what's actually installed (should always pass)
brew bundle check --file=Brewfile --verbose

# Dry-run: find things installed on the system but missing from the Brewfile
brew bundle cleanup --file=Brewfile

# Actually uninstall anything not tracked in the Brewfile (destructive — confirm with the user first)
brew bundle cleanup --file=Brewfile --force
```

There is no lint/test/build step for this repo.

## Brewfile conventions

- Entries are grouped as `tap` / `brew` / `cask` / `mas`, each block loosely alphabetical but not strictly —
  new entries can go near related ones instead of forcing alphabetical order.
- Non-obvious entries get a trailing `#` comment tagging *why* it's installed, reusing the existing tag
  vocabulary rather than inventing new ones: `# AI`, `# dev`, `# gaming`, `# media`, `# pdf`, `# work`. Casks
  with self-explanatory names (`docker-desktop`, `discord`, `vlc`) get no comment.
- Keep the Brewfile and the actual system in sync in the same change: adding a package means both installing
  it (`brew install`/`brew install --cask`) and adding the Brewfile line; removing means both uninstalling and
  deleting the line. Use the `check`/`cleanup` commands above to verify before/after.
- `README.md` has a "Backlog — possible Brewfile additions" section (a `ruby` fenced block) for packages that
  are candidates but not yet installed — that's a holding area, not a normal Brewfile line.

## init.zsh

A sequential, largely non-idempotent bootstrap script meant to be stepped through interactively on a fresh
Mac (per the README, not run unattended end-to-end). Notable behavior:
- Pulls the SSH private key (used for both auth and git commit/tag signing via `gpg.format = ssh`) out of a
  Bitwarden vault item via `bw get item <id> | jq`.
- Applies dotfiles with `chezmoi init --apply git@github.com:exarus/dotfiles.git`.
- A few steps are inherently interactive (Bitwarden/GitHub login, Keka helper GUI install, Battle.net
  installer) and can't be made non-interactive.

## README.md

Holds what `init.zsh` can't do: manual System Settings/Finder/iTerm/app tweaks, the Brewfile backlog, and a
history log of past infra decisions (e.g. why commit signing moved from GPG to SSH-format signing). When
making a similar non-trivial infra change, add a short dated entry to that history section rather than just
changing behavior silently.
