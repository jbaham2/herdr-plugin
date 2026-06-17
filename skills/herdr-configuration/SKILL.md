---
name: herdr-configuration
description: "Use when configuring or tuning herdr through its config file or detection manifests — editing ~/.config/herdr/config.toml, changing keybindings (prefix mode, direct shortcuts, special keys, custom pane/shell/plugin_action commands), setting a theme or custom colors, tuning agent-detection/labeling rules, configuring notifications and sounds, terminal/shell and sidebar/scrollback/mouse behavior, experimental flags, or authoring herdr's own plugins (herdr-plugin.toml). Triggers: 'configure herdr', 'change herdr keybindings', 'rebind herdr prefix', 'set a herdr theme', 'tune herdr agent detection rules', 'herdr notifications/sounds', 'edit config.toml for herdr', 'write a herdr plugin', 'create herdr-plugin.toml'. Does NOT cover in-pane control CLI, session/workspace lifecycle, or the meaning of agent states."
allowed-tools: Bash, WebFetch, Read, Edit, Write, Glob, Grep
---

# herdr configuration

Make sound decisions about **how to configure and tune herdr** by editing its config file
(`~/.config/herdr/config.toml`), its agent-detection manifests, and — adjacently — by authoring
herdr's own plugins. herdr runs fine with no config; you reach for this skill when the user wants
to *change durable behavior*: keys, theme, notifications, shell/terminal policy, detection rules,
experimental features, or plugin extension.

## When to use vs. not

Use this skill when the task is about the **config file or detection manifests** — anything the
user persists to disk and applies with a reload. Do NOT use it for:

- One-off, in-pane control (split this pane, spawn an agent, read output) → vendored `herdr` skill.
- How to organize work / recover sessions / native resume *lifecycle* → `herdr-workspace-management`.
- What agent states *mean* (working / waiting / idle) → `herdr-agent-monitoring`. **You own the
  rule SYNTAX that produces those states; that sibling owns their meaning.**

## Ground yourself in live sources first

herdr ships a single Rust binary; exact key names, table names, and default values drift between
versions. **Never hand-write a default value or invent a key from memory.** Instead:

1. Generate the authoritative current config:
   `herdr --default-config` (every section, key, and default the installed build supports).
2. Confirm semantics against the docs with WebFetch:
   - https://herdr.dev/docs/configuration/
   - https://herdr.dev/docs/plugins/ (for `references/herdr-plugins.md`)
3. To start a user's config from scratch:
   `herdr --default-config > ~/.config/herdr/config.toml`

If `herdr` isn't on PATH, say so and rely on WebFetch; mark any key you can't verify as
"confirm against `herdr --default-config`."

## The edit → reload workflow (core loop)

1. Read the current `~/.config/herdr/config.toml` (create from `--default-config` if absent).
2. Make the minimal `[section]` edit — keep the user's file lean; don't paste the whole default.
3. Apply **without restarting panes**: `herdr server reload-config`.
4. For agent-detection manifest edits (separate files, see below), reload with
   `herdr server reload-agent-manifests` instead.

Always confirm the exact section/key name you're editing exists in `herdr --default-config` before
writing it.

**Safe rollback for keybindings:** `herdr config reset-keys` backs up `config.toml` and removes
custom keybindings — use it to recover from a broken `[keys]` edit without losing the rest of the
file. **Update channel:** `herdr channel show` / `herdr channel set <stable|preview>` selects which
release track `herdr update` pulls from (orthogonal to config.toml).

## Map of what's configurable (grouped)

Full per-area detail, illustrative TOML, and tuning judgment live in
**`references/config-reference.md`**. The areas:

- **Keybindings** (`[keys]`, `[[keys.command]]`) — prefix mode, direct shortcuts, special/named
  keys, custom commands. See **`references/keybindings.md`**.
- **Agent detection & labeling** — per-agent **detection manifests** (separate from config.toml).
  herdr ships bundled manifests; locate the active set and their status with
  `herdr server agent-manifests [--json]`, refresh remote ones with
  `herdr server update-agent-manifests`, and apply local edits with
  `herdr server reload-agent-manifests`. A user-override directory may not exist until you create
  one — confirm the exact override path for your version rather than assuming
  `~/.config/herdr/agent-detection/`. Plus UI-side knobs in config.toml (panel scope, label
  display, per-agent sound). See `references/config-reference.md`.
- **Themes** — built-in name + `[theme.custom]` per-color overrides.
- **Session / agent** — native session resume key, agent panel scope (all vs current workspace).
- **Notifications & sound** — toast routing (off / herdr / terminal / system), custom mp3s for
  completion/attention, per-agent sound overrides.
- **Terminal / shell** — default shell, login mode, new-pane/workspace cwd policy.
- **UI / sidebar** — sidebar width, mobile threshold, mouse capture/scroll, close confirmation,
  tab-name prompt.
- **Scrollback & history** — scrollback limit; experimental `pane_history` (stores sensitive
  terminal contents — off by default, warn the user).
- **Experimental** — nested-launch protection, kitty graphics, CJK/IME cursor tracking.
- **Worktrees / remote / update channel** — checkout directory, SSH config management, release channel.

## Decision framework: custom keybinding type

Custom command bindings go in `[[keys.command]]` with a `type`. Pick by lifecycle and target:

- **`pane`** — opens a *temporary* pane that closes when the command exits. Use for interactive,
  foreground tools the user watches then dismisses (e.g. lazygit, a REPL, `htop`).
- **`shell`** — runs *detached in the background*, no pane. Use for fire-and-forget side effects
  (sync a file, kick off a build, send a notification) where there's nothing to watch.
- **`plugin_action`** — invokes an **action declared by an installed herdr plugin** (not an
  arbitrary command). Use when the behavior is owned by a plugin and you want a key to trigger it;
  the plugin, not the keybinding, defines what runs. See `references/herdr-plugins.md`.

Rule of thumb: *watch it → `pane`; forget it → `shell`; it belongs to a plugin → `plugin_action`.*
Confirm the exact field spelling and available env vars (`HERDR_ACTIVE_PANE_CWD`, etc.) against
`herdr --default-config` and the docs.

## Boundaries (do not duplicate)

- **Vendored `herdr` skill** owns the in-pane control CLI (splitting, spawning, reading panes). You
  own the config file and detection manifests only.
- **`herdr-workspace-management`** owns session/restart/update *lifecycle* and recovery judgment,
  including native agent resume as a workflow. **You own only the config KEY that enables resume
  and the agent-panel-scope key** — point lifecycle questions there.
- **`herdr-agent-monitoring`** owns what agent states mean and how to monitor them. **You own only
  how to write/tune the detection-rule manifests** — defer state meaning there.
- Multi-agent strategy and layout design belong to their respective sibling skills.

When a request spans a boundary, do your config part and name the sibling for the rest.
