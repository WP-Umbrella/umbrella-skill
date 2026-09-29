# WP Umbrella MCP server — manage every WordPress site from Claude, ChatGPT or any AI assistant
<img width="2560" height="423" alt="WP Umbrella — the WordPress AI agent" src="https://github.com/user-attachments/assets/5bfdf9c4-a98f-4cad-8f8c-b162668cf3b6" />

###

![MCP Server](https://img.shields.io/badge/MCP-Server-10B981)
![OAuth](https://img.shields.io/badge/Auth-OAuth_2.0-0EA5E9)
![Tools](https://img.shields.io/badge/Tools-71-8B5CF6)
![Version](https://img.shields.io/github/v/release/wp-umbrella/umbrella-skill)
[![WP Umbrella](https://img.shields.io/badge/Powered_by-WP_Umbrella-0EA5E9)](https://wp-umbrella.com)

**Connect your AI assistant to [WP Umbrella](https://wp-umbrella.com) and run your whole WordPress maintenance workflow by talking instead of clicking.**

The WP Umbrella MCP server is hosted by us at `https://mcp.wp-umbrella.com/`. Paste the URL into Claude, ChatGPT, Claude Code, Cursor or any MCP-compatible assistant, sign in with your WP Umbrella account, and you're done: **no API key, nothing to install, one connection for your whole fleet.**

New to WP Umbrella? Start a [14-day free trial, no credit card](https://app.wp-umbrella.com/register).

## Quick start

| Client | How to connect |
|---|---|
| **Claude** (web, desktop, mobile) | **Settings → Connectors → Browse connectors**, search **WP Umbrella**, click **Connect**. Or **Add custom connector** with `https://mcp.wp-umbrella.com/` |
| **Claude Code** | `claude mcp add --transport http wp-umbrella https://mcp.wp-umbrella.com/`, then `/mcp` → **Authenticate** |
| **ChatGPT** (Business, Enterprise, Edu) | Turn on developer mode, then **Settings → Apps → Create** with `https://mcp.wp-umbrella.com/` and OAuth |
| **Cursor** and other clients | Add `{"mcpServers": {"wp-umbrella": {"url": "https://mcp.wp-umbrella.com/"}}}` to your MCP config |

**Even faster in coding agents** (Claude Code, Cursor, Codex…): just ask *"Add the MCP server https://mcp.wp-umbrella.com/ and connect to it."* The agent adds it and opens the WP Umbrella sign-in.

Sign-in uses **OAuth**: you log in on WP Umbrella and choose what the assistant can access. Your password never reaches the AI client, and there is no token to copy, store or rotate.

📖 Full guide: [WP Umbrella MCP documentation](https://wp-umbrella.com/REPLACE-WITH-HELP-CENTER-URL)

## Who this is for

- **WordPress agencies and freelancers** maintaining 10 to 1,000+ client sites who want to replace hours of clicking with a short conversation.
- **Hosting companies and managed WordPress providers** who want to give support and operations teams an assistant that can check any customer site in one question.
- **Teams building their own AI workflows and agents** on top of WP Umbrella's infrastructure: updates with rollback, backups, security scanning, uptime and reporting, ready to use as tools.

## First 5 things to try

These only read data, so nothing changes on your sites:

1. *"Which of my WordPress sites need attention today?"*
2. *"Which plugins are outdated on example.com, and do any updates fix a vulnerability?"*
3. *"Give me a security overview of all my sites, least secure first."*
4. *"Was example.com down in the last 30 days? Any PHP fatal errors?"*
5. *"When was example.com last backed up, and how often is it backed up?"*

Then act in the same conversation: *"Back up example.com, then update those plugins."* The assistant tells you exactly what will change and waits for your confirmation.

## What you can do — 71 tools

| Area | Examples |
|---|---|
| **Updates** | List plugins and themes, update plugins, themes and WordPress core (Safe update with automatic rollback), plugin update automations, updates blocked by missing licences |
| **Backups** | Backup history, incremental backups on demand, schedule and exclusions, temporary download links |
| **Security** | Fleet security score, vulnerabilities by severity, malware detections, Patchstack firewall, hardening (2FA, login limits, XML-RPC…), hidden admin cleanup |
| **Monitoring** | Uptime and incidents, Lighthouse performance and Core Web Vitals, PHP errors, broken links, activity log |
| **Clients & reports** | Customers, labels, custom maintenance work, white-label maintenance reports |
| **Database** | Database optimization |

40 tools only read data. The other 31 change your WP Umbrella account or a site, and the server instructs the assistant to confirm with you before each one.

## Build custom workflows

The tools are building blocks. Chain them in a prompt, a skill, a scheduled agent or your own app (the Claude API and OpenAI API both support remote MCP servers):

| Workflow | Tools it chains |
|---|---|
| Weekly patch run with a safety net | `create_incremental_backup` → `update_plugins` (Safe update) → `wait_for_process` → `get_uptime`, `list_issues` |
| Vulnerability response across the fleet | `list_security_overview` → `get_vulnerabilities` → `update_plugins` → `scan_vulnerabilities` |
| Monthly client reporting | `list_customers` → `create_custom_work` → `generate_report` → `get_report` |
| Incident triage for support teams | `get_uptime` → `list_issues` → `get_activity_log_digest` → `list_tasks` |

## Security

- **OAuth, not shared secrets.** Each person signs in with their own WP Umbrella account. The assistant acts as that user, with no more rights than their account, and only on the sites they authorized.
- **Confirmation before any change.** Reading runs freely. Updates, backups, security settings, database optimization, reports and deletions wait for your explicit confirmation. Irreversible or billed actions (database optimization, hourly backups, security add-ons) are called out before you confirm.
- **Revoke any time.** Disconnect in your AI client (`claude mcp remove wp-umbrella` in Claude Code) and access stops.
- **Prompt injection.** Content read from sites could in theory contain instructions aimed at the assistant. The confirmation step is your safeguard: decline any action you didn't expect, and [open an issue](https://github.com/wp-umbrella/umbrella-skill/issues).
- **Data flow.** Your prompts and the data the assistant reads pass through your AI provider as part of the conversation. Your WP Umbrella password never does.

---

## Alternative: Claude Code plugin

Prefer everything to run from your own terminal? The **umbrella** Claude Code plugin ships the same capabilities as markdown workflows and slash commands. Claude calls the [WP Umbrella Public API](https://wp-umbrella.readme.io/) with `curl` using a Public API token stored in your OS keychain.

**Use the MCP server unless you specifically need this.** The plugin needs a Public API token, works only in Claude Code, and asks you to approve shell commands.

| | **MCP server (recommended)** | **Claude Code plugin** |
|---|---|---|
| Setup | Paste a URL, sign in | `/plugin install` + Public API token |
| Authentication | OAuth, no token to manage | Public API token in your keychain or `~/.umbrella/token` |
| Works with | Claude, ChatGPT, Claude Code, Cursor, any MCP client | Claude Code only |
| Tools | 71 typed tools, kept up to date by WP Umbrella | `curl` calls built from a bundled OpenAPI spec |
| Approvals | Approve the connector once | Approve `curl`/`jq` commands |

<details>
<summary>Install and use the plugin</summary>

```
/plugin marketplace add wp-umbrella/umbrella-skill
/plugin install umbrella@wp-umbrella
```

Claude Code asks for your **Public API token** (dashboard → **Profile → Public API (for developers)**) and stores it in your OS keychain. This is not the connection key that links a site to WP Umbrella. File-based and environment-variable setups: [`auth.md`](./src/skills/umbrella/references/auth.md).

| Command | What it does |
|---|---|
| `/umbrella:sites` | Quick list of all your sites |
| `/umbrella:sites down` | Only sites currently down |
| `/umbrella:sites updates` | Only sites with pending plugin updates |
| `/umbrella:sites vulns` | Only sites with known vulnerabilities |
| `/umbrella:sites <name>` | Search a site by name |
| `/umbrella:health` | Fleet-wide health snapshot |
| `/umbrella:work <site> <details>` | Log or schedule custom maintenance work |

Too many approval prompts? Run `/fewer-permission-prompts`, or see [`permissions.md`](./src/skills/umbrella/references/permissions.md). `/plugin update umbrella@wp-umbrella` keeps you on the latest release.

> **SSH-less machines:** if the install fails with `git@github.com: Permission denied (publickey)`, run `git config --global url."https://github.com/".insteadOf "git@github.com:"` and retry.

</details>

<details>
<summary>Contributing to the plugin</summary>

The canonical content lives under `src/`. `skills/` is regenerated by `scripts/build.sh`: **do not edit `skills/` by hand**. Edit `src/`, run `./scripts/build.sh`, commit both trees (CI checks they stay in sync). Full procedure: [`CONTRIBUTING.md`](./CONTRIBUTING.md).

</details>

## Feedback

Questions or bugs: [open an issue](https://github.com/wp-umbrella/umbrella-skill/issues) or contact [support@wp-umbrella.com](mailto:support@wp-umbrella.com).
