# Councils, pipelines, and manager/worker teams

Three team shapes for putting multiple agents on *related* (not disjoint) work. Pick by the
relationship between the agents. All coordination uses herdr's `agent_status` semantics
(`idle`/`working`/`blocked`/`done`/`unknown`); the raw wait/read commands live in the vendored
`herdr` skill — reference, don't restate.

## Council (parallel, then reconcile)

**Shape:** N agents independently attack the *same* problem; you or a dedicated judge agent
reconcile their answers.

**Use when:** one high-stakes, ambiguous decision is worth N× the tokens — a thorny design choice, a
bug with several plausible causes, "is this approach sound." The value is *diverse independent
takes*, so:

- Give each council member the **same prompt** but let them work in **isolation** — separate
  panes/workspaces, no shared scratch, so they don't anchor on each other.
- For genuine diversity, consider **different agent integrations** (e.g. Claude Code + Codex + one
  more) so you're not getting one model's blind spots three times. Confirm which agents are installed
  via the integrations docs / `herdr agent --help` (live).
- Wait for **all** members to reach `done`, then read each pane. Reconcile yourself, or spawn a
  **judge agent** whose only job is to read the N answers and pick/synthesize.

**Cost & failure mode:** N× tokens for one answer; members can converge on the same wrong idea if the
prompt over-constrains them. Keep prompts open enough to surface disagreement — agreement is only
signal if it was reachable independently.

## Pipeline / review chain (sequential, gated)

**Shape:** agents run in order, each consuming the prior's output. Classic: **implement → review →
fix**, or **draft → critique → revise**.

**Coordination = a chain of waits.** Each stage:
1. waits for the upstream agent to reach `done`,
2. **reads the upstream pane** (remember: `done` ≠ correct — verify before consuming),
3. does its stage,
4. signals its own `done` for the next stage.

**Routing tips:**
- Gate stages you care about on **native-reporting agents** (Claude Code, Codex, Droid, OpenCode,
  Copilot, Cursor — confirm live) so the `done` signal is trustworthy rather than screen-guessed.
- If a stage goes `blocked`, route input to it **by name** to unblock — a stalled middle stage
  freezes the whole chain.
- Keep the chain short. Every hop is a place to lose context; 2–3 stages is usually the sweet spot.

**Failure mode:** the chain is only as good as each hand-off. If the reviewer can't see what the
implementer changed (no diff, no summary), the review is theater. Make each stage emit an explicit
hand-off artifact.

## Manager / workers (orchestrated fan-out)

**Shape:** one **manager** agent spawns **workers** for disjoint slices, waits on each, and
integrates. Only the manager holds the full picture; workers see only their slice.

**When to use:** many similar subtasks (per-module migration, per-endpoint test writing) where a
human shouldn't hand-spawn each one.

**How it runs:**
- The manager uses the vendored spawn recipe with **`--no-focus`** so spawning workers doesn't yank
  the user's terminal.
- It spawns each worker into its **own container** — a fresh workspace/worktree per parallel worker
  (see fan-out-patterns.md), a sibling pane only for a tightly-coupled helper.
- It names workers so it can route to them by name and waits on each `agent_status`.
- It collects results, reads each pane (verify `done`), and integrates — typically serializing the
  merge so conflicts surface one at a time.

**Failure modes:**
- **Manager overload** — if the manager spawns more workers than it can supervise, `blocked` workers
  pile up unrouted. Cap concurrency at what the manager can actually shepherd.
- **Lost workers** — a worker that goes `unknown` (screen detection lost it) can hang the manager's
  wait. Use the agent `explain` command (confirm spelling live) to see why, and set timeouts on
  waits so the manager isn't blocked forever.
- **Over-orchestration** — for 2–3 disjoint tasks you can supervise directly, a manager agent is
  overhead. Reserve it for genuinely fan-out-heavy batches.

## Choosing between them

| You want… | Shape |
|---|---|
| Confidence on **one** hard answer | Council |
| Each step to **improve** the last | Pipeline / review chain |
| Many disjoint subtasks done **in parallel** under one coordinator | Manager / workers |
| Two or three disjoint tasks you'll watch yourself | Plain fan-out (no manager) |
