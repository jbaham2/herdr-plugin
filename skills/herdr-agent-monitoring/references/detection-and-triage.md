# Detection authority and triage — reference

Companion to SKILL.md. Depth on the two detection authorities, how to classify an agent, and the public surfaces you triage from. Exact command flags and event names are stale-prone — confirm them via `herdr --help`, the vendored `herdr` skill, and a live WebFetch of https://herdr.dev/docs/agents/ and https://herdr.dev/docs/socket-api/.

## The two authorities, restated

| | Authority A: lifecycle-state hooks | Authority B: screen-manifest detection |
|---|---|---|
| Source of state | The agent's integration pushes its own state transitions | herdr reads the live bottom of the pane buffer and evaluates TOML rules |
| Authoritative? | Yes — sole authority when installed and actively reporting for the running pane; herdr does not override it with screen reading | No — state is inferred from on-screen text |
| `blocked` reliability | Direct from the hook; no strictness gap | Deliberately strict: only when the live snapshot matches known approval/question/permission UI, else falls back to `idle` |
| Failure mode | Integration not installed / not reporting → falls back to B | Novel prompt unrecognized → reads `idle` while actually stuck |

## Classify an agent — don't trust a memorized roster

The set of integrations and which category each falls into changes over time. Determine it live, two ways:

1. **Read /docs/integrations/.** It separates agents that report lifecycle state via hooks/plugins (Authority A) from agents that only report session *identity* for restore (Authority B — their state still comes from screen detection).
2. **Run `herdr agent explain <target>`** and read the reported manifest/detection source. If a lifecycle integration is the source, it's Authority A for that pane; if a screen manifest is the source, it's Authority B.

### The identity-vs-state trap (most important)

An agent having a hook does NOT make it Authority A. The decisive question is whether the hook carries lifecycle **state** or only session **identity**.

- **State hooks** (Authority A): push `idle`/`working`/`blocked` transitions. Example named in the brief: Pi, OpenCode.
- **Identity hooks** (Authority B): report a session reference so the session can be restored later, but do not report lifecycle state. **Claude Code is the canonical example** — also Codex and GitHub Copilot CLI. They look integrated; their state is still screen-detected.

> Integrated agents in herdr 0.6.10 (from `herdr integration install`): **pi, omp, claude, codex,
> copilot, droid, kimi, opencode, kilo, hermes, qodercli, cursor**. IMPORTANT: that list only tells
> you an agent is *integrated* — it does **not** give its authority category. Installable ≠ state-hook;
> e.g. Claude Code and Copilot integrate but are identity-only (Authority B), still screen-detected for
> state. Don't infer category from this list — classify a specific agent live with
> `herdr agent explain <target>` and `herdr server agent-manifests`. The roster is version-specific.

## What you triage from (public surfaces)

- **`agent_status` per pane** — the one public state field: `idle | working | blocked | done | unknown`.
- **The `pane` object** — returned by pane queries; carries `agent_status` among other fields.
- **A status-change event stream** — subscribe for a long-lived monitor instead of polling, so you react the instant an agent goes `blocked` or `done`. The exact subscription method/event name lives in /docs/socket-api/; confirm live rather than hardcoding it.
- **Two distinct wait commands** (verified herdr 0.6.10) — pick by whether you need `done`:
  - `herdr agent wait <target> --status <idle|working|blocked|unknown>` — **no `done`**.
  - `herdr wait agent-status <pane> --status <idle|working|blocked|done|unknown>` — **includes `done`**.
  So to block until an agent finishes, use `herdr wait agent-status … --status done`. Re-confirm with
  `herdr --help` on other versions.

## Triage priority order

1. **blocked** — a human is needed; resolve first. Rolls up to mark its tab and workspace.
2. **done** — finished and unseen; review it (viewing clears the marker).
3. **unknown** — detection failed; `herdr agent explain` to find out why.
4. **working** — healthy; leave it.
5. **idle** — usually fine. But for Authority-B agents, a wrong `idle` is the classic misdetection — verify by reading recent pane output if you expected work or a prompt.

## Roll-up mechanics

State climbs pane → tab → workspace:

- One **blocked** pane marks its tab and workspace blocked — so the sidebar shows you *where* attention is needed without opening panes.
- A **working** pane makes its workspace look active.
- A **done** pane stays flagged until viewed.

Read top-down: let the workspace/tab indicators route you to the pane.

## Becoming a state authority (custom integrations: `pane report-agent`)

The flip side of the authority model: if an agent (or a wrapper script) **reports its own state**,
it becomes **Authority A** for that pane and herdr stops guessing from the screen. This is how you
fix a chronically-misdetected agent — make it report instead of relying on screen-manifest rules.

Verified CLI surface (herdr 0.6.10) — confirm flags live with `herdr pane --help`:

- `herdr pane report-agent <pane> --source ID --agent LABEL --state idle|working|blocked|unknown
  [--message TEXT] [--custom-status TEXT] [--agent-session-id ID] [--agent-session-path PATH] [--seq N]`
  — push a lifecycle-state transition (and optionally a session reference for native restore).
- `herdr pane report-agent-session <pane> --source ID --agent LABEL [--agent-session-id ID] …`
  — report only session **identity** (Authority B: enables `--resume` restore, state stays screen-detected).
- `herdr pane report-metadata <pane> --source ID [--title …] [--display-agent …] [--custom-status …]
  [--state-label STATUS=TEXT] [--ttl-ms N]` — override display labels / custom status text.
- `herdr pane release-agent <pane> --source ID --agent LABEL` — relinquish authority for that pane.

Judgment: use `report-agent --state` when your tool *knows* its lifecycle (hook into its own
start/stop/await events) — that's strictly better than tuning screen-manifest rules. Use
`report-agent-session` alone when you can only supply a resumable session id. `--seq` orders updates;
send monotonically increasing values so out-of-order reports don't regress state. To author or tune
the *screen-manifest* rules instead (for agents you can't modify), see the `herdr-configuration` skill.
