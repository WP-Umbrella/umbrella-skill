# Workflows

Step-by-step playbooks for common user intents. Each workflow is self-contained: the AI can follow it end-to-end to satisfy a user request, including preconditions, error paths, and confirmation gates.

## Categories

### [`maintenance/`](./maintenance/) — Routine upkeep

Updates, database cleanup, scheduled work.

- [safe-plugin-update.md](./maintenance/safe-plugin-update.md) — update plugins with pre-flight checks, safe mode, and visual regression verification
- [custom-work-scheduling.md](./maintenance/custom-work-scheduling.md) — log or schedule a custom maintenance work (one-time or recurring) on a project for tracking and client reports
- *Planned:* safe-theme-update, wp-core-update, database-cleanup

### `security/` — Vulnerability management

Patching, audits, hardening.

- *Planned:* triage-vulnerabilities, patch-critical-cves, plugin-hygiene-audit

### `diagnostics/` — "Something's wrong"

Fault finding, incident response, rollback.

- *Planned:* site-down-playbook, performance-regression, post-update-rollback, broken-link-sweep

### [`reporting/`](./reporting/) — Multi-site inventories & audits

Client-ready summaries, exports, fleet dashboards.

- [project-inventory.md](./reporting/project-inventory.md) — list, filter, drill into, and summarize sites. **Start here whenever the user asks about their sites or needs to find a project ID.**
- *Planned:* weekly-health-report, client-maintenance-report, fleet-update-summary

## Adding a new workflow

1. **Pick one of the four categories.** If none fit, question whether this is actually a workflow, or just an API call that belongs inline in `SKILL.md` / `openapi-public.json`.
2. **Name by user intent**, not by endpoint. Good: `safe-plugin-update.md`. Bad: `post-plugins-update.md`.
3. **Structure**:
   - **User intents this covers** — 3-5 example prompts the AI should recognize
   - **Endpoint(s)** — method + path + key params
   - **Preconditions** — token, required IDs, abort conditions
   - **Steps** — numbered; each with curl + jq + what to present to the user
   - **Confirmation gates** — any mutation MUST pause for user approval
   - **Error paths** — what the AI does when a step fails
4. **Link the new workflow from this README** under the right category.

## Why categories and not API-resource folders?

Users think in intentions (*"update my plugins safely"*, *"is my fleet healthy?"*), not in REST resources. A single workflow often touches multiple API resources (e.g. `project-inventory.md` reads projects + vulnerabilities + warnings). Categorizing by intent keeps related playbooks together and matches how the user phrases their request.
