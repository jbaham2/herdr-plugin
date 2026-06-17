# Authoring herdr's OWN plugins (herdr-plugin.toml)

## Two different "plugins" — don't conflate them

- **Claude Code plugin** (the thing this skill lives inside): a directory of skills/commands/agents
  that extends *Claude Code*. It uses `plugin.json` / `.claude-plugin/` and SKILL.md files.
- **herdr plugin** (this document): a directory with a **`herdr-plugin.toml`** manifest that
  extends *herdr the multiplexer* — adding actions, event hooks, panes, and link handlers that
  herdr triggers. Installed via `herdr plugin install`, not via Claude Code.

These are unrelated systems. When the user says "write a herdr plugin," they mean the
`herdr-plugin.toml` kind below. Confirm everything here against https://herdr.dev/docs/plugins/ —
manifest fields evolve.

---

## Manifest: `herdr-plugin.toml`

**Required top-level fields:**
- `id` — identifier (ASCII letters, digits, `.`, `:`, `_`, `-`).
- `name` — display name.
- `version` — semantic version.
- `min_herdr_version` — minimum herdr version supported.

**Optional:**
- `description`
- `platforms` — e.g. `["linux", "macos", "windows"]`.

```toml
id = "example.worktree-notify"
name = "Worktree Notifier"
version = "0.1.0"
min_herdr_version = "0.x.y"     # confirm a real minimum against the docs / a release
description = "Notify when a worktree is created"
platforms = ["linux", "macos"]
```

---

## Declarable components

### Actions — `[[actions]]`
A named, invokable behavior.

```toml
[[actions]]
id = "open-dashboard"        # local id, no dots
title = "Open Dashboard"
contexts = ["workspace"]     # invocation context(s)
command = ["my-script", "--flag"]   # argv array, not a shell string
platforms = ["linux"]        # optional per-action override
```

Actions are what a `plugin_action` keybinding (see keybindings.md) targets, and what link handlers
reference.

### Event hooks — `[[events]]`
Run a command automatically when a herdr event fires.

```toml
[[events]]
on = "worktree.created"      # event name; confirm the full event list in the docs
command = ["herdr", "..."]
```

`worktree.created` is the documented example. **Do not invent other event names** — enumerate the
supported events from https://herdr.dev/docs/plugins/ before using one.

### Panes — `[[panes]]`
A pane the plugin can open.

```toml
[[panes]]
id = "logs"
title = "Logs"
placement = "overlay"        # overlay | split | tab | zoomed
command = ["tail", "-f", "app.log"]
```

### Link handlers — `[[link_handlers]]`
Handle Ctrl/modified-click on URLs matching a regex by invoking a declared action.

```toml
[[link_handlers]]
id = "jira"
title = "Open in Jira"
pattern = "^https://jira\\."   # Rust regex
action = "open-dashboard"      # must reference a declared [[actions]] id
```

### Build commands — `[[build]]` (optional)
Run during `herdr plugin install` (from GitHub) after confirmation, before registration. They do
**not** run during `herdr plugin link` (local dev).

```toml
[[build]]
command = ["npm", "ci"]
platforms = ["linux", "macos"]
```

---

## How plugins are triggered

1. **Keybindings** — a `[[keys.command]]` of `type = "plugin_action"` invokes an action.
2. **Events** — `[[events]]` hooks fire automatically (e.g. `worktree.created`).
3. **Modified-click (Ctrl)** — `[[link_handlers]]` match terminal URLs.
4. **CLI** — `herdr plugin action invoke …`.

## Runtime environment injected by herdr

Commands receive: `HERDR_SOCKET_PATH`, `HERDR_BIN_PATH`, `HERDR_ENV`, `HERDR_PLUGIN_ID`,
`HERDR_PLUGIN_ROOT`, `HERDR_PLUGIN_CONFIG_DIR`, `HERDR_PLUGIN_STATE_DIR`,
`HERDR_PLUGIN_CONTEXT_JSON`, plus context-dependent vars: `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`,
`HERDR_PANE_ID`; `HERDR_PLUGIN_ACTION_ID` (actions); `HERDR_PLUGIN_EVENT` /
`HERDR_PLUGIN_EVENT_JSON` (hooks); `HERDR_PLUGIN_ENTRYPOINT_ID` (panes). Confirm the current set
against the docs.

---

## Directory & distribution

A minimal plugin directory: `herdr-plugin.toml` plus any referenced scripts/binaries.

- **Local development:** `herdr plugin link <dir>` (does not run `[[build]]`).
- **Distribution:** publish to a GitHub repo tagged with the **`herdr-plugin`** topic.
- **Install:** `herdr plugin install owner/repo[/subdir]` (runs `[[build]]` after confirmation).

---

## Authoring checklist

- [ ] `herdr-plugin.toml` has all four required fields (`id`, `name`, `version`, `min_herdr_version`).
- [ ] `command` values are argv arrays, not shell strings.
- [ ] Every `link_handlers.action` references a real `[[actions]].id`.
- [ ] Event names verified against the docs — none invented.
- [ ] Tested locally with `herdr plugin link` before publishing.
- [ ] Repo tagged `herdr-plugin` for discovery.
- [ ] Reconciled all field names against https://herdr.dev/docs/plugins/.
