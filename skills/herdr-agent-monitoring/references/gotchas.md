# Misdetection gotchas — failure taxonomy

Companion to SKILL.md. Each entry: the symptom, why it happens, and how to confirm/fix. The debugging entry point is always `herdr agent explain <target>` (confirm exact flags with `herdr agent explain --help`; `--json` available). Detection-rule changes belong to the herdr-configuration skill.

## 1. Agent reads `idle` but is actually waiting on a prompt

**Symptom:** an agent at a question/approval shows `idle`, not `blocked`.
**Why:** blocked detection is *deliberately strict* for screen-manifest (Authority-B) agents. herdr only marks `blocked` when the live bottom-buffer snapshot matches a known visible approval/question/permission UI. A new or unusual prompt that no rule recognizes does NOT get a guessed `blocked` — it falls back to `idle`. This is by design (it prevents false-positive blocks), but it means novel prompts read idle until a detection rule learns the pattern.
**Confirm:** read the live pane; `herdr agent explain` will show no blocking rule matched.
**Fix:** add/extend a detection rule → herdr-configuration. Authority-A (lifecycle-state) agents don't have this gap — their hook reports `blocked` directly.

## 2. herdr sees `tmux` instead of the agent

**Symptom:** the pane's detected process is `tmux`; the agent inside is invisible, state is `unknown`/`idle`.
**Why:** herdr does NOT inspect tmux sessions launched *inside* a pane. It sees `tmux` as the foreground process and never reaches the agent running within it.
**Fix:** run the agent directly in a herdr pane. Don't nest a tmux session inside a herdr pane and expect detection to see through it. (herdr is itself the multiplexer — nesting tmux defeats it.)

## 3. State seems to track the wrong screen / lags while you scroll

**Symptom:** you scroll up through history and the state doesn't reflect what you're looking at, or seems "behind."
**Why:** detection follows the **live bottom buffer**, not your scrolled viewport. Scrolling through scrollback never changes detection — herdr always evaluates the recent bottom of the buffer.
**Fix:** compare detection against the live bottom, not scrollback. This is correct behavior, not a bug.

## 4. Wrong-agent manifest matched

**Symptom:** state is consistently wrong, or `herdr agent explain` shows a manifest source for a different agent than the one running.
**Why:** the screen patterns matched another agent's manifest (similar prompts/titles), or the wrong agent label is associated with the pane.
**Confirm:** `herdr agent explain` — check the reported manifest source/version and matched rules against the agent you believe is running.
**Fix:** correct the agent association, or refine the rule so it doesn't over-match → herdr-configuration.

## 5. "Has a hook, so its state must be authoritative" — false

**Symptom:** you assume Claude Code / Codex / Copilot CLI report their own state because they have integrations, then are surprised when state lags or misreads.
**Why:** those hooks report session **identity** (for restore), not lifecycle **state**. State still comes from screen-manifest detection (Authority B), with all of B's gotchas above.
**Fix:** classify by whether the integration reports STATE, not whether a hook exists. `herdr agent explain` shows the actual detection source. See detection-and-triage.md.

## 6. `done` "disappeared"

**Symptom:** a pane showed `done`, now it doesn't.
**Why:** not a bug. `done` means finished AND unseen by you. Viewing the pane clears the marker — it is a personal to-do flag, not a durable agent property. If you need a durable "this finished" signal for automation, wait on / subscribe to the status event instead of relying on the visible `done` flag.

## 7. `pane read --source recent` comes back EMPTY on a fresh/short pane

**Symptom:** you read a pane to check on an agent and `--source recent` (or `recent-unwrapped`)
returns nothing, so you wrongly conclude the pane is empty or the agent did nothing.
**Why:** `recent` is **scrollback** — text that has scrolled *out* of the visible viewport. A
newly-spawned or short-lived pane whose output still fits on screen has an empty scrollback; the
content is in the **visible** buffer. (Verified live, herdr 0.6.10: on a fresh pane `--source
visible` returned the screen while `--source recent`/`recent-unwrapped` returned 0 bytes.)
**Fix:** use **`--source visible`** to read what's currently on screen (the right choice for a
quick "what does this pane show now" check); reserve `--source recent` for long-running panes where
you specifically want scrolled-off history. Note `herdr wait output` matches against the recent
*unwrapped* transcript and returns the matched text even when a standalone `recent` read is empty —
so prefer `wait output` for "block until expected text appears," and `pane read --source visible`
for "show me the current screen."

## Quick reference: confirm-live, don't memorize

- Exact `herdr agent explain` flags → `herdr agent explain --help`.
- Which agents are Authority A vs B → /docs/integrations/ or `herdr agent explain` output (the roster changes).
- Event/subscription method names for monitors → /docs/socket-api/.
- The `herdr wait` / `herdr agent wait` status set and syntax → `herdr --help` and the vendored `herdr` skill.
