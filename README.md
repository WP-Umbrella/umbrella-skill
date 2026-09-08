# WP Umbrella — the WordPress AI agent
<img width="2560" height="423" alt="Youtube Banner - 2560x423 (1)" src="https://github.com/user-attachments/assets/5bfdf9c4-a98f-4cad-8f8c-b162668cf3b6" />

###

![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-8B5CF6)
![MCP Server](https://img.shields.io/badge/MCP-Server-10B981)
![Version](https://img.shields.io/github/v/release/wp-umbrella/umbrella-skill)
![Issues](https://img.shields.io/github/issues/wp-umbrella/umbrella-skill)
[![WP Umbrella](https://img.shields.io/badge/Powered_by-WP_Umbrella-0EA5E9)](https://wp-umbrella.com)

You're looking at the first AI agent built for WordPress agencies, powered by [WP Umbrella](https://wp-umbrella.com) infrastructure.

WP Umbrella is the monitoring and maintenance platform trusted by WordPress professionals to manage their clients' sites — uptime, updates, backups, performance, and security, all in one place. This project connects Claude directly to that infrastructure through the [WP Umbrella Public API](https://wp-umbrella.readme.io/), so you can run your entire maintenance workflow by talking instead of clicking.

Two ways in: our **[hosted MCP server](#option-a--mcp-server-for-ai-assistants)** (one command, works with any MCP-capable assistant) or the **[Claude Code plugin](#option-b--claude-code-plugin)** (markdown workflows + slash commands). [Compare them](#two-ways-to-connect).

We have a [2 weeks free trial without credit card](https://app.wp-umbrella.com/register) so you can get started if you are not a client already.

## Who this is for

WordPress agencies and maintenance professionals managing 10 to 200+ client sites. If you spend hours each week clicking through update screens, this turns that work into a short conversation.

## What you can do

- **Get a fleet overview in one sentence.** "Which sites are down?", "Which have updates pending?", "Which have known security issues?"
- **Run safe plugin updates.** Claude uses the WP Umbrella safe-update workflow: back up, update, check the site is healthy, roll back if anything fails.
- **Review vulnerabilities across all sites.** Surface known CVEs, sorted by severity.
- **Log and schedule maintenance work.** "Log 2 hours of SEO work on site X today", "Schedule a monthly content review on the 1st" — tracked custom works that feed your client reports.
- **Stay in control.** Reading and checking runs freely. Anything that changes a site waits for your explicit confirmation.

## Two ways to connect

Both talk to the same [WP Umbrella Public API](https://wp-umbrella.readme.io/) with the same token. Pick the one that fits your setup — you can also run both.

| | **MCP server** | **Claude Code plugin** |
|---|---|---|
| Setup | One command, nothing to install | `/plugin install`, nothing to install either |
| Works with | Any MCP-capable assistant (Claude Code, Claude Desktop, Cursor, …) | Claude Code |
| How calls happen | Typed tools served by WP Umbrella's hosted MCP server | Claude builds `curl` calls locally from the OpenAPI spec |
| Approvals | Approve the server (and its tools) once in your client | Approve `curl`/`jq` — see [`/fewer-permission-prompts`](#run-commands-faster-plugin-optional) |
| Guided workflows | Server-side tools | Full markdown workflows shipped as context (safe-plugin-update, …) |
| Where your token sits | Sent as a header to `mcp.wp-umbrella.com` | Stays on your machine (OS keychain or `~/.umbrella/token`) |

```
  MCP     You ──► Claude ──► mcp.wp-umbrella.com ──┐
       "update plugins"        (hosted tools)      │
                                                   ├──► public-api.wp-umbrella.com ──► your sites
  Plugin  You ──► Claude ──► curl, from your ──────┘
       "update plugins"        own terminal
```

---

## Requirements

- A **WP Umbrella** account with the Public API feature enabled
- A **Public API token** — generate one in your dashboard under **Profile → Public API (for developers)**
  > ⚠️ This is **not** the same as your dashboard↔plugin **connection key** (the key that links a WordPress site to WP Umbrella). The Public API token is an account-level developer token; reaching for the connection key here won't work and is a security footgun.
- An MCP-capable AI assistant, or **Claude Code** (macOS, Linux, or Windows) — https://claude.com/claude-code

## Option A — MCP server (for AI assistants)

The MCP server lets an AI assistant such as Claude read and act on your sites through the Public API. Export the Public API token above, then register the server in Claude Code:

```bash
export WP_UMBRELLA_TOKEN="your-token-here"
claude mcp add wp-umbrella --transport http https://mcp.wp-umbrella.com/ \
  --header "Authorization: Bearer $WP_UMBRELLA_TOKEN"
```

Same `WP_UMBRELLA_TOKEN` variable the plugin reads, so one export covers both. If you already keep the token in `~/.umbrella/token`, substitute it directly instead: `--header "Authorization: Bearer $(head -n1 ~/.umbrella/token)"`.

Keep the token secret — it grants access to every site in your account.

Once connected, you can ask things like:

> *"Which of my sites have pending plugin updates?"*
> *"Update all the plugins on example.com."*
> *"List the known vulnerabilities across my sites."*
> *"When was the last backup of example.com, and did it succeed?"*
> *"Show me the broken links found on example.com."*

Check the connection with `claude mcp list`, and remove it with `claude mcp remove wp-umbrella`.

### Other MCP clients

`https://mcp.wp-umbrella.com/` is a remote HTTP MCP server, so any client that speaks that transport works. Most of them take a config block along these lines:

```json
{
  "mcpServers": {
    "wp-umbrella": {
      "type": "http",
      "url": "https://mcp.wp-umbrella.com/",
      "headers": { "Authorization": "Bearer YOUR_TOKEN_HERE" }
    }
  }
}
```

Check your client's documentation for the exact file and key names.

## Option B — Claude Code plugin

Inside Claude Code, run:

```
/plugin marketplace add wp-umbrella/umbrella-skill
/plugin install umbrella@wp-umbrella
```

That's it. `/plugin update umbrella@wp-umbrella` keeps you on the latest release.

> **SSH-less machines:** if the install fails with `git@github.com: Permission denied (publickey)`, the installer is cloning over SSH on a machine without a GitHub SSH key. Tell git to use HTTPS instead, then re-run the install:
> ```bash
> git config --global url."https://github.com/".insteadOf "git@github.com:"
> ```

### Manual install (for development or testing)

If you want to hack on the plugin itself:

```bash
git clone https://github.com/wp-umbrella/umbrella-skill.git
claude --plugin-dir ./umbrella-skill
```

### Other AI agents (Cursor, Windsurf, ChatGPT, …)

The quickest route is [the MCP server](#option-a--mcp-server-for-ai-assistants) — it works with any MCP-capable assistant, no plugin needed.

If you'd rather ship the skill itself: the content under `skills/umbrella/` is pure markdown + OpenAPI and works with any agent that can execute shell commands — a generic install guide for other agents is on the way.

## Set up your token (plugin)

The MCP server takes the token as a header, so this section only concerns the Claude Code plugin. Two simple options depending on how you installed umbrella.

### If you used `/plugin install umbrella@wp-umbrella` (recommended)

**Nothing extra to do.** Claude Code prompted you for the token at install time and stored it in your OS keychain (macOS Keychain, Windows Credential Manager, Linux Secret Service). umbrella reads it automatically on every call.

### If you prefer a file-based setup (or use another AI agent)

Save the token to `~/.umbrella/token`. Three commands — replace `PASTE_YOUR_TOKEN_HERE` with your actual token:

```bash
mkdir -p ~/.umbrella
echo "PASTE_YOUR_TOKEN_HERE" > ~/.umbrella/token
chmod 600 ~/.umbrella/token
```

CI / ephemeral shells can export `WP_UMBRELLA_TOKEN` instead. Full guide: [`src/skills/umbrella/references/auth.md`](./src/skills/umbrella/references/auth.md).

## Try it

Open Claude Code in any directory and either:

**Chat naturally** (works with the MCP server too):

> *"List my WP Umbrella projects"*
> *"Which of my sites have plugin updates pending?"*
> *"Update SeoPress on project 123 using the safe-update workflow."*

**Or use a slash command** (plugin only):

| Command | What it does |
|---|---|
| `/umbrella:sites` | Quick list of all your sites |
| `/umbrella:sites down` | Only sites currently down |
| `/umbrella:sites updates` | Only sites with pending plugin updates |
| `/umbrella:sites vulns` | Only sites with known vulnerabilities |
| `/umbrella:sites <name>` | Search a site by name |
| `/umbrella:health` | Fleet-wide health snapshot (totals) |
| `/umbrella:work <site> <details>` | Log or schedule a custom maintenance work (one-time or recurring) on a site |

Claude reads the relevant workflow, calls the right API endpoints with your token, and reports back.

## Run commands faster (plugin, optional)

With the plugin, Claude asks for your approval before every `curl`, `jq`, `head`, etc. For umbrella's read-only operations this adds friction fast. (The MCP server isn't affected — you approve its tools in your client instead.)

**Quick fix — inside Claude Code, run:**

```
/fewer-permission-prompts
```

Claude Code analyzes your recent usage and adds a tailored allowlist to your settings. Mutations (plugin updates, DB optimization) still require explicit confirmation — that safety gate lives in the skill itself, not in your permissions file.

Full guide (including a manual allowlist snippet): [`src/skills/umbrella/references/permissions.md`](./src/skills/umbrella/references/permissions.md).

## What's in this repo

```
umbrella/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest (metadata)
│   └── marketplace.json         # Marketplace listing for umbrella
├── src/                         # ← Source of truth (human-edited)
│   └── skills/
│       ├── umbrella/            # Main knowledge skill (readable markdown)
│       │   ├── SKILL.md
│       │   ├── openapi-public.json
│       │   ├── references/
│       │   └── workflows/
│       ├── sites/               # /umbrella:sites slash command
│       ├── health/              # /umbrella:health slash command
│       └── work/                # /umbrella:work slash command
├── skills/                      # ← Generated (what Claude loads)
│   └── …                        # mirror of src/skills, compressed at build time
├── scripts/
│   └── build.sh                 # regenerates skills/ from src/
├── .github/workflows/
│   └── verify-build.yml         # CI check that skills/ matches src/
├── .gitattributes               # marks skills/ as generated
└── README.md
```

## Contributing / developing

The canonical content lives under `src/`. `skills/` is regenerated by `scripts/build.sh` — **do not edit `skills/` by hand**, your changes will be overwritten at the next build.

Typical flow:

```bash
# 1. Edit the readable source
$EDITOR src/skills/umbrella/workflows/maintenance/safe-plugin-update.md

# 2. Rebuild the compressed output
./scripts/build.sh

# 3. Commit both trees (CI verifies they stay in sync)
git add src/ skills/
git commit -m "refine safe-plugin-update workflow"
```

### Current build behavior

`scripts/build.sh` today is a **pass-through copy** — it mirrors `src/` into `skills/` verbatim. Caveman compression (LLM-based markdown minification, ~46% token reduction on prose) is planned but not yet wired. See the TODO in `scripts/build.sh`.

### Testing

Full dev + test procedure (5 levels, build sanity → plugin runtime): [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Safety and security

We built this plugin knowing it would touch production client sites. A few things worth understanding before you install.

- **Where your token lives.** With the **plugin**, your Public API token stays on your machine — Claude Code stores it in your OS keychain (macOS Keychain, Windows Credential Manager, Linux Secret Service) and calls go directly from your machine to `public-api.wp-umbrella.com`, with nothing in between. With the **MCP server**, your client sends the token as an `Authorization` header to `mcp.wp-umbrella.com`, which calls the Public API on your behalf; the token is stored by your MCP client's own config (in Claude Code, `claude mcp add` writes it to your Claude Code configuration).

- **Confirmation before any change.** The plugin instructs Claude to ask for your explicit confirmation before any call that modifies a site (plugin updates, database operations, restorations). Read-only calls (listing sites, checking vulnerabilities) run without prompting. This is enforced by two independent layers: the skill's own instructions, and Claude Code's command approval system. With the MCP server, that gate is your client's tool-approval settings — review which tools you allow to run without asking.

- **Known limits.** Like any AI agent, Claude is not a hard technical guarantee. A confused or adversarially prompted model could in principle attempt a mutating call, which is why the two-layer confirmation system matters. If you ever see Claude propose a command you didn't expect, decline it and open an issue.

- **Prompt injection.** When Claude reads content from your sites or third-party APIs, that content could in theory contain instructions designed to hijack the agent. The confirmation gate on mutations is your main defense here. Treat any unexpected proposed action as a signal to stop and investigate.

- **If your token leaks.** Revoke it immediately [in your WP Umbrella dashboard](https://app.wp-umbrella.com/profile), then generate a new one. API calls are logged on the WP Umbrella side and available in your dashboard for incident review.

- **Data flow.** Your prompts, the API responses Claude sees, and the commands or tool calls it generates pass through Anthropic's infrastructure as part of using Claude. Your Public API token does not: with the plugin it stays on your local machine and is used only when Claude Code executes a call from your terminal; with the MCP server it travels from your machine to `mcp.wp-umbrella.com` over TLS, never to Anthropic.

## Feedback

Open an issue at https://github.com/wp-umbrella/umbrella-skill/issues.
