---
description: Reattach to herdr or recover a session after a restart or update — explain what survived.
allowed-tools: Bash, Read, WebFetch, Glob, Grep
---

Help the user get back to their herdr work.

1. Use the **herdr-workspace-management** skill to determine what happened:
   - client closed but nothing restarted → just reattach (`herdr`, or `herdr --session <name>`);
   - server/machine restarted → layout/panes/cwd return but processes don't; eligible agents
     auto-resume only if native restore is on and integrations are current
     (`herdr integration status`);
   - recovering across an update → explain `herdr update --handoff` (experimental, built-in updater only).
2. Walk the persistence matrix from the skill's references to set correct expectations
   (a fresh shell in the right directory is the *expected* outcome after a restart, not a bug).
3. Reattach / reconcile, then report which agents resumed and which need a manual restart.

Confirm exact flags live (`herdr --help`); defer in-pane control to the vendored herdr skill.
