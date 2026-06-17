---
description: Set up a herdr workspace and herd a fleet of agents to work a multi-part task in parallel.
argument-hint: <task to split across agents>
allowed-tools: Bash, Read, WebFetch, Glob, Grep
---

Goal: orchestrate multiple coding agents in herdr to work on: **$ARGUMENTS**

1. First confirm you are inside herdr — check that `HERDR_ENV=1`. If it is not `1`, tell the user
   this command must run inside a herdr-managed pane and stop.
2. Use the **herdr-multi-agent** skill to decide the shape: single agent vs fan-out, and if fan-out,
   council vs pipeline vs manager/worker, plus how to divide work so agents don't collide.
3. Use the **herdr-workspace-management** skill to choose the container layout (workspace/tabs/panes),
   and the vendored **herdr** skill for the exact `workspace`/`tab`/`pane split`/`pane run` syntax to
   spawn the agents without stealing focus (`--no-focus`).
4. Assign each agent its slice of the task by name/pane, and set up any `wait` coordination
   (agent B waits on agent A) per the multi-agent skill.
5. Report the resulting layout: which agent owns what, and how the user can watch them
   (point them at `/herd-status`).

Confirm the plan with the user before spawning agents if the fan-out is non-trivial.
