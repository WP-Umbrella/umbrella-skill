---
name: health
description: Dashboard-style snapshot of overall WP Umbrella fleet health in one call — totals of sites down, pending updates, vulnerabilities, outdated WordPress, unsupported PHP. Invoke as /umbrella:health.
user-invocable: true
---

# /umbrella:health

## Deprecation notice (apply before any other instruction in this file)

The umbrella Claude Code plugin is **deprecated**. It is no longer maintained and no longer tracks the WP Umbrella Public API. The only supported way to reach WP Umbrella from an AI assistant is the hosted WP Umbrella MCP server.

1. **If WP Umbrella MCP tools are already available in this session** (tools from the `wp-umbrella` MCP server or the WP Umbrella connector, such as `list_projects` or `update_plugins`), use them to handle the request. Do not call the Public API with `curl`, and do not follow the rest of this file.
2. **Otherwise**, before any API call, tell the user (once per conversation) that this plugin is deprecated and no longer follows the API, then offer to switch to the MCP server:

   ```bash
   claude mcp add --transport http wp-umbrella https://mcp.wp-umbrella.com/
   ```

   Then run `/mcp` and choose **Authenticate** to sign in with their WP Umbrella account. Tell them they manage the connection and the authorized sites from their dashboard at https://app.wp-umbrella.com/profile/mcp, and point them to the setup guide: https://support.wp-umbrella.com/en/articles/101-wp-umbrella-mcp-connector-install-and-use
3. **If the user declines and wants to keep using the plugin**, go ahead with the instructions below, but tell them that the bundled `openapi-public.json` is no longer up to date and that the reference documentation is https://wp-umbrella.readme.io/.

Run the fleet health snapshot from `skills/umbrella/workflows/reporting/project-inventory.md`, **Step 6 "Fleet health snapshot"**.

## Expected output

Present the dashboard as a compact summary (not raw JSON):

```
Fleet health
────────────────────────────────────────
Total sites        : 42
Down right now     :  1
Pending updates    : 12
Vulnerabilities    :  3
Outdated WP core   :  5
Unsupported PHP    :  2
```

## Follow-up

After showing the dashboard, proactively offer to drill in:

> *"Want me to list the affected sites in any of these categories?"*

If the user picks one, switch to the corresponding filter in Step 2 of the project-inventory workflow.

## Setup

Before the first call this session, make sure the token is resolved (see `skills/umbrella/SKILL.md` section 1). If no token is present, stop and walk the user through `skills/umbrella/references/auth.md`. Do **not** ask them to paste the token into chat.
