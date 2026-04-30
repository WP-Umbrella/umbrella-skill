# WP Umbrella — the WordPress AI agent
<img width="2560" height="423" alt="Youtube Banner - 2560x423 (1)" src="https://github.com/user-attachments/assets/5bfdf9c4-a98f-4cad-8f8c-b162668cf3b6" />

###

![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-8B5CF6)
![Version](https://img.shields.io/github/v/release/wp-umbrella/umbrella-skill)
![Issues](https://img.shields.io/github/issues/wp-umbrella/umbrella-skill)
[![WP Umbrella](https://img.shields.io/badge/Powered_by-WP_Umbrella-0EA5E9)](https://wp-umbrella.com)

You're looking at the first AI agent built for WordPress agencies, powered by [WP Umbrella](https://wp-umbrella.com) infrastructure.

WP Umbrella is the monitoring and maintenance platform trusted by WordPress professionals to manage their clients' sites — uptime, updates, backups, performance, and security, all in one place. This plugin connects Claude directly to that infrastructure through the [WP Umbrella Public API](https://wp-umbrella.readme.io/), so you can run your entire maintenance workflow by talking instead of clicking. 

We have a [2 weeks free trial without credit card](https://app.wp-umbrella.com/register) so you can get started if you are not a client already.

## Who this is for

WordPress agencies and maintenance professionals managing 10 to 200+ client sites. If you spend hours each week clicking through update screens, this turns that work into a short conversation.

## What you can do

- **Get a fleet overview in one sentence.** "Which sites are down?", "Which have updates pending?", "Which have known security issues?"
- **Run safe plugin updates.** Claude uses the WP Umbrella safe-update workflow: back up, update, check the site is healthy, roll back if anything fails.
- **Review vulnerabilities across all sites.** Surface known CVEs, sorted by severity.
- **Stay in control.** Reading and checking runs freely. Anything that changes a site waits for your explicit confirmation.

## How does it work?

umbrella is a zero-dependency Claude Code plugin: just markdown + the official OpenAPI spec. Claude loads it as context, then calls the WP Umbrella API directly with `curl` on your behalf — no server to install, no binary to run.

```
       You ────────►  Claude ────────►  public-api.wp-umbrella.com
   "update plugins"   (reads umbrella,    (your Bearer token,
                       constructs curl)    your projects)
```

---

## Requirements

- A **WP Umbrella** account with the Public API feature enabled
- A **Public API token** — generate one in your dashboard under *Settings → Public API*
- **Claude Code** installed (macOS, Linux, or Windows) — https://claude.com/claude-code

## Install

Inside Claude Code, run:

```
/plugin marketplace add wp-umbrella/umbrella-skill
/plugin install umbrella@wp-umbrella
```

That's it. `/plugin update umbrella@wp-umbrella` keeps you on the latest release.

### Manual install (for development or testing)

If you want to hack on the plugin itself:

```bash
git clone https://github.com/wp-umbrella/umbrella-skill.git
claude --plugin-dir ./umbrella-skill
```

### Other AI agents (Cursor, Windsurf, ChatGPT, …)

*Coming soon.* The skill content under `skills/umbrella/` is pure markdown + OpenAPI and works with any agent that can execute shell commands — a generic install guide for other agents is on the way.

## Set up your token

Two simple options depending on how you installed umbrella.

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

**Chat naturally:**

> *"List my WP Umbrella projects"*
> *"Which of my sites have plugin updates pending?"*
> *"Update SeoPress on project 123 using the safe-update workflow."*

**Or use a slash command:**

| Command | What it does |
|---|---|
| `/umbrella:sites` | Quick list of all your sites |
| `/umbrella:sites down` | Only sites currently down |
| `/umbrella:sites updates` | Only sites with pending plugin updates |
| `/umbrella:sites vulns` | Only sites with known vulnerabilities |
| `/umbrella:sites <name>` | Search a site by name |
| `/umbrella:health` | Fleet-wide health snapshot (totals) |

Claude reads the relevant workflow, calls the right API endpoints with your token, and reports back.

## Run commands faster (optional)

By default, Claude asks for your approval before every `curl`, `jq`, `head`, etc. For umbrella's read-only operations this adds friction fast.

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
│       └── health/              # /umbrella:health slash command
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

- **Your token stays on your machine.** When you use the recommended install, Claude Code stores your Public API token in your OS keychain (macOS Keychain, Windows Credential Manager, Linux Secret Service). Nothing runs on WP Umbrella's servers between Claude and the API — calls go directly from your machine to `public-api.wp-umbrella.com`.

- **Confirmation before any change.** The plugin instructs Claude to ask for your explicit confirmation before any call that modifies a site (plugin updates, database operations, restorations). Read-only calls (listing sites, checking vulnerabilities) run without prompting. This is enforced by two independent layers: the skill's own instructions, and Claude Code's command approval system.

- **Known limits.** Like any AI agent, Claude is not a hard technical guarantee. A confused or adversarially prompted model could in principle attempt a mutating call, which is why the two-layer confirmation system matters. If you ever see Claude propose a command you didn't expect, decline it and open an issue.

- **Prompt injection.** When Claude reads content from your sites or third-party APIs, that content could in theory contain instructions designed to hijack the agent. The confirmation gate on mutations is your main defense here. Treat any unexpected proposed action as a signal to stop and investigate.

- **If your token leaks.** Revoke it immediately [in your WP Umbrella dashboard](https://app.wp-umbrella.com/profile), then generate a new one. API calls are logged on the WP Umbrella side and available in your dashboard for incident review.

- **Data flow.** Your prompts, the API responses Claude sees, and the commands it generates pass through Anthropic's infrastructure as part of using Claude. Your Public API token does not — it stays on your local machine and is used only when Claude Code executes a call from your terminal.

## Feedback

Open an issue at https://github.com/wp-umbrella/umbrella-skill/issues.
