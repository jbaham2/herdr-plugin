# herdr sessions, state, and recovery — durable judgment

Facts here are the *durable model*. Exact flags/output shapes are stale-prone — confirm live with
`herdr <group> --help` or `WebFetch https://herdr.dev/docs/session-state/` and `/docs/cli-reference/`.

## Persistence matrix

| What survives | Live detach | Server restart | Update w/o handoff | Update w/ handoff |
|---|---|---|---|---|
| Running processes | ✓ | ✗ | ✗ | ✓ (best effort) |
| Layout / panes / cwd / focus | ✓ | ✓ | ✓ | ✓ |
| Terminal contents | ✓ (live) | only with history replay | only with history replay | ✓ (if handoff succeeds) |
| Agent conversations | ✓ | only with native restore | only with native restore | ✓ (if handoff succeeds) |

Read the matrix as: **detach is safe; restart keeps the *shape* but not the *processes*; only handoff
keeps processes across a binary swap.**

## The four recovery mechanisms (strongest → weakest)

1. **Live persistence (detach/reattach).** `ctrl+b q` or closing the terminal detaches; the server
   and every process keep running. `herdr` reattaches. Nothing is lost. This is the normal path.
2. **Snapshot restore (server restart).** On restart herdr recovers workspaces, tabs, panes, cwd,
   layout, and focus. Processes do **not** resume — panes return as fresh shells in their saved
   directories. This is expected behavior, not a failure.
3. **Native agent session restore (on by default).** For integrated agents that report a session id,
   herdr stores the reference and relaunches the pane with e.g. `claude --resume <id>` or
   `pi --session <path-or-id>`. Prerequisites: the integration must be current
   (`herdr integration status`; update with `herdr integration install <agent>`). Stale/invalid/
   unsupported references fall back to a normal shell in the saved directory — so treat resume as
   best-effort, never guaranteed.
4. **Pane history replay (experimental, off by default).** Restores recent terminal *contents* after
   a full server restart. Disabled by default because the captured buffer can contain secrets and
   tokens. Enable via config `[experimental] pane_history = true`.

## Live handoff (experimental)

`herdr update --handoff` (or `herdr --remote <host> --handoff`) transfers running panes to a new
server instance, keeping processes alive across the replacement. Caveats:
- Opt-in and experimental; best-effort.
- Works **only** with herdr's built-in updater — not Homebrew, Nix, or other package managers.
- If handoff fails, you fall back to snapshot restore (processes gone).

When a user must not lose a long-running process across an update, handoff is the only option; if
they installed via a package manager, tell them handoff won't apply and they should drain/checkpoint
the process first.

## Security: pane history holds sensitive data

The session/pane-history directory captures everything shown in terminals — credentials, tokens,
command output. Treat it like shell history: don't enable replay on shared/untrusted machines, and
don't commit or sync the session directory.

## Organization heuristics (workspace / tab / pane)

- **One repo → one workspace.** Auto-label follows the first tab's root pane (repo name, else folder
  name). Create with `--cwd <repo>`; override with `--label` only when the auto-name is ambiguous.
- **Tabs = subcontexts** (logs, scratch, review). Promote a concern to a tab once it needs more than
  a glance.
- **Panes = co-running processes** in one subcontext (server + logs + tests). Keep it to a few;
  beyond ~4 panes nothing is legible — split into tabs instead.
- **Named sessions** for whole parallel environments you attach to deliberately (`--session <name>`),
  especially on remote boxes where the session should outlive your client.
- **`--no-focus`** whenever a script creates workspaces/tabs/panes, so automated setup doesn't steal
  the user's focus.

## Named & remote sessions

- `herdr --session <name>` attaches to (or creates) a named server-side session. Use distinct names
  to keep unrelated environments from sharing one session.
- `herdr --remote <host>` attaches over SSH with local keybindings; the server runs on the remote
  box, so the fleet persists there independent of the laptop. Combine with `--handoff` only when you
  understand the experimental caveats above.

## Recovery decision tree

1. Client gone but you didn't restart anything → just `herdr` (live reattach; everything intact).
2. Machine/server restarted, layout is back but shells are fresh → expected snapshot restore. Check
   `herdr integration status` for agents that should have auto-resumed.
3. Agents should have resumed but came back as plain shells → integration stale/unsupported, or the
   stored reference was invalid. Update integrations; some agents only report identity, not full
   state, so a manual `--resume` may be needed.
4. About to update and a process must survive → `herdr update --handoff` (if using the built-in
   updater); otherwise checkpoint first.
