---
name: herdr-agent-monitoring
description: "Monitors and triages a fleet of agents in herdr, and explains why a herdr agent's detected state looks wrong. Teaches the detection-AUTHORITY model (lifecycle-state hooks vs screen-manifest detection), state roll-up across pane/tab/workspace, a triage workflow for finding who needs attention, and a debugging path with `herdr agent explain`. Defers raw command syntax to the vendored herdr skill and live `herdr --help`. Triggers: 'which herdr agent needs attention', 'why does herdr show my agent as idle/blocked', 'monitor my agents status', 'an agent is stuck/blocked in herdr', 'herdr agent state is wrong / explain detection', 'is my agent done in herdr'."
allowed-tools: Bash, WebFetch, Read, Glob, Grep
---

# herdr — agent monitoring

You are watching many agents at once. The skill is reading herdr's rolled-up state correctly, trusting it where it is authoritative, and knowing when (and how) to distrust it. This is judgment, not syntax — for exact commands, defer to the live CLI and the vendored `herdr` skill.

First check `HERDR_ENV=1`. If unset, you are not inside herdr and cannot inspect its panes; say so and stop.

## When to use this skill

- "Which of my agents needs attention right now?" — triage across a fleet.
- "Why does herdr say this agent is idle/blocked/done?" — a detected state looks wrong.
- "Is the agent stuck, or just thinking?" — distinguishing `blocked` from `working`.
- Building a monitor that reacts to agents changing state.

Not this skill: organizing workspaces/tabs/panes or reattaching after restart (→ workspace-management); authoring the TOML detection rules themselves (→ herdr-configuration); raw command flags (→ vendored `herdr` skill).

## The five states

herdr exposes one public field, `agent_status`, per pane:

- **idle** — not actively processing (also the *fallback* when no rule matches; see below).
- **working** — actively running a task.
- **blocked** — needs a human: an approval, a question, a permission prompt.
- **done** — finished AND you have not looked at that pane yet. The moment you view it, it stops being `done`. So `done` is a personal to-do marker, not a durable property of the agent.
- **unknown** — herdr cannot determine state.

The other public surface is the `pane` object and a subscribable status-change event stream (use it to drive a long-lived monitor instead of polling). Confirm the exact event/method name live in /docs/socket-api/ — do not hardcode it.

## The detection-authority decision framework

Before you trust a state, ask: **does this agent's integration report lifecycle STATE for this pane?** That, not "does it have a plugin/hook," is the dividing line.

**Authority A — lifecycle-state hooks.** Some agents (e.g. Pi, OpenCode) ship integrations that push their own `idle`/`working`/`blocked` transitions. When installed and actively reporting for the running pane, the integration is the *sole authority* — herdr does not second-guess it with screen reading. Trust these states directly.

**Authority B — screen-manifest detection.** Everything else. herdr reads the live bottom of the pane buffer and evaluates TOML rules (terminal title, progress sequences, screen patterns) against it. State is inferred from what is on screen *now*.

**The trap: identity hooks are not state hooks.** Several agents — Claude Code is the canonical case, also Codex and GitHub Copilot CLI — install hooks that report session *identity* (so sessions can be restored), but NOT lifecycle state. They look integrated, yet their `idle`/`working`/`blocked` still comes entirely from screen-manifest detection. Treat them as Authority B. Do not assume "Claude Code has a hook, therefore its state is authoritative."

To classify a specific agent, don't rely on a memorized roster (it rots): check /docs/integrations/, or run `herdr agent explain` on the pane and read what it reports as the manifest/detection source.

**Why the category matters for blocked:** blocked detection is *deliberately strict* for Authority-B agents. herdr only marks `blocked` when the live bottom-buffer snapshot matches a known visible approval/question/permission UI. If nothing matches, it falls back to `idle` — never a guessed `blocked`. Consequence: an Authority-B agent waiting at a novel or unrecognized prompt can read **idle** while it is actually stuck. For Authority-A agents this gap doesn't exist; the hook reports `blocked` directly.

## State roll-up

State propagates up the tree, so the sidebar lets you triage without opening panes:

- A **blocked** agent marks its pane → tab → workspace as blocked. This is your highest-priority signal: something is waiting on a human.
- A **working** agent makes its workspace look active.
- A **done** agent stays visible until you look at it.

Read the tree top-down: a blocked workspace tells you *where* to look before you open anything.

## Triage workflow

1. **Scan the fleet.** List agents and their `agent_status` (live CLI; the vendored skill has exact syntax). You want the status column across all panes/workspaces.
2. **Sort by urgency:** `blocked` first (human needed) → `done` (review the result) → `unknown` (detection failed, investigate) → `working` (let it run) → `idle` (usually fine, but see the gotcha below).
3. **For each blocked agent**, open/attach the pane, answer the prompt, move on.
4. **For each done agent**, view it — that also clears the `done` marker.
5. **Watch the idle ones with suspicion** if they are Authority-B agents: an "idle" that should be working or blocked is the classic misdetection. Verify by reading the pane's recent output.
6. **To react continuously** rather than re-scanning, subscribe to the status-change event stream or wait on a specific status (e.g. wait for `done`) — see the vendored skill for the exact `herdr wait` / `herdr agent wait` syntax.

## When the state looks wrong — debugging path

Entry point: **`herdr agent explain <target>`** (add `--json` for machine output; it can also evaluate a captured screen offline against a named agent). Use it to see herdr's reasoning: the detected state, which manifest/source and version produced it, which rules matched, and the evidence flags. Confirm the exact flags with `herdr agent explain --help`.

Diagnose in this order:

1. **Run `herdr agent explain` on the pane.** Does the reported manifest source match the agent you think is running? If herdr is matching the wrong agent (or `tmux`), the state is being read against the wrong rules.
2. **Authority A or B?** If the explain output shows a lifecycle integration is reporting, trust that state — your eyes may be lagging the buffer. If it's screen-manifest, continue.
3. **"Stuck on idle."** Likely an unrecognized prompt: a new/unusual agent prompt reads `idle` until detection rules learn the pattern, and strict blocked-detection won't upgrade it. Read the live pane to confirm it's actually waiting. The fix is a detection rule → herdr-configuration skill.
4. **State tracks the wrong thing / lags.** Detection follows the LIVE BOTTOM BUFFER, not your scrolled viewport — scrolling through history does not change detection. Make sure you're comparing against the live bottom, not scrollback.
5. **herdr sees `tmux`, not the agent.** herdr does NOT inspect tmux sessions launched *inside* a pane; it sees `tmux` as the foreground process, so the agent inside is invisible to detection. Run the agent directly in a herdr pane instead of nesting tmux.

Full failure taxonomy and the authority table: `references/gotchas.md` and `references/detection-and-triage.md`.

## Boundaries (do not duplicate)

- **Exact command syntax** (`herdr wait agent-status`, `herdr agent ...` flags, the `agent_status` field schema) → vendored `herdr` skill (`skills/herdr-agent-skill/SKILL.md`) and `herdr --help`. Confirm live; do not memorize flags from this skill.
- **Authoring detection-rule TOML** (manifests, rule patterns) → `herdr-configuration` skill.
- **Workspace/tab/pane organization, reattach, session resume** → workspace-management skill.
- **Multi-agent strategy and layouts** → their respective sibling skills.
