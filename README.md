# Transfer

* `~/Projects`
* Import Raycast settings

## Update ownership

```zsh
chown -R ${USER}:staff ~/Projects
```

# Run `init.zsh` interactively

# Customize

## System Settings

- Press `Option+Command+D`
- Disable `Desktop & Dock` -> `Windows` -> `Close windows when quitting an application` (for `iTerm`)
- Set `Desktop & Dock` -> `Hot Corners...` -> `Right Bottom` to `-`
- Set `General` -> `Language & Region` -> `First day of week` to `Monday`
- Set `General` -> `Language & Region` -> `Number format` -> `1 234 567.89`
- Enable `Storage` -> `Empty Trash automatically`
- Disable `Menu Bar` -> `Menu Bar Controls` -> `Spotlight`
- Set `Trackpad` -> `More Gestures` -> `App Exposé` to `Swipe Down with Three Fingers`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Spotlight` -> `Show Spolight Search`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Spotlight` -> `Show Finder search window`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Input Sources` -> `Select the previous input source`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Input Sources` -> `Select the next input source`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Services` -> `Searching`
- Disable `Keyboard` -> `Keyboard Shortcuts...` -> `Services` -> `Text`
- Enable `Keyboard` -> `Text Input` -> `Input Sources` -> `Edit...` -> `All Input Sources` ->
  `Use the Caps Lock key to switch to and from ABC`

## Browser

- Set as default browser
- Sync settings

## Finder

### `Settings...`
- Disable `General` -> `Show these items on the desktop:` -> `External disks`
- Set `General` -> `New Finder windows show:` -> `~/Projects`
- Set `Advanced` -> `Show all filename extensions`

## Bitwarden

- Enable `Settings...` -> `Unlock with PIN`
- Enable `Settings...` -> `Unlock with Touch ID`
- Enable `Settings...` -> `Unlock with Touch ID` -> `Ask for Touch ID on app start`
- Enable `Settings...` -> `Allow browser integration`

## iTerm:

* Press `Control+Shift+Command+\` to set `iTerm` as default terminal
* Set `Profile` -> `Profile Names` -> `exarus` as default profile
* Enable `General` -> `Selection` -> `Applications in terminal may access clipboard`
* Set `Advanced -> Mouse -> Scroll wheel sends arrow keys when in alternate screen mode.` to `Yes`

## MEGA

* Selective sync with default settings (`MEGA` -> `~/MEGA`)

## Steam

* Disable `Preferences -> Interface -> Run Steam when my computer starts`


# Removed: GPG commit signing (migrated to SSH, 2026-07)

Git commit/tag signing used to run through GnuPG with a Touch ID pinentry:
`gnupg` + `pinentry-mac` + `jorgelbg/tap/pinentry-touchid` in the Brewfile,
and `init.zsh` imported a private key from a Bitwarden item
(`ad501fa8-3b2e-4dce-92dc-b2ad00998c1c`) via
`gpg --pinentry-mode loopback --import`, then ran `pinentry-touchid -fix`.

Worked fine for commits typed by hand, but `pinentry-touchid` pops a macOS
GUI Secure Enclave prompt — it hangs forever with no human at the keyboard
(background jobs, scheduled tasks, agentic/CI commits). Switched to git's
native SSH-format signing (`gpg.format = ssh`, git 2.34+) instead: the same
SSH key already restored above (`~/.ssh/id_ed25519`) doubles as the signing
key, no GnuPG stack needed. `~/.gitconfig` (`gpg.format`, `user.signingkey`,
`gpg.ssh.allowedSignersFile`) and `~/.ssh/allowed_signers` are managed by
chezmoi now, so `chezmoi init --apply` in `init.zsh` sets it all up — no
separate GPG import step required. The key was also registered as a
"signing key" (in addition to "authentication") on GitHub so commits still
show as Verified.

If GPG is ever needed again for something other than commits (e.g.
encrypted email): `brew install gnupg pinentry-mac`, then put
`pinentry-program /opt/homebrew/bin/pinentry-mac` (or `-touchid`) in
`~/.gnupg/gpg-agent.conf`. The Bitwarden GPG key item above was left alone
in the vault, just no longer pulled during bootstrap.

# Possibly interesting additions to Brewfile

```shell
brew 'fd'
brew 'fx'
brew 'kubernetes-cli'
brew 'magic-wormhole'
brew 'pyenv'
brew 'rsync'

cask 'android-platform-tools'
cask 'anydesk'
cask 'balenaetcher'
cask 'bluestacks' # gaming
cask 'background-music'
cask 'chatgpt'
cask 'crossover' # gaming
cask 'figma'
cask 'firefox'
cask 'google-chrome'
cask 'handbrake-app'
cask 'jordanbaird-ice'
cask 'kindle-previewer'
cask 'homebrew/cask-drivers/logitech-g-hub' # gaming
cask 'microsoft-teams'
cask 'monitorcontrol'
cask 'grishka/grishka/neardrop'
cask 'parsec'
cask 'postman'
cask 'rustdesk'
cask 'slack'
cask 'superwhisper'
cask 'tradingview'

mas 'MEGA VPN', id: 6456784858
mas 'Windows App', id: 1295203466
```
