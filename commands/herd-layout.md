---
description: Save, restore, or design a reusable herdr pane/tab layout.
argument-hint: save|restore|design [name]
allowed-tools: Bash, Read, WebFetch, Glob, Grep
---

Manage a herdr layout. Request: **$ARGUMENTS**

1. Confirm `HERDR_ENV=1`; if not, say this must run inside herdr and stop.
2. Use the **herdr-layouts** skill:
   - **design** → propose a concern-driven arrangement (e.g. editor + server + logs + tests),
     respecting the legibility limit (~3–4 panes per tab; zoom vs split).
   - **save/export** → capture the current tab/workspace as a portable tree, including each pane's
     launch command and cwd (so a restore comes back as *working* state, not dead shells).
   - **restore/apply** → recreate the layout from a saved tree.
3. Confirm the exact export/apply method or CLI surface **live** (socket API docs / `herdr --help`) —
   do not assume method names. Defer raw `pane split`/`pane run` syntax to the vendored herdr skill.

Report what was saved/restored and where the layout artifact lives.
