---
name: sites
description: Power-user shortcut to list WP Umbrella sites with an optional filter. Invoke as /umbrella:sites [filter]. Filter can be "down", "updates", "vulns", "outdated", "php", or a name search.
user-invocable: true
argument-hint: [filter]
---

# /umbrella:sites

## Deprecation notice (apply before any other instruction in this file)

The umbrella Claude Code plugin is **deprecated**. It is no longer maintained and no longer tracks the WP Umbrella Public API. The only supported way to reach WP Umbrella from an AI assistant is the hosted WP Umbrella MCP server.

1. **If WP Umbrella MCP tools are already available in this session** (tools from the `wp-umbrella` MCP server or the WP Umbrella connector, such as `list_projects` or `update_plugins`), use them to handle the request. Do not call the Public API with `curl`, and do not follow the rest of this file.
2. **Otherwise**, before any API call, tell the user (once per conversation) that this plugin is deprecated and no longer follows the API, then offer to switch to the MCP server:

   ```bash
   claude mcp add --transport http wp-umbrella https://mcp.wp-umbrella.com/
   ```

   Then run `/mcp` and choose **Authenticate** to sign in with their WP Umbrella account. Tell them they manage the connection and the authorized sites from their dashboard at https://app.wp-umbrella.com/profile/mcp, and point them to the setup guide: https://support.wp-umbrella.com/en/articles/101-wp-umbrella-mcp-connector-install-and-use
3. **If the user declines and wants to keep using the plugin**, go ahead with the instructions below, but tell them that the bundled `openapi-public.json` is no longer up to date and that the reference documentation is https://wp-umbrella.readme.io/.

Shortcut to the project-inventory workflow. Take `$1` and map it to the right step of `skills/umbrella/workflows/reporting/project-inventory.md`.

## Argument mapping

| `$1` | Action |
|---|---|
| *(empty)* / `all` | Step 1 — quick listing |
| `down` | Step 2 — "Down right now" |
| `updates` / `update` | Step 2 — "Plugin updates pending" |
| `vulns` / `vulnerabilities` / `vuln` | Step 2 — "Known vulnerabilities" |
| `outdated` / `wp` | Step 2 — "WordPress core out of date" |
| `php` | Step 2 — "PHP unsupported / insecure" |
| anything else | Step 3 — treat `$1` as a site name search |

## Setup

Before the first call this session, make sure the token is resolved (see `skills/umbrella/SKILL.md` section 1). If no token is present, stop and walk the user through `skills/umbrella/references/auth.md`. Do **not** ask them to paste the token into chat.

## Arguments received

`$ARGUMENTS`
