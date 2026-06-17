---
description: Configure or tune herdr — keybindings, theme, agent-detection rules, notifications, or write a herdr plugin.
argument-hint: <what to change>
allowed-tools: Bash, Read, Edit, Write, WebFetch, Glob, Grep
---

Change herdr configuration. Request: **$ARGUMENTS**

1. Use the **herdr-configuration** skill to locate the right surface:
   - general behavior, keybindings, themes, notifications/sounds → `~/.config/herdr/config.toml`
     (apply with `herdr server reload-config`);
   - agent-detection/labeling rules → per-agent manifest under `~/.config/herdr/agent-detection/`
     (apply with the manifest-reload command — confirm its exact name live);
   - authoring a herdr plugin → a `herdr-plugin.toml` directory (distinct from this Claude Code plugin).
2. Always start from generated defaults — `herdr --default-config` — rather than memorized keys; confirm
   exact key names and default values live. Make a backup before editing an existing config.
3. Make the minimal edit, then run the matching reload command and report what changed and how to revert.

For *why* an agent's detected state looks wrong (vs how to change the rule), use **herdr-agent-monitoring**.
