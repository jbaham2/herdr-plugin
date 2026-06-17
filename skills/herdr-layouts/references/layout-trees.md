# Layout trees: task-shaped examples + the persistence workflow

This file holds depth. The durable judgment is in `SKILL.md`. Everything here that names a
**method, command, flag, or field** is **illustrative** — the shapes shown are a plausible
model of how herdr structures a layout tree, not a verified schema. **Confirm the exact
names live** before you run anything:

```bash
herdr --help
herdr pane --help
herdr workspace --help
# and the authoritative source for layout export / apply and the tree shape:
#   WebFetch https://herdr.dev/docs/socket-api/
```

If a field or command below doesn't match what the live docs / `--help` show, the live
source wins.

## How to read a layout tree

A tree describes a tab's pane arrangement as a **binary split tree (BSP)**:

- **split nodes** divide space — a `direction` (e.g. right / down), a `ratio` (how the space
  is shared), and two children (`first` / `second`).
- **pane nodes** are the leaves — each carries the things needed to *recreate* that pane:
  a working directory (`cwd`), an optional `label`, and optionally the `command` (argv) that
  pane should run on restore.

Restore/apply rebuilds the splits, re-enters each `cwd`, restores `env` and `label`, and
re-runs any recorded `command`. It does **not** bring back live PTYs, scrollback, or
processes that were already running — see "Why command capture matters" below.

## Example 1 — the feature loop (editor + server + logs + tests)

Four concerns, kept legible by putting tests in a second tab so the first tab stays at three
readable panes.

**Tab "dev"** — editor left (wide), server top-right, logs bottom-right:

```
+----------------+-------------------+
|                |   server          |
|   editor       |   (npm run dev)   |
|                +-------------------+
|                |   logs (tail -f)  |
+----------------+-------------------+
```

Illustrative tree shape for that tab:

```jsonc
// ILLUSTRATIVE — confirm field names live
{
  "tab_label": "dev",
  "root": {
    "split": {
      "direction": "right",
      "ratio": 0.6,
      "first":  { "pane": { "label": "editor", "cwd": "/repo", "command": ["nvim", "."] } },
      "second": {
        "split": {
          "direction": "down",
          "ratio": 0.5,
          "first":  { "pane": { "label": "server", "cwd": "/repo", "command": ["npm", "run", "dev"] } },
          "second": { "pane": { "label": "logs",   "cwd": "/repo", "command": ["tail", "-f", "var/log/app.log"] } }
        }
      }
    }
  }
}
```

**Tab "tests"** — a single pane you switch to (often left as a shell so you choose when to
run, or given a watch command if you want it always running):

```jsonc
// ILLUSTRATIVE
{ "tab_label": "tests", "root": { "pane": { "label": "tests", "cwd": "/repo", "command": ["npm", "test", "--", "--watch"] } } }
```

Design notes:
- Editor gets the larger `ratio` because that's where the work happens — legibility follows the work.
- Server and logs are split *within* the right half so you watch both without a fourth column.
- Tests live in their own tab: a fourth pane here would make every pane unreadable.

## Example 2 — agent + review

One pane runs an agent, a sibling pane is for you to read diffs / run ad-hoc commands. Keep
it to two panes so both stay full-height; **zoom** the diff pane when reading a long change,
then un-zoom.

```jsonc
// ILLUSTRATIVE
{
  "tab_label": "agent",
  "root": {
    "split": {
      "direction": "right",
      "ratio": 0.5,
      "first":  { "pane": { "label": "agent",  "cwd": "/repo", "command": ["claude"] } },
      "second": { "pane": { "label": "review", "cwd": "/repo" } }
    }
  }
}
```

## The export → version → restore workflow

1. **Build it live.** Use the vendored skill's `pane split` / `tab create` to reach a
   legible arrangement. Iterate with resize/swap/zoom until it reads well.

2. **Export the tab as a tree.** The capability is "export this tab's layout as a portable
   tree" — find the exact method/flag live (socket-api docs or `herdr --help`). Note that the
   export reflects each pane's `cwd` and label; whether it records the running `command`
   depends on the pane and the export — verify the exported tree actually contains the
   commands you want re-run, and add them if not.

3. **Version it.** Save the exported tree into the repo and commit it:

   ```bash
   mkdir -p .herdr/layouts
   # write the exported tree to .herdr/layouts/feature-loop.json, then:
   git add .herdr/layouts/feature-loop.json && git commit -m "Add feature-loop herdr layout"
   ```

   Now the layout is a reviewable, diffable, shareable artifact. A teammate gets the exact
   arrangement; a new machine reproduces it; a PR can change the standard dev layout.

4. **Restore it.** Apply the saved tree to a fresh tab or a new workspace (confirm the
   apply/create-from-tree method live). Because cwd and recorded commands come back, the
   server starts, logs tail, and tests watch — the layout restores into *working state*, not
   empty shells.

## Why command capture matters (set expectations correctly)

Restore reproduces **structure + labels + cwd + env + recorded argv**. It does **NOT**
restore **live terminals, scrollback, or processes that were running**.

Consequence: a tree with **no commands** restores as the right *grid of empty shells in the
right directories* — you still have to start everything by hand. A tree that **captures each
pane's launch command** restores as a layout that **re-bootstraps itself**. When you design a
reusable layout, decide per pane:

- **Service/observer panes** (server, log tail, test-watch) → **record the command** so
  restore re-runs it.
- **Interactive panes** (an editor you'll drive, a shell for ad-hoc work, an agent you may
  not always want auto-launched) → leave the command off and let it restore as a fresh shell.

This is the single highest-leverage decision in layout design: it's the difference between a
reproducible *workflow* and a reproducible *empty grid*.

## Tidying a live layout (resize / swap / move / zoom)

- **resize** — give the working pane (editor, log tail) more room; don't leave a pane too
  small to read.
- **swap** — exchange two panes' positions when the arrangement grew in the wrong order.
- **move** — relocate a pane to another tab/workspace; herdr keeps the pane's process alive
  across the move (a new public pane id is assigned). Use this to *promote* a cramped pane to
  its own tab instead of closing and restarting it.
- **zoom** — temporarily fullscreen one pane to focus; it's a view toggle and leaves the tree
  intact, so the whole arrangement comes back when you un-zoom.

Confirm each operation's exact method/flag live (pane operations in the socket API /
`herdr pane --help`).
