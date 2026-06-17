# Vendored: official herdr agent skill

`SKILL.md` and `LICENSE` in this directory are **vendored verbatim** from the upstream herdr
repository. They are not authored by this plugin and must not be edited — re-sync from upstream
instead.

| Field | Value |
|---|---|
| Upstream repo | https://github.com/ogulcancelik/herdr |
| Source file | `SKILL.md` (repo root) |
| Pinned commit | `54490254f70469cd154ee630bc4bec84da178f0c` (master, fetched 2026-06-17) |
| Raw URL | https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md |
| License | AGPL-3.0-or-later (herdr is dual-licensed; see `LICENSE`) |

## What it owns (do not duplicate elsewhere)

This skill is the **single source of truth for the raw in-pane control mechanics**:

- the `HERDR_ENV=1` safety guard (only act when running inside a herdr-managed pane);
- id formats (`1`, `1:1`, `1-1`) and the rule that ids compact — always re-read them;
- the CLI command surface for `workspace`/`tab`/`pane` create/split/read/run/send/close;
- `wait output` and `wait agent-status`;
- the canonical recipes (run-server-and-wait, run-tests, spawn-an-agent, coordinate).

Complement skills in this plugin (`herdr-workspace-management`, `herdr-multi-agent`,
`herdr-layouts`, `herdr-agent-monitoring`, `herdr-configuration`) must **defer to this skill and
to the live CLI/socket-API for command syntax**, and teach only the durable judgment the official
skill does not: session/server lifecycle, fan-out strategy, layout persistence, the
detection-authority model, and configuration.

## Re-sync procedure

```bash
curl -fsSL https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md \
  -o skills/herdr-agent-skill/SKILL.md
curl -fsSL https://raw.githubusercontent.com/ogulcancelik/herdr/master/LICENSE \
  -o skills/herdr-agent-skill/LICENSE
```

Then update the pinned commit above and review for any new commands the complement skills now
overlap with.
