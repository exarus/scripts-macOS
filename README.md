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
<summary><strong>🛠️ TODO — init.zsh improvements</strong></summary>

Found by a Claude Code review of `init.zsh`, not yet applied.

**Likely-breaking bugs**
1. **oh-my-zsh install will hijack the script.** The official installer execs into a new interactive `zsh -l` shell at the end unless `RUNZSH=no` (and typically `CHSH=no KEEP_ZSHRC=yes`) is set. If this script is ever run top-to-bottom rather than pasted line-by-line, everything after the oh-my-zsh line (SSH key, chezmoi, ghost-complete, pnpm, iTerm schemes, Keka, Battle.net, `gh auth login`) never executes — you just land in a fresh nested shell.
2. **`bw get item` assumes an already-unlocked Bitwarden CLI session.** There's no `bw login`/`bw unlock` (or `BW_SESSION` export) anywhere in the script. On a truly fresh machine this fails with "not logged in" / "vault is locked", and since there's no error checking, `jq -r .sshKey.privateKey` on an error payload can silently write garbage (or the literal string `null`) into `~/.ssh/id_ed25519` instead of failing loudly.
3. **No `set -e`/`set -euo pipefail`.** Every command's failure is silently swallowed and the script marches on. Given this pipeline writes a signing/auth SSH key and then immediately does a `git`-over-SSH clone with it, a quiet failure early on (bad Bitwarden item, network blip) turns into a confusing failure several steps later instead of stopping where the real problem is.

**Working-directory / path fragility**
4. **`brew bundle` has no `--file=Brewfile`.** It relies on the script being run with cwd = repo root. If invoked from elsewhere it either uses the wrong file or errors.
5. **iTerm2 color scheme clone happens into the current working directory**, not a temp dir. If the script is re-run after a partial failure, `git clone` fails because `./iTerm2-Color-Schemes` already exists from the aborted run — and since cleanup only runs if the import step succeeds and nothing traps failures, a half-finished clone can be left behind indefinitely.
6. Consider resolving the script's own directory (`${0:A:h}` in zsh) up front so `brew bundle` and any relative paths work regardless of invocation cwd.

**Missing safety nets around the SSH/git step**
7. No validation that the fetched key actually looks like a private key before `chmod 600`/using it (e.g. checking for the `-----BEGIN OPENSSH PRIVATE KEY-----` header).
8. No `ssh-keyscan github.com >> ~/.ssh/known_hosts` (or `StrictHostKeyChecking=accept-new`) before the first SSH connection to GitHub (`chezmoi init --apply git@github.com:...`) — first connection will hit an interactive host-key confirmation prompt that isn't called out anywhere.
9. No post-setup verification step (e.g. `ssh -T git@github.com`) to confirm the restored key actually authenticates before depending on it for the rest of the bootstrap.

**Inconsistent interactivity/cleanup handling**
10. The Keka block blocks with `open -W` and then uninstalls the helper cask — but the Battle.net block fires `open` without `-W`, so the script (in a hypothetical full run) would race ahead to `gh auth login` while the Battle.net installer window is still open. Worth deciding if that's intentional or an oversight.
11. `open -W /Applications/KekaExternalHelper.app` hardcodes an exact app path/name; if the cask ever installs under a slightly different bundle name, this fails silently (no error handling, see #3).

**Lower-priority / stylistic**
12. Mixed interpreters for the two installer one-liners (`/bin/bash -c` for Homebrew, `sh -c` for oh-my-zsh) vs. the `#!/bin/zsh` shebang — harmless but inconsistent.
13. No idempotency guard on the Homebrew install itself (`command -v brew` check) — harmless on a truly fresh Mac, but means the script can't be safely re-run partway through without re-triggering the installer.
14. `ghost-complete install` may need Accessibility/Input Monitoring permissions granted manually (typical for text-expansion tools) — if so, that's currently undocumented in the "Manual configuration" section above.
15. No section banners/echoes (`==> doing X`) — if the intent really is "run this file straight through" rather than "paste block by block" (this doc says "step through interactively," which is a bit ambiguous given the file is executable with a shebang), some visible progress markers would make failures easier to locate.

The single highest-impact one is #1 (oh-my-zsh's `RUNZSH` behavior), since it silently truncates every run of the script as currently written.

</details>

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
cask 'crossover' # gaming
cask 'figma'
cask 'google-chrome'
cask 'handbrake-app'
cask 'jordanbaird-ice'
cask 'homebrew/cask-drivers/logitech-g-hub' # gaming
cask 'monitorcontrol'
cask 'grishka/grishka/neardrop'
cask 'parsec'
cask 'postman'
cask 'slack'
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