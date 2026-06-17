---
description: Triage your herdr agent fleet — find which agents are blocked, done, or need attention.
allowed-tools: Bash, Read, WebFetch, Glob, Grep
---

Triage the agents in the current herdr session.

1. Confirm `HERDR_ENV=1`; if not, say this must run inside herdr and stop.
2. Use the **herdr-agent-monitoring** skill to:
   - read the current agents and their `agent_status` (idle / working / blocked / done / unknown),
   - apply the triage priority order (blocked first, then done-but-unreviewed, then stuck-working),
   - for any agent whose state looks wrong, run the `herdr agent explain` debugging path and
     classify whether it's a hook-authority or screen-detected agent.
3. Report a short ranked list: **who needs attention now and why**, with the pane to attach to.

Read-only: inspect and report. Do not send input or restart agents unless the user asks.
