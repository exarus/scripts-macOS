# scripts-macOS

My personal macOS setup — everything needed to take a fresh machine to a
fully configured one.

| File | What it does |
| --- | --- |
| [`Brewfile`](./Brewfile) | Every formula, cask, and Mac App Store app to install |
| [`init.zsh`](./init.zsh) | Bootstrap script — Homebrew, dotfiles, SSH key, apps |
| [`launchd/`](./launchd) | Scheduled background jobs (plist + script), symlinked into place by `init.zsh` |
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

- Set Google Chrome as default browser
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
cask 'balenaetcher'
cask 'bluestacks' # gaming
cask 'background-music'
cask 'crossover' # gaming
cask 'figma'
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
<summary><strong>🗄️ History — init.zsh restores the rental-search API keys (2026-10)</strong></summary>

The rental search in `~/MEGA/Projects/Housing - Rental Property Search` runs
scripts that need a Google Maps key, an OpenRouteService key and a Google
Sheets service-account JSON. They live in `~/.config/rental-search/` (never in
the MEGA folder, which syncs to the cloud and is read by AI agents), and the
master copy is two Bitwarden Secure Notes: `rental-search sheets-sa.json` and
`rental-search .env`.

`restore_rental_secrets` runs right after `restore_ssh_key` and reuses its
unlocked session. It looks the notes up by exact name, and follows the same
refuse-to-write rule: the JSON must be a service account with a private key,
and the env note must set both keys. Files are written under `umask 077`.
Verified against a stubbed `bw`: locked, missing note, wrong JSON and
incomplete env all leave nothing written; the happy path writes a `0700`
directory with `0600` files.

</details>

<details>
<summary><strong>🗄️ History — qbittorrent moved to a third-party tap (2026-09)</strong></summary>

Homebrew disabled the official `qbittorrent` cask on 2026-09-01
(`fails_gatekeeper_check`: the app isn't Developer ID–signed), so `brew
upgrade` stopped updating it. It now installs from
[`thedavidweng/unsigned-tap`](https://github.com/thedavidweng/homebrew-unsigned-tap),
which carries the same cask plus a postflight that strips
`com.apple.quarantine`.

Accepted supply-chain risk, knowingly: the tap is new, small, and
auto-updated nightly by its owner, and the weekly `sysup` job runs `brew
upgrade` unattended — so its cask code runs here unreviewed. To limit that,
only the `qbittorrent` cask is `brew trust`ed, not the whole tap (~600
casks). No other unsigned casks should be added.

</details>

<details>
<summary><strong>🗄️ History — weekly sysup moved from ad hoc to `launchd/` (2026-09)</strong></summary>

`sysup` (Oh My Zsh + chezmoi + `brew update`/`upgrade`/`autoremove`/`cleanup`,
defined in the dotfiles repo's `functions.zsh`) existed but was only ever run
by hand, so `claude-code@latest` and everything else in the Brewfile could
still drift for weeks between runs — which is exactly how the stale-`claude`
bug in the entry below happened.

Added `launchd/sysup.zsh` (sources `~/.zshrc` so `sysup()` is in scope, since
`launchd` jobs don't start a login shell) and `launchd/com.exarus.sysup.plist`
(runs it every Monday 9am via `StartCalendarInterval`; only fires while
logged in and awake — a missed slot runs at next login, it doesn't queue).
`init.zsh` now symlinks both into `~/.local/share/scheduled-tasks/` and
`~/Library/LaunchAgents/` and does a `launchctl unload`/`load`, so a fresh Mac
gets the schedule automatically and any later edit to the files in this repo
takes effect after the next `launchctl load` — no re-copying needed. Output
logs to `~/.local/share/scheduled-tasks/sysup.log`.

</details>

<details>
<summary><strong>🗄️ History — Brewfile reconciled with installed apps (2026-09)</strong></summary>

Added the `adguard`, `anydesk` and `google-chrome` casks and the `maven` and
`openjdk@21` formulae, which were installed but untracked, so a fresh Mac set
up from this repo gets them. Removed the `comet` cask, so fresh setups no
longer install it. Chrome is now the default browser in the manual setup step.

`mas` is deliberately not listed: `brew bundle` installs the `mas` CLI itself
because the Brewfile has `mas` entries (App Store IDs; needs an App Store
sign-in). `brew bundle cleanup` still reports it as untracked — don't run it
with `--force`, or it would uninstall `mas`.

</details>

<details>
<summary><strong>🗄️ History — claude-code tracks Anthropic's `latest` release channel (2026-09)</strong></summary>

Hit a stale-version bug where `claude` didn't pick up `AGENTS.md` support —
the Homebrew cask was several releases behind. Anthropic publishes two
release channels for the Claude Code binary
(`downloads.claude.ai/claude-code-releases/stable` vs. `.../latest`), and
Homebrew ships both as separate cask tokens with `conflicts_with` between
them: `claude-code` tracks `stable`, `claude-code@latest` tracks `latest`.
Switched the Brewfile entry from `claude-code` to `claude-code@latest` to get
new releases as soon as Anthropic cuts them instead of whenever they promote
to stable.

Checked whether the same applies to the other AI tools in the Brewfile
(`claude`, `chatgpt`, `codex`, `google-gemini`, `antigravity`,
`antigravity-cli`, `muse`, `muse-code`, `mistral-vibe`): none of them ship an
equivalent `@latest`/`@nightly` cask token in `homebrew-cask`. `claude`,
`chatgpt`, `google-gemini`, `antigravity`, `antigravity-cli`, and `muse` are
all Homebrew-`auto_updates` apps — they self-update to the actual latest
release in the background regardless of what version Homebrew last
installed, so there's no freshness gap to close for them. `muse-code` (Meta's
CLI coding agent, `dev.meta.ai`) checks a `muse-stable` channel via
`api.meta.ai`; there's also a `muse-canary` channel, but as of this check it
resolves to an *older* build than stable, so unlike Anthropic's split it's
not a faster stream and wasn't worth switching to. `codex` and `mistral-vibe`
(formula) do not self-update and have no faster channel to opt into; staying
current on those just means running `brew upgrade` reasonably often.

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
whenever `TERM_PROGRAM` names a supported terminal — iTerm2 included. So on a
machine set up from this repo, every interactive shell runs inside a second
pty, with the binary sitting between the terminal and zsh. That is why `ps`
shows dozens of `ghost-complete` processes, one per session.

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
