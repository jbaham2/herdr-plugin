# herdr config.toml — reference by area

All exact key names and **default values drift between versions**. The TOML below is
**illustrative of structure**, not a source of truth for defaults. Always cross-check the spelling
of a section/key and its current default with `herdr --default-config`, and confirm semantics at
https://herdr.dev/docs/configuration/. Where this file says "confirm live," it means the exact
spelling/default was not verifiable at authoring time.

Apply config edits with `herdr server reload-config` (no pane restart). Apply agent-detection
manifest edits with `herdr server reload-agent-manifests`.

---

## Themes — `[theme]`, `[theme.custom]`

```toml
[theme]
name = "catppuccin"   # built-in theme name
```

Built-ins seen in docs include catppuccin (+ latte), tokyo-night (+ day), dracula, nord, gruvbox
(+ light), one-dark / one-light, solarized (+ light), kanagawa (+ lotus), rose-pine (+ dawn),
vesper, terminal. **Confirm the exact available list with `herdr --default-config`** — it changes.

Per-color overrides layer on top of the named theme:

```toml
[theme.custom]
accent = "#a6e3a1"
green  = "#a6e3a1"
blue   = "#89b4fa"
# panel_bg = "reset"
```

Color formats: hex, named colors, `rgb(r,g,b)`, and reset aliases (`reset`, `default`, `none`,
`transparent`). The exact set of overridable color slots is build-specific — enumerate them from
`herdr --default-config`, don't guess slot names.

**Judgment:** prefer a built-in name; reach for `[theme.custom]` only to fix specific clashes
(e.g. an accent that's illegible on the user's terminal background). Override the fewest slots.

---

## Agent detection & labeling

Two distinct layers — keep them straight.

### 1. Detection RULES (separate manifest files)

State classification rules do **not** live in config.toml. They live in per-agent **detection
manifests**, which herdr ships bundled. Verified commands (herdr 0.6.10):

- `herdr server agent-manifests [--json]` — show the active manifests and their status (use this
  to **locate** them; do not assume a fixed path — `~/.config/herdr/agent-detection/` may not exist
  until you create a local override, and the exact override location can vary by version).
- `herdr server update-agent-manifests` — fetch and reload the remote manifests.
- `herdr server reload-agent-manifests` — reload after a local edit.

- A local override file **fully replaces** the bundled manifest for that agent; invalid files are
  ignored and herdr falls back to the cached/bundled version.

Manifests classify states (docs cite `idle`, `working`, `blocked`) by matching against:
- the bottom screen buffer (not the scrolled-back viewport),
- terminal title sequences,
- progress / OSC sequences.

**The exact manifest schema (top-level fields, rule table names, per-rule fields like state /
match / source / priority) is not fully published.** To tune rules safely:

1. Start from a real manifest, never a blank invention. Locate the bundled/active one for the
   target agent with `herdr server agent-manifests` (and the docs at
   https://herdr.dev/docs/agents/ and https://herdr.dev/docs/integrations/).
2. Copy it to the local override location, edit minimally (tighten or add one pattern), keep the rest.
3. `herdr server reload-agent-manifests` and observe; if the file is rejected, herdr silently
   falls back — re-check syntax.
4. **Do not invent table/field names.** If you can't read an example, tell the user the schema must
   be confirmed against a bundled manifest or the live docs before editing.

Defer the *meaning* of `idle`/`working`/`blocked` and how to act on them to the
`herdr-agent-monitoring` skill.

### 2. UI-side agent knobs (in config.toml)

```toml
[ui]
agent_panel_scope = "all"                 # "all" or "current" workspace
show_agent_labels_on_pane_borders = false

[session]
resume_agents_on_restore = true           # native session resume — KEY only; lifecycle judgment lives in herdr-workspace-management
```

`agent_panel_scope = "current"` declutters the agent panel to the active workspace. Confirm exact
key spellings live.

---

## Notifications & sound — `[ui.toast]`, `[ui.sound]`

```toml
[ui.toast]
delivery = "off"          # "off" | "herdr" | "terminal" | "system"
# delay_seconds = 1

[ui.toast.herdr]
position = "bottom-right" # when delivery = "herdr"

[ui.sound]
enabled = true
# done_path    = "sounds/done.mp3"      # completion sound
# request_path = "sounds/request.mp3"   # attention / needs-input sound

[ui.sound.agents]
# per-agent override: "default" | "on" | "off"
# claude = "on"
# droid  = "off"
```

**Judgment on toast routing:**
- `off` — user watches herdr directly, no interruptions.
- `herdr` — toast inside herdr's own UI; good when herdr is the focused window.
- `terminal` — emit to the host terminal's bell/notification path.
- `system` — OS-level notifications; best when herdr is backgrounded and the user multitasks.

Custom mp3s: point `done_path` / `request_path` at the user's files for distinct completion vs.
attention cues. Per-agent overrides mute noisy agents (e.g. a frequently-pinging one) while keeping
others audible. `HERDR_DISABLE_SOUND` env var kills sound globally. Confirm exact key names live.

---

## Terminal & shell — `[terminal]`

```toml
[terminal]
default_shell = "nu"      # executable for new interactive panes; unset → $SHELL then /bin/sh
shell_mode = "auto"       # "auto" | "login" | "non_login"
new_cwd = "follow"        # "follow" | "home" | "current" | a fixed path
```

- `shell_mode = "auto"` typically means login shells on macOS, non-login elsewhere — confirm.
- `new_cwd = "follow"` inherits the source pane/workspace cwd (falls back to `$HOME`); use `home`
  for a clean start every time, or a fixed path to pin new panes to a project root.

---

## UI / sidebar — `[ui]`

```toml
[ui]
# sidebar_width = 32
# sidebar_min_width = 18
# sidebar_max_width = 36
# mobile_width_threshold = 64
# mouse_capture = true
# mouse_scroll_lines = 3
# confirm_close = true          # confirm before closing
# prompt_new_tab_name = true    # ask for a tab name on new tab
```

**Do not state these numbers as fact** — list them only as the knobs that exist and read current
defaults from `herdr --default-config`. `mobile_width_threshold` collapses the sidebar below a
terminal width; `mouse_capture = false` hands scroll/selection back to the host terminal.

---

## Scrollback & history — `[advanced]`, `[experimental]`

```toml
[advanced]
# scrollback_limit_bytes = ...   # confirm default live
```

```toml
[experimental]
pane_history = false   # OFF by default — persists pane CONTENTS across restarts
```

**Warn the user before enabling `pane_history`:** it writes terminal contents (which may include
secrets, tokens, command output) to disk. Only enable when the convenience of restored scrollback
outweighs storing sensitive screen data.

---

## Experimental — `[experimental]`

```toml
[experimental]
allow_nested = false              # nested-launch protection; true allows herdr inside herdr
kitty_graphics = false            # kitty graphics protocol support
# reveal_hidden_cursor_for_cjk_ime = false
# cjk_ime_agents = []             # allow-list of agents for IME cursor tracking
pane_history = false
```

These are opt-in and may change or be promoted/removed between versions — always reconcile against
`herdr --default-config` and the docs before recommending one.

---

## Worktrees / remote / update — `[worktrees]`, `[remote]`, `[update]`

```toml
[worktrees]
# directory = "~/.herdr/worktrees"   # checkouts: <dir>/<repo>/<branch-slug>

[remote]
# manage_ssh_config = true           # herdr-managed SSH keepalive fallbacks

[update]
# channel = "stable"                 # "stable" | "preview"
```

---

## Quick checklist before writing any config edit

- [ ] Confirmed the section + key exists in `herdr --default-config`.
- [ ] Edited minimally — didn't paste whole defaults into the user's file.
- [ ] Did not assert a default *value* from memory.
- [ ] Reloaded: `herdr server reload-config` (or `reload-agent-manifests` for detection files).
- [ ] Routed lifecycle/state-meaning questions to the correct sibling skill.
