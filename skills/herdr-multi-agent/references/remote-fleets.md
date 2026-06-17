# Running an agent fleet on a remote box

The highest-leverage herdr setup: the **server runs on the remote box**, you attach from your
laptop. The fleet lives on the box, so it survives SSH disconnects, laptop sleep, and reconnects.
This reference is the durable judgment for that setup; raw connect/attach syntax belongs to
`herdr-workspace-management` and the live CLI.

## Why remote is the killer use case

- **Persistence.** Because the server is on the box, agents keep running when your SSH session drops.
  Reattach and the whole fleet — panes, agents, in-flight work — is still there. This is the main
  reason to herd remotely rather than locally.
- **Compute & proximity.** The box is near the code/build/test resources; your laptop is just a
  viewport.
- **Centralized fleet.** One place to see every agent's `agent_status` instead of N terminal windows.

## The durable cautions (read before scaling up)

1. **No sandboxing.** herdr does **not** sandbox agents. On a remote box with credentials, that's a
   real blast radius. Network egress, IAM scope, and what each agent can reach are **your**
   responsibility — constrain the box (least-privilege creds, egress rules) before you point a fleet
   at it.
2. **Early software.** herdr is young (0.1.x-era). Keep a fallback path (plain SSH + tmux) so a fleet
   on a shared remote box isn't your only way back to the work.
3. **Collisions are harder to see remotely.** You can't glance across windows. Lean *harder* on
   **one worktree/workspace per agent** (see fan-out-patterns.md) so isolation is structural, not
   visual.
4. **Identity over location.** With many agents you won't track pane ids over an SSH session that
   reconnects. **Name your agents** and route by name (confirm `herdr agent` syntax live) — names
   survive; pane ids compact.

## End-to-end recipe (shape, not exact flags)

1. **On the box:** install herdr and the integrations for the agents you'll run (e.g. the Claude Code
   integration). Confirm install/integration commands live (`herdr --help`, `/docs/integrations/`).
2. **Attach from your laptop** over SSH using herdr's remote-attach mode. The exact connect syntax is
   owned by `herdr-workspace-management` and the live CLI — confirm there.
3. **One worktree per slice on the box:** prefer herdr's native `herdr worktree create --branch <name>
   [--no-focus]` (verified 0.6.10) over raw `git worktree add` — it creates the worktree and wires it
   into herdr in one step. One herdr workspace per worktree.
4. **Spawn an agent per workspace** with its slice's task (vendored spawn recipe). Name each agent.
5. **Coordinate on `agent_status`** exactly as locally: wait for `done`, read before trusting,
   route to `blocked` agents by name. The signals work identically; only the latency changes.
6. **Detach freely.** Closing the laptop or dropping SSH leaves the fleet running on the box.
   Reattach to pick it back up.

## Remote-specific failure modes

- **Reconnect drift** — after a reconnect, re-read ids from `pane list` / `agent list` before acting;
  don't reuse a pane id you cached before the drop. Name-addressing sidesteps this.
- **Silent worker stalls** — a `blocked` agent you can't see waits forever for input. Periodically
  scan the fleet's statuses (that's `herdr-agent-monitoring`'s job) so blocked workers get routed.
- **Server restart on the box** — if the remote server restarts, processes don't survive (layout
  does); native session restore softens this for eligible agents. That recovery judgment lives in
  `herdr-workspace-management` — defer to it.
- **Credential sprawl** — every agent on the box inherits the box's reach. Audit before, not after.
