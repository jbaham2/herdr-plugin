# herdr keybindings — reference

Keybindings live under `[keys]` (built-in actions) and `[[keys.command]]` (custom commands) in
`~/.config/herdr/config.toml`. Apply with `herdr server reload-config`.

**Exact action names and defaults drift.** Treat the lists below as a map of *what kinds of things
bind*, and always confirm the precise action name and current default with `herdr --default-config`.

---

## The prefix-mode model (like tmux)

herdr uses a **prefix key** (default `ctrl+b`) plus a follow-up key:

```toml
[keys]
prefix = "ctrl+b"
# an action bound to "prefix+n" means: press ctrl+b, release, then press n
```

Three binding shapes:

1. **Prefix sequences** — `"prefix+n"`. Safe for most actions; won't collide with shell input
   because they require the prefix first.
2. **Direct shortcuts** — `"ctrl+alt+n"`. Fire without the prefix. **Avoid plain single keys**
   (e.g. `"n"`) as direct shortcuts — they intercept what the user types into the shell.
3. **Mode-scoped plain keys** — navigation actions active only inside navigate/resize modes can
   safely use plain keys (`h`/`j`/`k`/`l`), since they only apply while that mode is engaged.

**Tuning judgment:** keep frequent, low-risk actions on `prefix+<letter>`; reserve direct
`ctrl+alt+…` shortcuts for a few high-frequency actions the user wants without the prefix; never
bind a bare letter outside a mode.

---

## Key syntax

- Modifiers: `ctrl`, `shift`, `alt`, `cmd`.
- Special keys: `enter`, `tab`, `esc`, `left`, `right`, `up`, `down` (confirm full set live).
- Named punctuation (because the literal char is ambiguous in TOML / hard to type as a key):
  `minus`, `comma`, `ampersand`, `plus`, `backtick`.
- Combine with `+`: `"prefix+shift+enter"`, `"ctrl+alt+minus"`.

**Indexed / ranged jumps** bind a contiguous numeric range in one entry:

```toml
[keys]
switch_tab       = "prefix+1..9"
switch_workspace = "prefix+shift+1..9"
focus_agent      = "prefix+alt+1..9"
```

Confirm whether `1..9` range syntax is supported in the installed build via `herdr --default-config`.

---

## Built-in actions (categories)

Bind these by setting the action's key under `[keys]`. The current build's exact set is in
`herdr --default-config`; broadly they cover:

- **Workspaces:** new / rename / close, navigate up/down/left/right, picker, goto, worktree creation.
- **Tabs:** new, previous/next, switch (indexed), rename, close.
- **Panes:** focus L/D/U/R, swap L/D/U/R, cycle next/previous, last-pane, split vertical/horizontal,
  close, zoom, resize-mode.
- **Modes & UI:** copy-mode, toggle-sidebar, detach.

Navigate-mode movement actions take precedence over general bindings while that mode is active.

---

## Custom command keybindings — `[[keys.command]]`

Bind a key to run a command. Each entry needs a `key`, a `type`, and a `command`
(`description` optional):

```toml
[[keys.command]]
key = "prefix+alt+g"
type = "pane"            # "pane" | "shell" | "plugin_action"
command = "lazygit"
description = "run lazygit"
```

### Choosing `type` (decision framework)

| type            | lifecycle                          | use when                                              |
|-----------------|------------------------------------|-------------------------------------------------------|
| `pane`          | temporary pane, closes on exit     | interactive tool you watch then dismiss (lazygit, REPL) |
| `shell`         | detached background, no pane       | fire-and-forget side effect (sync, build, notify)     |
| `plugin_action` | invokes an installed plugin action | behavior owned by a herdr plugin (see herdr-plugins.md) |

Mnemonic: **watch it → `pane`; forget it → `shell`; it's a plugin's job → `plugin_action`.**

### Environment available to commands

herdr injects context env vars the command can use — e.g. `HERDR_SOCKET_PATH`, `HERDR_BIN_PATH`,
`HERDR_ACTIVE_WORKSPACE_ID`, `HERDR_ACTIVE_TAB_ID`, `HERDR_ACTIVE_PANE_ID`, `HERDR_ACTIVE_PANE_CWD`.
Confirm the exact set with `herdr --default-config` / the docs before relying on one. Example using
the active pane's cwd:

```toml
[[keys.command]]
key = "prefix+alt+e"
type = "shell"
command = "code $HERDR_ACTIVE_PANE_CWD"
description = "open active pane dir in VS Code"
```

---

## Workflow

1. `herdr --default-config` → find the exact action name / confirm syntax.
2. Edit `[keys]` or add a `[[keys.command]]` block minimally.
3. `herdr server reload-config`.
4. Test the binding; if a direct shortcut swallows shell input, move it behind the prefix.
