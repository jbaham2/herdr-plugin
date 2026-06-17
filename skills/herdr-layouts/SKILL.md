---
name: herdr-layouts
description: "Use when designing, saving, or reproducing a pane/tab arrangement in herdr — 'save/restore my herdr layout', 'set up a reusable pane layout in herdr', 'recreate this workspace layout', 'export a herdr layout tree', 'declarative workspace setup in herdr', or capturing an editor+server+logs+tests arrangement as a shareable, reproducible artifact. Also covers the judgment around resize/swap/move/zoom for legibility. Use this skill to arrange, save, or reproduce panes *now*; for session lifecycle, recovery, and which-container-to-use judgment use herdr-workspace-management. Defers raw command syntax to the vendored herdr skill and the live socket API; defers keybindings to herdr-configuration."
allowed-tools: Bash, WebFetch, Read, Glob, Grep
---

# herdr layouts

You design **reusable pane/tab arrangements** for a task, and you treat a layout as a
**portable, versionable artifact** — export it as a tree, commit it, restore it later or
hand it to a teammate. This skill holds the *design and persistence judgment*. It does
**not** restate per-command syntax.

For exact method names, flags, and JSON shapes, defer to:
- the vendored **`herdr` agent skill** (`pane split` / `tab create` / `workspace create`, `pane read/run`),
- the **live socket API** — `WebFetch https://herdr.dev/docs/socket-api/`,
- the **live CLI** — `herdr --help`, `herdr pane --help`, `herdr workspace --help`.

Never hardcode a method, command, or field name from memory — confirm it live before you run it.

## When to use this skill

- "Save / export this layout so I can get it back."
- "Recreate the layout I had yesterday" or "set this up the same way on another machine."
- "Set up a reusable layout for working on <task>" (editor + server + logs + tests).
- "Make this workspace reproducible / shareable."
- Deciding **zoom vs. split**, or cleaning up a cramped tab with resize/swap/move.

Not this skill: detaching/reattaching, server-restart recovery, `herdr update` → **herdr-workspace-management**.
Pane-navigation keybindings → **herdr-configuration**. Spawning/coordinating agents → the multi-agent sibling.

## Design framework: what panes/tabs does a task need?

Start from the *concerns* the task runs in parallel, not from a pretty grid. A typical
feature loop has four: **edit**, **run** (server/build), **observe** (logs), **verify**
(tests). Map each concern to the smallest container that isolates it:

- Concerns that share a working directory and you watch *together* → **panes in one tab**
  (editor + server + logs).
- A concern you switch to deliberately and don't need on screen constantly → its **own tab**
  ("tests", "scratch", "review", "db shell").
- A different repo / cwd / env → a **separate workspace**.

**Legibility is a hard constraint.** More than ~3-4 panes in one tab and none of them are
readable — a log pane squeezed to 6 lines tells you nothing. When a tab gets crowded,
**promote a concern to its own tab** instead of splitting again. A good layout is one you
can actually read at a glance.

### Zoom vs. split

- **Split** when you need to *watch two things at once* (server output while editing, logs
  while tests run). The value is simultaneity.
- **Zoom** (temporarily fullscreen one pane) when you need to *focus deeply* on one pane for
  a while — reading a long diff, scrolling a stack trace — without destroying the layout.
  Zoom is a view toggle; it doesn't change the underlying tree, so un-zoom restores everything.
- Reach for **resize** to give the pane doing the work more room (e.g. a wide editor, a tall
  log tail); use **swap/move** to fix an arrangement that grew awkwardly rather than tearing
  it down and rebuilding.

Confirm the exact zoom/resize/swap/move method or flag live — they live under the pane
operations in the socket API / `herdr pane --help`.

## Layouts as portable artifacts: export → version → restore

The core capability: herdr can **read the current pane/tab arrangement as a tree** and you
reproduce it by **rebuilding the splits** (optionally re-running each pane's command), giving
you a multi-pane setup with **working directories preserved**.

What's verified in the CLI (herdr 0.6.10): `herdr pane layout [--pane ID|--current]` prints
the current layout tree. There is **no first-class CLI "export to file / apply from file"
command** in this version — so "restore a layout" means **scripting the rebuild** (a sequence
of `pane split` + `pane run` from your saved tree), or using a socket-API apply method **if
one exists in your version**. Confirm the live surface (`herdr pane --help`, socket-api docs)
before assuming a one-shot apply; treat any apply/import method name as illustrative until verified.

**The one fact that drives all the design judgment:** restoring a tree reproduces the
**structure, pane labels, working directory (cwd), and environment** — and, if the tree
records them, each pane's **launch command (argv)**. It does **NOT** revive live terminals,
scrollback, or already-running processes. A restored layout is a **re-runnable skeleton**,
not a frozen snapshot.

So the difference between a layout that restores into *useful work* and one that restores
into *dead shells* is whether the tree **captures each pane's command**:

- A pane that should run the dev server → record its command (e.g. `npm run dev`) in the tree.
- A pane tailing logs → record the tail/`pane run` command.
- A pane that's just an interactive shell → no command; it restores as a fresh shell in the
  right cwd, which is correct.

Workflow:

1. **Design** the arrangement live (split/tab/zoom) until it's legible and matches the task's concerns.
2. **Capture** the arrangement: read it with `herdr pane layout` and record, alongside each
   pane, the **command it should run** on rebuild (the part the raw tree won't infer for you).
3. **Version** it: save that captured layout-plus-commands to a file in the repo (e.g.
   `.herdr/layouts/feature-loop.json` or a small setup script) and commit it. Now the layout is
   reviewable, diffable, and shareable like any other config.
4. **Rebuild** from the saved file — script the `pane split`/`pane run` sequence (or a socket-API
   apply if your version exposes one) into a fresh tab or new workspace. Because cwd and recorded
   commands come back, the server/logs/tests re-bootstrap themselves instead of leaving you to
   re-run everything by hand.

This is also the right tool for **server-restart recovery of a layout's *shape*** — but the
"will my running processes survive?" question belongs to **herdr-workspace-management**; this
skill only owns reproducing the arrangement.

## The declarative-tree pattern

Rather than scripting a sequence of `pane split` / `tab create` calls, describe the desired
end state as a **tree** and let herdr build it in one apply. A tree is nested **split** nodes
(each with a direction and a ratio) bottoming out in **pane** nodes (each with cwd, optional
label, optional command). Confirm the exact field names live; see
`references/layout-trees.md` for an *illustrative* shape and worked examples.

Prefer the declarative tree over imperative splits when:

- You want the setup to be **idempotent and reviewable** (a file in git vs. a brittle script).
- You're reproducing a **known-good** arrangement (your standard feature loop) rather than exploring.
- You're handing the setup to **someone else** or **another machine** — the tree is the contract.

Use imperative `pane split` / `tab create` (vendored skill) when you're *exploring* what
arrangement you even want, or making a one-off adjustment to a live tab.

## Boundaries (do not duplicate)

- Raw `pane split` / `tab create` / `workspace create` / `pane read` / `pane run` syntax → **vendored `herdr` skill** + live socket API. Don't restate flags here.
- Exact layout-export / apply method names and tree JSON field names → **confirm live** (socket-api docs, `herdr --help`); treated as illustrative-only in this skill.
- Detach/reattach, server-restart & `herdr update` recovery, *whether processes survive* → **herdr-workspace-management**.
- Pane-navigation keybindings (how to move focus between panes) → **herdr-configuration**.
- Spawning/coordinating multiple agents as a strategy → the multi-agent sibling.
- Reading/triaging agent status → the agent-monitoring sibling.
