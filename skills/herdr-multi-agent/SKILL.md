---
name: herdr-multi-agent
description: "Use when herding a fleet of coding agents in herdr — deciding whether to run several agents in parallel vs a single agent, setting up an agent council/team, having one agent coordinate or manage others, routing input to a specific agent by name or pane, dividing work so agents don't collide, making agent B wait on agent A, spawning helper agents without stealing focus, or running a fleet on a remote box. Holds the durable judgment of multi-agent assignment; defers all raw command syntax to the vendored herdr skill and the live CLI. Triggers: 'run several agents in parallel in herdr', 'set up an agent council/team', 'have one agent coordinate others', 'herd agents on a remote box', 'split a task across multiple coding agents', 'route this to a specific agent', 'make one agent wait for another'."
allowed-tools: Bash, WebFetch, Read, Glob, Grep
---

# herdr multi-agent assignments

You decide **how to spread work across a fleet of agents in herdr** and **how to keep them
coordinated without colliding**. This skill is pure judgment: when to fan out, which team shape to
use, how to route and sequence agents, and where fleets go wrong.

This skill holds *strategy*. For exact command syntax, defer to:
- the vendored **`herdr` agent skill** (`skills/herdr-agent-skill/SKILL.md`) — it owns every raw
  `workspace`/`tab`/`pane` create/split/read/run/send command, the `HERDR_ENV=1` guard, id formats,
  the spawn-an-agent recipe (split + run `claude` + wait for `>`), and `wait output` / `wait
  agent-status`. Do not restate these here.
- the **live CLI** — run `herdr --help` and `herdr agent --help` for the higher-level agent commands
  (start / attach / list / explain / send-by-name). **Confirm their exact spelling live**; this
  skill never hardcodes them.
- **WebFetch** of `https://herdr.dev/docs/agents/`, `/docs/integrations/`, `/docs/socket-api/` when
  you need the agent model, the supported-agent matrix, or socket method names. Treat method names
  and per-agent flags as stale-prone — confirm live.

## When to use this skill

Reach for it the moment the work involves **more than one agent at once**: parallelizing a task,
standing up a review chain, putting a manager agent over workers, or routing a follow-up to one
specific agent in a busy fleet. If you're structuring a single agent's workspace, that's
`herdr-workspace-management`. If you're reading or triaging *who needs attention*, that's
`herdr-agent-monitoring`.

## Two ways to address an agent (and why it matters)

herdr lets you reach an agent **by pane id** (`1-3`) or **by agent name**. The choice is strategic:

- **Pane ids compact** when tabs/panes/workspaces close — an old `1-3` may be a different pane later.
  For one-shot, in-the-moment coordination, pane ids are fine (re-read them from `pane list` first).
- **Agent names are durable identity.** Per the agent docs, named agents "show up in `agent list`,
  can be read or sent input by agent name, can be waited on by agent state, and can be directly
  attached." For a long-lived fleet — councils, manager/worker, anything you'll route to repeatedly
  — **name your agents and address them by name.** You stop chasing renumbered pane ids.

Confirm the exact `herdr agent ...` syntax live (`herdr agent --help`). The *capability* above is
durable; the spelling is not.

## Decision framework: one agent, or many?

The discriminator is **collision risk, not task size.**

| Situation | Do this |
|---|---|
| Subtasks are **independent** and touch **disjoint files/dirs** | **Fan out** — one agent per subtask |
| Work is **coupled**, or agents would **edit the same files** | **One agent** — serialize it |
| Same repo, parallel agents | **One workspace (and ideally one git worktree) per agent** so edits can't clobber each other |
| You want **higher confidence** on one hard decision | **Council** — several agents, same problem, then reconcile |
| Output of step N **feeds** step N+1 | **Pipeline** — gate each stage on the prior agent's status |
| Many similar subtasks + a coordinator | **Manager/worker** — one agent fans out and collects |

Rule of thumb: if you can't name the **disjoint slice** each agent owns, you're not ready to fan
out. Define ownership (by directory, by file glob, by worktree) *before* spawning. Collision
avoidance is the whole game — see `references/fan-out-patterns.md`.

## The three team shapes

Pick by the *relationship* between the agents, not their count.

- **Council** — N agents independently attack the *same* problem; you (or a judge agent) reconcile
  their answers. Use for high-stakes design calls, ambiguous bugs, "which approach is right." Cost:
  N× tokens for one answer. See `references/councils-and-teams.md`.
- **Pipeline / review chain** — agents run in sequence, each consuming the prior's output (implement
  → review → fix). Coordination is a chain of waits. See `references/councils-and-teams.md`.
- **Manager / workers** — one orchestrating agent spawns workers for disjoint slices, waits on each,
  and integrates. The manager is the only agent that needs the full picture. See
  `references/councils-and-teams.md`.

## Coordination: sequence on agent_status

herdr detects a public `agent_status`: `idle`, `working`, `blocked`, `done`, `unknown`. Coordinate
on these semantics rather than scraping the screen:

- **Make B wait on A** → block on A reaching `done` before B consumes A's output. (Use the vendored
  `wait agent-status` recipe; don't restate it.)
- **`done` means *finished but not yet reviewed by you*.** It does **not** mean "correct." Always
  read the pane after `done` before feeding its output downstream — a `done` worker can be `done` and
  wrong.
- **`blocked` means the agent needs input** — a permission prompt or a question. In a fleet, a
  blocked agent is your cue to **route input to it by name** and unblock it, not to wait longer.
- **`unknown`** usually means screen detection has nothing to go on — relevant because agents that
  report lifecycle/session identity natively (e.g. Claude Code, Codex, Droid, OpenCode, Copilot,
  Cursor) give you more reliable `working`/`blocked`/`done` signals than agents herdr classifies
  purely from the screen. Prefer native-reporting agents for the legs of a pipeline you gate on.
  Confirm the current support matrix via `/docs/integrations/`; treat it as live.

When detection looks wrong (a worker stuck at `unknown`, a false `blocked`), use the agent
**`explain`** command to see how the state was decided. Confirm its exact spelling live.

**Alert the human at milestones.** A fleet that runs for a while shouldn't require the user to
babysit it. When the whole fan-out finishes, or the *first* agent goes `blocked` and needs a
decision, fire a desktop toast: `herdr notification show "<title>" [--body TEXT]
[--sound none|done|request] [--position …]` (verified herdr 0.6.10 — confirm flags live). Pair it
with the wait you already use, e.g. wait for the last worker to reach `done`, then
`herdr notification show "fleet done" --sound done`. Keep it to genuine attention points (all-done,
first-blocked), not per-step chatter.

## Spawning helpers without stealing focus

When a manager agent spawns workers, or you add a helper mid-task, use **`--no-focus`** on the
split/create so you don't yank the user's terminal around. The vendored skill's "spawn a new agent
and give it a task" recipe is the canonical sequence — reference it, don't duplicate it. The
strategy layer here: spawn into the **right container** (a fresh workspace/worktree per parallel
worker; a sibling pane only for tightly-coupled helpers).

## Remote fleets

Running a fleet on a remote box is the highest-leverage herdr use case: the **server lives on the
box**, so the fleet survives SSH drops and your laptop sleeping. Three durable cautions before you
scale up there: herdr **does not sandbox agents** (egress/IAM is your problem), it's **early
software** (keep a fallback path), and one-worktree-per-agent matters even more remotely where you
can't eyeball collisions. Full remote recipe and gotchas: `references/remote-fleets.md`.

## Boundaries (do not duplicate)

- Raw `workspace`/`tab`/`pane` create/split/read/run/send + `wait output` / `wait agent-status` +
  the spawn-an-agent and coordinate recipes → **vendored `herdr` skill**
  (`skills/herdr-agent-skill/SKILL.md`). This skill calls those; it does not respell them.
- Session lifecycle, detach/reattach, native session **restore**, per-agent `--resume`/`--session`
  flags → **`herdr-workspace-management`**.
- Reusable **layout trees** → `herdr-layouts`.
- Reading and **triaging** agent state (who needs attention now) → `herdr-agent-monitoring`.
- `config.toml`, keybindings, detection rules → `herdr-configuration`.
