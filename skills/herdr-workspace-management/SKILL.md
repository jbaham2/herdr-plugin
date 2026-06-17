---
name: herdr-workspace-management
description: "Use when organizing work in herdr or managing its sessions — choosing how to split work across workspaces, tabs, and panes; detaching and reattaching; recovering after a server restart or `herdr update`; native agent session resume; named or remote/SSH sessions; or the headless server. Covers the durable lifecycle and which-container-to-use judgment; for saving/restoring a reusable pane *layout* use herdr-layouts instead. Defers raw command syntax to the vendored herdr skill and the live `herdr` CLI. Triggers: 'my herdr agents disappeared after restart', 'reattach to herdr', 'organize this project in herdr', 'resume my herdr session', 'update herdr without losing my work'."
allowed-tools: Bash, WebFetch, Read, Glob, Grep
---

# herdr workspace & session management

Make sound decisions about **how to structure work in herdr** and **how its state survives detach,
restart, and updates**. This is the foundational mental model the other herdr skills build on.

This skill holds *judgment*. For exact command syntax, defer to:
- the vendored **`herdr` agent skill** (in-pane control: `workspace`/`tab`/`pane` create/split/read/run),
- the **live CLI** — run `herdr --help`, `herdr <group> --help`, or `herdr --default-config`,
- **WebFetch** of `https://herdr.dev/docs/cli-reference/` and `/docs/session-state/` when the binary
  isn't on PATH.
Flag names and output shapes cited below are **illustrative for judgment**, not a spec — don't
reproduce an exact invocation from memory; confirm it live before running.

## Mental model (the one thing to internalize)

herdr is **client + server**. A long-lived **server** owns your sessions, workspaces, tabs, panes,
shells, and agents. The `herdr` command is a **client** that attaches to it. Closing your terminal
detaches the client; the server keeps running. This is why agents survive you walking away — and why
"my agents are gone" almost always means *the server restarted*, not that you lost the client.

The containment hierarchy:

```
session ─▶ workspace ─▶ tab ─▶ pane
(server)   (project)    (subcontext)  (one process: shell / agent / server / logs)
```

## Decision framework: workspace vs tab vs pane

Pick the smallest container that gives the isolation you need.

| Use a… | When | Because |
|---|---|---|
| **pane** | Parallel processes in the *same* subcontext — server + its logs + a test runner | Panes share a tab; cheapest split; ideal for one feature loop |
| **tab** | A *separate subcontext* in the same project — "logs", "scratch", "review" | Tabs group panes; switch focus without losing layout |
| **workspace** | A *different project* — different repo or cwd, its own env | Workspaces isolate cwd + env; the sidebar rolls agent state up per workspace |
| **worktree** | The *same repo* but a parallel branch/checkout — esp. one per agent in a fan-out | herdr has a native `herdr worktree create --branch …` (+ `open`/`list`/`remove`) that makes the git worktree *and* wires it into herdr; strongest isolation for parallel edits. Strategy for fan-out lives in `herdr-multi-agent` |
| **named session** | A whole parallel environment you attach to deliberately (`herdr --session work`) | Separate server-side session; good for long-running remote/box setups |

Heuristics:
- One **repo** → one **workspace**. A workspace auto-labels from its first tab's root pane (usually
  the repo name), so create it with `--cwd <repo>` and let naming follow, or set `--label`.
- Don't over-split panes. More than ~4 panes in a tab and you can't read any of them — promote a
  concern to its own tab.
- Use `--no-focus` when scripting setup so you don't yank the user's focus around.

## Lifecycle: what survives what

This is the highest-value judgment in this skill. The short version:

- **Detach** (`ctrl+b q`, or just close the terminal) → everything survives, processes keep running.
  Reattach with `herdr`.
- **Server restart** → layout/panes/cwd/focus return, but **processes do not** — panes come back as
  fresh shells in their saved directories. Two opt-in features soften this: **native agent session
  restore** (on by default — eligible agents relaunch with `--resume`/`--session`) and
  **pane history replay** (off by default; stores sensitive terminal contents).
- **`herdr update`** → same as a restart unless you use **`--handoff`** (experimental), which
  transfers live processes to the new server. Handoff only works with herdr's built-in updater, not
  Homebrew/Nix.

Full persistence matrix, native-restore prerequisites, handoff caveats, and the pane-history
security warning live in **`references/sessions-and-workspaces.md`** — read it before advising a
user on recovery or updates.

## Common workflows

**"Reattach — my session/agents are still there."** `herdr` (or `herdr --session <name>`). If the
server is up, you're back instantly with live processes.

**"My agents disappeared after a reboot/restart."** The server restarted. Confirm with
`herdr status` / `herdr session list`. Layout returns; processes don't. Eligible agents auto-resume
if native restore is on and their integrations are current (`herdr integration status`). Set
expectations: a fresh shell in the right cwd is the *expected* outcome, not a bug.

**"Set up this project."** Create one workspace at the repo root, then tabs/panes per concern. Defer
the exact create/split commands to the vendored skill; this skill decides the *shape*.

**"Update herdr without losing work."** If processes must stay alive, use `herdr update --handoff`
and warn it's experimental + updater-only. Otherwise update normally and rely on native restore.

**"Run it on a remote box."** `herdr --remote <host>` attaches over SSH with local keybindings;
the server runs on the box, so your fleet persists there independent of your laptop. (See the
`herdr-multi-agent` skill for herding agents on a remote box.)

## Boundaries (do not duplicate)

- Raw `workspace`/`tab`/`pane` create/split/read/run/wait commands → **vendored `herdr` skill**.
- Designing and persisting reusable **layout trees** → `herdr-layouts`.
- **Spawning and coordinating agents** as a strategy → `herdr-multi-agent`.
- Reading/triaging **agent state** → `herdr-agent-monitoring`.
- Editing `config.toml` (keybindings, session-resume settings) → `herdr-configuration`.
