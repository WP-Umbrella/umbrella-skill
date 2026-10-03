# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A zero-dependency Claude Code plugin (`umbrella`) that teaches Claude to operate WordPress sites through the WP Umbrella Public API (`https://public-api.wp-umbrella.com`). There is no application code: the plugin is markdown skills + the official OpenAPI spec. At runtime Claude reads the skill, builds `curl` calls with the user's Bearer token, and executes them itself. Repository: https://github.com/WP-Umbrella/umbrella-skill (API reference at https://wp-umbrella.readme.io/).

## Source of truth vs generated output

- `src/skills/` — **canonical, human-edited** content. Edit here only.
- `skills/` — **generated** by `scripts/build.sh`; this is what Claude Code actually loads. Never edit by hand.
- Both trees are committed. CI (`.github/workflows/verify-build.yml`) reruns the build and fails on any drift in `skills/`, so every change to `src/` must be followed by a rebuild and both trees committed together.

Today the build is effectively a pass-through copy (`diff -r src/skills skills` is empty). It contains a caveman-compression hook (headless `claude -p "/caveman:compress"`) that only runs when the `claude` CLI is on PATH and `UMBRELLA_SKIP_COMPRESS` is not `1`; CI has no `claude` CLI so it always takes the copy path. Caveman writes `*.original.md` sidecars — `scripts/clean-originals.sh` removes them if a build is interrupted. Never run compression against `src/`.

## Commands

```bash
./scripts/build.sh                      # regenerate skills/ from src/
UMBRELLA_SKIP_COMPRESS=1 ./scripts/build.sh   # force plain copy (matches CI)

# L1 build sanity — idempotent build + parity + no sidecar debris
./scripts/build.sh && ./scripts/build.sh && diff -r src/skills skills && ! find src -name '*.original.md' | grep -q .

# L2 manifest validation
claude plugin validate .
claude plugin validate .claude-plugin/plugin.json

# L4 runtime test — load the plugin from this checkout
claude --plugin-dir .
```

Minimum before a PR: L1 + L2 + L4 (see CONTRIBUTING.md for the full 5-level checklist). In L4, verify that `/umbrella:sites` and `/umbrella:health` autocomplete, that a natural-language request auto-invokes the skill, and that a mutating request (e.g. "update plugins on site X") stops for confirmation — observe the gate, don't confirm.

Releases: bump `version` in `.claude-plugin/plugin.json` (semver), run L1/L2/L4, tag `vX.Y.Z`.

## Architecture of the skill content

Three skills live under `src/skills/`:

- `umbrella/` — the knowledge skill, auto-invoked by description. `SKILL.md` defines the contract every other file relies on: token resolution order (`$CLAUDE_PLUGIN_OPTION_token` → `$WP_UMBRELLA_TOKEN` → `~/.umbrella/token`, never paste into chat), the base URL, the `processId` polling protocol (terminal codes are exactly `success` / `failed` / `finished`; anything else including `pending` means keep polling, 5s interval, ~2 min cap), pagination, error shapes, and the **mutation gate** (any POST/PUT/DELETE must restate the action and wait for explicit confirmation; GETs never prompt). `openapi-public.json` is the authoritative schema — consult it for exact paths, required fields and enums before writing any request.
- `sites/` and `health/` — thin `user-invocable` slash commands (`/umbrella:sites [filter]`, `/umbrella:health`). They contain no API logic; they map arguments to numbered steps in `umbrella/workflows/reporting/project-inventory.md`. If you renumber steps in that workflow, update both commands.

`umbrella/workflows/` holds playbooks organized by **user intent** (`maintenance/`, `security/`, `diagnostics/`, `reporting/`), not by API resource — one workflow often spans several endpoints. `project-inventory.md` is the foundation workflow (name → project ID resolution) that others reference; `safe-plugin-update.md` is the reference example of a full mutating playbook (pre-flight → plan table → confirmation → POST → poll → verify → re-check). `workflows/README.md` is the index and defines the required section structure for a new workflow (intents, endpoints, preconditions, numbered steps with curl+jq, confirmation gates, error paths); link every new workflow from it. Several workflows listed there as *Planned* (e.g. `custom-work-scheduling`) have endpoints already present in the OpenAPI spec.

`umbrella/references/` holds user-facing setup docs (`auth.md`, `permissions.md`) that `SKILL.md` and the README point users to; keep the Public API token vs. plugin connection-key distinction intact when editing them.

## Conventions

- Commit messages follow conventional-commit prefixes (`docs:`, `fix:`, `chore:`); branches are named `<type>/issue-<n>-<slug>`. PRs target `develop`.
- User-facing responses in skills must match the user's language; endpoint names, JSON keys, and skill prose stay in English.
- Any new endpoint usage that mutates a site must go through the confirmation gate and, if the response returns a `processId`, the polling protocol from `SKILL.md` §6.
- `.claude/settings.json` in this repo allow-lists read-only `curl` calls to the API for development; mutations stay gated by the skill, not by permissions.
