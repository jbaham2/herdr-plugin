# herdr — Claude Code expert plugin

Makes Claude a genuine expert at [**herdr**](https://herdr.dev/docs/), the agent-aware terminal
multiplexer: herding fleets of coding agents, designing and restoring workspace/tab/pane layouts,
monitoring agent state, managing sessions, and authoring configuration.

It **vendors the official herdr agent skill** (the authoritative in-pane control reference) and
complements it with durable workflow judgment the official skill doesn't cover.

## What's inside

### Skills
| Skill | Owns |
|---|---|
| `herdr` *(vendored)* | Raw in-pane control mechanics + `HERDR_ENV=1` guard + id rules + recipes (official, AGPL) |
| `herdr-workspace-management` | Session/server lifecycle, detach/reattach, native resume, workspace-vs-tab-vs-pane organization |
| `herdr-multi-agent` | Fan-out strategy, council/team/manager-worker patterns, routing, dependency coordination, remote fleets |
| `herdr-agent-monitoring` | Detection-authority model (hooks vs screen-manifest), fleet triage, `herdr agent explain`, gotchas |
| `herdr-layouts` | Designing, exporting, and restoring reusable layout trees; declarative workspace-from-tree |
| `herdr-configuration` | Authoring `config.toml` + detection manifests: keybindings, themes, notifications, herdr-plugin authoring |

### Commands
- `/herd <task>` — set up a workspace and herd a fleet of agents on a multi-part task.
- `/herd-status` — triage the fleet: who is blocked, done, or needs attention (read-only).
- `/herd-layout save|restore|design [name]` — manage a reusable layout.
- `/herd-config <what>` — configure/tune herdr (keybindings, theme, detection rules, notifications).
- `/herd-resume` — reattach or recover a session after a restart/update.

### Agents
- `herdr-fleet-monitor` — **read-only** triage of the agent fleet.
- `herdr-orchestrator` — sets up and dispatches a fleet, wiring up handoffs.

### Hook
- `SessionStart` — if Claude is running inside herdr (`HERDR_ENV=1`), injects a short context note so
  the herdr skills engage. Emits nothing and never blocks when run outside herdr.

## Design principles

- **Vendor + complement.** The official `SKILL.md` (pinned, see `skills/herdr-agent-skill/VENDORED.md`)
  is the single source of truth for command mechanics. The complement skills hold only durable
  judgment and **defer stale-prone facts** (flags, socket method names, defaults) to the live `herdr`
  CLI and docs.
- **CLI-first + WebFetch fallback.** Skills read current facts by calling the installed `herdr`
  binary (`herdr --help`, `herdr --default-config`) and fall back to `WebFetch` of `herdr.dev/docs`
  when it isn't on PATH. **For live lookups against your running session, herdr must be installed.**

## Install

```bash
# from a clone of this repo
/plugin marketplace add /path/to/herdr-plugin
/plugin install herdr@herdr-marketplace
```

No MCP server and no auth required. The plugin is most useful when run **inside** a herdr-managed
pane (so the `herdr` CLI can talk to your running session over its local socket).

## License

This plugin is licensed **AGPL-3.0-or-later** as a whole (see `LICENSE`). It vendors the official herdr
agent skill (`skills/herdr-agent-skill/SKILL.md` + `LICENSE`), which herdr distributes under
AGPL-3.0-or-later; licensing the whole plugin AGPL avoids any redistribution conflict. Reusers must
keep derivative works open under the same terms. Provenance and the pinned upstream commit are in
`skills/herdr-agent-skill/VENDORED.md`.

## Project meta

- `meta/ROADMAP.md` — build phases and status.
- `meta/DECISIONS.md` — architecture decisions and the ownership map.
- `meta/source-tracker.md` — every source, what it taught, and where it landed.
