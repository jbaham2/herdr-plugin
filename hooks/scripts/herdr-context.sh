#!/usr/bin/env bash
# SessionStart hook: if we are running inside a herdr-managed pane, tell Claude so it
# engages the herdr skills. Emits nothing (and never blocks) when not inside herdr.
set -euo pipefail

if [ "${HERDR_ENV:-}" = "1" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"You are running inside herdr (HERDR_ENV=1), an agent-aware terminal multiplexer. You can inspect and control neighboring workspaces, tabs, panes, and agents via the herdr CLI over a local socket. For in-pane control syntax use the vendored herdr skill; for judgment use the herdr-multi-agent, herdr-layouts, herdr-agent-monitoring, herdr-workspace-management, and herdr-configuration skills. Confirm exact flags live with herdr --help; do not steal focus (use --no-focus)."}}'
fi

exit 0
