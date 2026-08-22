# scripts-macOS

My personal macOS setup — everything needed to take a fresh machine to a
fully configured one.

| File | What it does |
| --- | --- |
| [`Brewfile`](./Brewfile) | Every formula, cask, and Mac App Store app to install |
| [`init.zsh`](./init.zsh) | Bootstrap script — Homebrew, dotfiles, SSH key, apps |
| `README.md` | This guide, including the manual steps that can't be scripted |

## Bootstrap a fresh Mac

1. **Restore data**
   - Copy `~/Projects` over from the old machine
   - Import Raycast settings
   - Fix ownership if needed:
     ```zsh
     chown -R ${USER}:staff ~/Projects
     ```

2. **Run the bootstrap** — step through [`init.zsh`](./init.zsh)
   interactively (it prompts for Bitwarden, GitHub, and a couple of GUI
   installers along the way).

3. **Apply the manual tweaks** below — the settings macOS won't let a
   script touch.

---

## Manual configuration

### System Settings

> Open with `Option+Command+D`.

- **Desktop & Dock → Windows** — disable `Close windows when quitting an application` (for iTerm)
- **Desktop & Dock → Hot Corners…** — set `Right Bottom` to `-`
- **General → Language & Region**
  - `First day of week` → `Monday`
  - `Number format` → `1 234 567.89`
- **Storage** — enable `Empty Trash automatically`
- **Menu Bar → Menu Bar Controls** — disable `Spotlight`
- **Trackpad → More Gestures** — set `App Exposé` to `Swipe Down with Three Fingers`
- **Keyboard → Keyboard Shortcuts…**
  - `Spotlight` → disable `Show Spotlight Search`
  - `Spotlight` → disable `Show Finder search window`
  - `Input Sources` → disable `Select the previous input source`
  - `Input Sources` → disable `Select the next input source`
  - `Services` → disable `Searching`
  - `Services` → disable `Text`
- **Keyboard → Text Input → Input Sources → Edit… → All Input Sources** —
  enable `Use the Caps Lock key to switch to and from ABC`

### Finder

- **Settings… → General**
  - `Show these items on the desktop:` → disable `External disks`
  - `New Finder windows show:` → `~/Projects`
- **Settings… → Advanced** — enable `Show all filename extensions`

### Browser

- Set as default browser
- Sync settings

### iTerm

- Press `Control+Shift+Command+\` to set iTerm as the default terminal
- Set profile `exarus` (`Profile → Profile Names`) as default
- **General → Selection** — enable `Applications in terminal may access clipboard`
- **Advanced → Mouse** — set `Scroll wheel sends arrow keys when in alternate screen mode` to `Yes`

### Bitwarden

- **Settings…** — enable:
  - `Unlock with PIN`
  - `Unlock with Touch ID`
  - `Unlock with Touch ID → Ask for Touch ID on app start`
  - `Allow browser integration`

### MEGA

- Selective sync with default settings (`MEGA → ~/MEGA`)

### Steam

- **Preferences → Interface** — disable `Run Steam when my computer starts`

---

<details>
<summary><strong>📌 Backlog — possible Brewfile additions</strong></summary>

```ruby
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

</details>

<details>
<summary><strong>🗄️ History — GPG commit signing removed (migrated to SSH, 2026-07)</strong></summary>

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

</details>

<details>
<summary><strong>CLI commands that modified dot files</strong></summary>

```shell
pnpm setup
uv tool update-shell
```
</details>