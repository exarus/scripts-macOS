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
2. **No `set -e`/`set -euo pipefail`.** Every command's failure is silently swallowed and the script marches on. Given this pipeline writes a signing/auth SSH key and then immediately does a `git`-over-SSH clone with it, a quiet failure early on (bad Bitwarden item, network blip) turns into a confusing failure several steps later instead of stopping where the real problem is.

**Working-directory / path fragility**
3. **`brew bundle` has no `--file=Brewfile`.** It relies on the script being run with cwd = repo root. If invoked from elsewhere it either uses the wrong file or errors.
4. **iTerm2 color scheme clone happens into the current working directory**, not a temp dir. If the script is re-run after a partial failure, `git clone` fails because `./iTerm2-Color-Schemes` already exists from the aborted run — and since cleanup only runs if the import step succeeds and nothing traps failures, a half-finished clone can be left behind indefinitely.
5. Consider resolving the script's own directory (`${0:A:h}` in zsh) up front so `brew bundle` and any relative paths work regardless of invocation cwd.

**Missing safety nets around the SSH/git step**
6. No `ssh-keyscan github.com >> ~/.ssh/known_hosts` (or `StrictHostKeyChecking=accept-new`) before the first SSH connection to GitHub (`chezmoi init --apply git@github.com:...`) — first connection will hit an interactive host-key confirmation prompt that isn't called out anywhere.
7. No post-setup verification step (e.g. `ssh -T git@github.com`) to confirm the restored key actually authenticates before depending on it for the rest of the bootstrap.

**Inconsistent interactivity/cleanup handling**
8. The Keka block blocks with `open -W` and then uninstalls the helper cask — but the Battle.net block fires `open` without `-W`, so the script (in a hypothetical full run) would race ahead to `gh auth login` while the Battle.net installer window is still open. Worth deciding if that's intentional or an oversight.
9. `open -W /Applications/KekaExternalHelper.app` hardcodes an exact app path/name; if the cask ever installs under a slightly different bundle name, this fails silently (no error handling, see #2).

**Lower-priority / stylistic**
10. Mixed interpreters for the two installer one-liners (`/bin/bash -c` for Homebrew, `sh -c` for oh-my-zsh) vs. the `#!/bin/zsh` shebang — harmless but inconsistent.
11. No idempotency guard on the Homebrew install itself (`command -v brew` check) — harmless on a truly fresh Mac, but means the script can't be safely re-run partway through without re-triggering the installer.
12. `ghost-complete install` may need Accessibility/Input Monitoring permissions granted manually (typical for text-expansion tools) — if so, that's currently undocumented in the "Manual configuration" section above.
13. No section banners/echoes (`==> doing X`) — if the intent really is "run this file straight through" rather than "paste block by block" (this doc says "step through interactively," which is a bit ambiguous given the file is executable with a shebang), some visible progress markers would make failures easier to locate.

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
<summary><strong>🗄️ History — init.zsh no longer trusts the Bitwarden CLI blindly (2026-09)</strong></summary>

`init.zsh` used to restore the SSH key with a bare pipeline:

```zsh
bw get item <id> | jq -r .sshKey.privateKey > ~/.ssh/id_ed25519
```

Nothing checked that the CLI was logged in or unlocked. On a logged-out or
locked `bw`, the error goes to stderr and stdout is empty, `jq -r` turns that
into the literal string `null`, and the redirect writes `null` into
`~/.ssh/id_ed25519` — which then fails several steps later at the `chezmoi`
clone, looking like a network or GitHub problem rather than a vault problem.

This is not hypothetical: the Bitwarden CLI dropped its own auth state
mid-session on 2026-09-19 (`bw status` went from `locked` to `unauthenticated`
with the account still present in `data.json`), which is exactly the state that
produces the silent corruption.

The step is now a `restore_ssh_key` function that checks `bw login --check` and
`bw unlock --check` first, prompts for whichever is missing, uses `jq -e` so a
missing field is an error rather than `null`, and refuses to write anything that
does not start with `-----BEGIN OPENSSH PRIVATE KEY-----`. It writes under
`umask 077`, and returns rather than exits so a failure doesn't kill the shell
when the file is pasted into a live session instead of executed. Verified
against stubbed logged-out / locked / error-payload / wrong-value cases: all
four leave an existing key untouched, and the happy path writes mode `0600`.

</details>

<details>
<summary><strong>🗄️ History — ghost-complete is a PTY proxy, not a shell plugin (2026-09)</strong></summary>

`ghost-complete` (Brewfile, `StanMarek/tap`) does more than source a script.
`ghost-complete install` puts a block at the *top* of `~/.zshrc` that sources
`~/.config/ghost-complete/shell/init.zsh`, which runs `exec ghost-complete`
whenever `TERM_PROGRAM` names a supported terminal — iTerm2 included. So every
interactive shell on this machine runs inside a second pty, with the binary
sitting between the terminal and zsh. That is why `ps` shows dozens of
`ghost-complete` processes, one per session.

Worth remembering when debugging anything at the terminal-protocol layer: key
encodings, escape sequences, mouse reporting, bracketed paste. The proxy parses
input and re-emits it, so what a program receives is not necessarily what the
terminal sent.

It already cost one debugging session. Arrow keys in application-cursor mode
(DECCKM, `\e[?1h`) were reaching programs as `ESC [ B` instead of `ESC O B`,
because the proxy decoded the SS3 and CSI arrow forms to the same internal event
and could only re-emit the CSI one. From inside the proxy this is
indistinguishable from the terminal ignoring DECCKM — the terminal's mode state
and its DECRQM replies are all correct, and only the bytes reaching the program
are wrong. It was filed against iTerm2 as
[gnachman/iterm2#12939](https://gitlab.com/gnachman/iterm2/-/work_items/12939);
iTerm2 was correct the whole time. Fix submitted upstream as
[StanMarek/ghost-complete#173](https://github.com/StanMarek/ghost-complete/pull/173).

To take the proxy out of the picture while debugging, start a shell that never
reads `~/.zshrc`:

```zsh
/bin/zsh -f
```

Then compare against a normal shell. If the two disagree about bytes, the proxy
is in the path.

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