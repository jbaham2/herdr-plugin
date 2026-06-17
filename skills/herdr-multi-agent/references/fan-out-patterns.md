# Fan-out patterns: parallelizing agents without collisions

The single hardest part of running parallel agents in one repo is **stopping them from clobbering
each other's edits**. Everything below is about defining ownership *before* you spawn.

## The collision-avoidance ladder (strongest isolation first)

1. **One git worktree per agent** — the strongest isolation, and the pattern the coles.codes
   case study leads with. Each agent gets its own checkout of a branch, so two agents editing the
   "same" file edit different working copies. You merge/rebase at the end. Map **one herdr
   workspace per worktree** so the fleet is visually one-agent-per-workspace.
   herdr has a **native worktree command group** (verified 0.6.10) so you don't drop to raw git:
   `herdr worktree create [--workspace ID|--cwd PATH] [--branch NAME] [--base REF] [--path PATH]
   [--label TEXT] [--no-focus]`, plus `worktree open|list|remove`. It creates the worktree *and*
   wires it into herdr, and emits a `worktree.created` event plugins can hook. Confirm exact flags
   live (`herdr worktree --help`); prefer it over manual `git worktree add` when inside herdr.
2. **Disjoint directory ownership** — agents share one checkout but each owns a non-overlapping
   subtree (`agent A: src/api/`, `agent B: src/web/`). Cheaper than worktrees; safe only if the
   subtrees truly don't cross-import-edit.
3. **Disjoint file globs within a shared dir** — finer-grained, more fragile. Only when you can
   enumerate exactly which files each agent may touch and they don't overlap.
4. **Serialize** — if you can't carve a clean slice, **don't fan out.** Run one agent. Coupled work
   (shared schema, intertwined refactor) is faster correct-on-the-first-try than fast-and-conflicted.

If you cannot state, in one sentence, the slice each agent owns, stop and either subdivide
differently or serialize.

## Setup shape (defer syntax to the vendored skill)

For a worktree-per-agent fan-out:

1. Create the worktrees with `herdr worktree create --branch <slice> [--no-focus]` (one per
   branch/slice) — herdr's native command, which both makes the worktree and wires it into herdr.
   See **Worktree discipline** below before creating.
2. For each, create a herdr **workspace** at that worktree's path (`--no-focus` so setup doesn't
   yank focus) — or let `herdr worktree create` place it; the vendored skill owns the
   `workspace create --cwd ... --label ...` syntax.
3. In each workspace, spawn the agent and hand it **only its slice's task** — explicitly name the
   directory/files it owns and tell it not to touch others. Use the vendored "spawn a new agent and
   give it a task" recipe.
4. Optionally name each agent (e.g. `api`, `web`, `tests`) so you can route follow-ups by name
   instead of by ever-changing pane id. Confirm `herdr agent` naming syntax live.

## Worktree discipline (do this before/around every per-agent worktree)

These are general worktree lessons adapted to herdr. If the **`using-git-worktrees`** skill is
available in the session, use it for the generic mechanics and apply the herdr specifics below —
don't re-derive the generic discipline here.

1. **Detect existing isolation first — don't nest.** Before creating a worktree for an agent, check
   you aren't *already* in a linked worktree, or you'll stack worktree-on-worktree:
   ```bash
   GIT_DIR=$(cd "$(git rev-parse --git-dir)" && pwd -P)
   GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
   # GIT_DIR != GIT_COMMON  → already in a worktree (UNLESS in a submodule:)
   git rev-parse --show-superproject-working-tree   # non-empty ⇒ submodule, treat as normal repo
   ```
   If a pane is already in a worktree, reuse it; don't create another.

2. **`herdr worktree create` IS the native tool — prefer it, and here's the real why.** Using raw
   `git worktree add` inside herdr creates **phantom state herdr can't see**: the checkout isn't
   wired to a workspace, no `worktree.created` event fires for plugins, and `herdr worktree
   list`/`remove` won't manage or clean it. Let herdr own the lifecycle so its sidebar, events, and
   teardown stay consistent. (This is the same "don't fight the harness" rule that says prefer a
   native worktree tool over manual git.)

3. **Start each worktree from a clean, verified baseline.** After creating an agent's worktree, run
   project setup (e.g. `npm install` / `cargo build` / `pip install`) and a quick baseline test
   **before** dispatching the agent. Otherwise the agent can't tell a pre-existing failure from one
   it caused — and you can't either at integration time. Only hand off the task once the slice is green.

4. **Keep worktree paths out of git.** By default `herdr worktree create` places the checkout under a
   **managed location outside your repo** (verified 0.6.10: `~/.herdr/worktrees/<repo>/<branch>`), so
   the ignore problem doesn't arise. It only matters if you **override `--path`** to put a worktree
   *inside* the repo — then verify it's gitignored (`git check-ignore -q <path>`) before work begins.

5. **Pair creation with teardown.** A worktree is created to be integrated and removed, not left
   behind. After a worker reaches `done` and you've merged/rebased its branch, run
   `herdr worktree remove --workspace <id>` (confirm flags live). Orphaned worktrees pile up phantom
   workspaces and stale branches. Integrate **one at a time** (see *Collecting results*).

## Briefing workers to stay in their lane

The fan-out is only as safe as the instructions. Each worker's prompt should state:
- **its slice** ("you own `src/api/` and its tests, nothing else"),
- **its branch/worktree** (so it doesn't wander),
- **the hand-off contract** — what "done" looks like and what it should leave for the integrator
  (a passing test, a summary, a clean diff).

Ambiguous ownership is the #1 cause of parallel-agent rework.

## Collecting results

After fan-out, wait on each worker reaching `done`, then **read its pane before trusting it** —
`done` is "finished, unreviewed," not "correct." Integrate sequentially (merge worktrees one at a
time, resolving conflicts) rather than trusting all branches to merge clean. The waiting/reading
commands belong to the vendored skill.

## When fan-out backfires

- **Shared-file edits** → merge hell. Re-slice or serialize.
- **Hidden coupling** (worker A's change breaks worker B's build) → you find out only at integration.
  Mitigate by having each worker keep its slice green independently.
- **Too many workers to supervise** → if you can't keep up with `blocked` agents, you've over-fanned.
  A blocked worker that sits unrouted stalls the whole batch. Cap the fleet at what you can route.
- **Token blow-up** → N agents cost N× context. Fan out for *independent* work, not to brute-force a
  single coupled problem (that's a council, and it's a deliberate trade — see councils-and-teams.md).
