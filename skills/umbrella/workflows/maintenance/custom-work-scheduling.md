# Workflow — custom work scheduling

Create a **custom work** on a WP Umbrella project: a tracked maintenance task (one-time or recurring) that shows up in the project's work history and client maintenance reports. Use this whenever the user wants to log, schedule, or plan a piece of maintenance work on a site — not to *execute* an update right now (that's `safe-plugin-update.md`).

## User intents this covers

- *"Log 2 hours of SEO work on site X for today"*
- *"Schedule a monthly content review on project 123, every 1st of the month"*
- *"Add a recurring weekly plugin update task on Monday for site Y"*
- *"Create a quarterly performance audit task on all my client sites"*
- *"Track the custom CSS fix I did on X yesterday, 30 minutes"*

## Endpoint

`POST /projects/{projectId}/custom-works` — see `openapi-public.json` for the authoritative schema.

This workflow covers **creation**. The API also exposes `GET` (list), `GET /{customWorkId}`, `PUT` and `DELETE` for custom works — they are documented in `openapi-public.json`, so fall back to the spec if the user asks to list, edit, or delete works (the mutation gate applies to `PUT`/`DELETE`). A dedicated playbook for them is a planned follow-up; the WP Umbrella dashboard (Project → Maintenance / Custom works) remains the simplest place to manage existing works.

### Request body

| Field | Required | Type / values | Notes |
|---|---|---|---|
| `name` | **yes** | string | Short title shown in the dashboard and reports |
| `description` | **yes (in practice)** | string | Optional per the spec, but the API currently 500s without it ([#30](https://github.com/WP-Umbrella/umbrella-skill/issues/30)) — see Step 2 |
| `execution_date` | **yes** | `YYYY-MM-DD` | Date the work is (or was) done; for recurring works, the first occurrence |
| `estimated_time` | **yes** | number | Duration value |
| `estimated_time_unit` | **yes** | `MINUTES` \| `HOURS` \| `DAYS` | Unit of `estimated_time` |
| `is_recurring` | **yes** | boolean | **Always send it** — `false` for one-time works |
| `frequency` | if recurring | `WEEKLY` \| `MONTHLY` \| `QUARTERLY` | |
| `type_frequency` | if recurring | `MONDAY`…`SUNDAY` or `BEGIN_Q1`…`BEGIN_Q4` | Weekday for `WEEKLY`; quarter anchor for `QUARTERLY` |
| `specific_day` | if recurring | number | Day of month (1–31) for `MONTHLY`. Only required for `MONTHLY` by the schema, but see the temporary quirk below ([#31](https://github.com/WP-Umbrella/umbrella-skill/issues/31)) |

Do **not** send `plugin_keys` or `clear_cache`: older versions of the spec listed them, but the create endpoint silently ignores them — nothing is stored.

Recurrence combinations to use:

| User says | `frequency` | `type_frequency` | `specific_day` |
|---|---|---|---|
| every Monday | `WEEKLY` | `MONDAY` | `1` * |
| every 15th of the month | `MONTHLY` | *(omit)* | `15` |
| every quarter, start of Q1 | `QUARTERLY` | `BEGIN_Q1` | `1` * |

\* **Temporary API quirk** ([#31](https://github.com/WP-Umbrella/umbrella-skill/issues/31)): `specific_day` is only meant to be required for `MONTHLY`, but the API currently rejects a missing `specific_day` on any recurring work (error: `"schedule.specific_day" must be a number`). Until this is fixed server-side, always send `specific_day: 1` for `WEEKLY`/`QUARTERLY` works — the value is ignored for these frequencies, so `1` carries no meaning.

## Preconditions

- Token present (resolved per SKILL.md section 1)
- Project identified by name or ID — resolve the ID with `reporting/project-inventory.md` Step 3 if the user gave a name
- Abort if the user's request is actually "run an update now" → redirect to `safe-plugin-update.md`

## Step 1 — resolve the project

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects?per_page=200" \
  | jq '.data[] | select(.name | test("<NAME>"; "i")) | {id, name, base_url}'
```

If several projects match, ask the user which one. If the user asked for the same work on **several** sites, collect all IDs and create one custom work per project in Step 4 (one confirmation covering the whole batch is enough — list every site in the plan).

## Step 2 — gather the fields

Fill the required fields from the user's message. Ask **only** for what is missing, in a single question:

- `name` — derive from the request if obvious (*"SEO work"*, *"Monthly content review"*), otherwise ask
- `execution_date` — default to **today** when the user says "today"/"now" or gives no date; convert relative dates ("yesterday", "next Monday") to `YYYY-MM-DD` using the current date
- `estimated_time` + `estimated_time_unit` — normalize: "30 min" → `30 MINUTES`, "2h" → `2 HOURS`, "half a day" → `4 HOURS`, "a day" → `1 DAYS`
- `description` — required in practice until [#30](https://github.com/WP-Umbrella/umbrella-skill/issues/30) is fixed (the spec marks it optional, but the create endpoint currently returns HTTP 500 without it). **Never invent content for it.** If the user gave no detail, ask for a one-line description as part of this same question — it feeds the client-facing maintenance reports, so a real sentence beats noise. Only if the user declines ("no description", "whatever") send the work's `name` as the value.
- Recurrence — only if the user said recurring/weekly/monthly/quarterly/every…

## Step 3 — present the plan and confirm

This is a **mutating call** — apply the SKILL.md section 5 gate. Show the exact payload in plain language:

```
Project: <name> (ID <id>)
Work     : Monthly content review
Descr.   : Review and refresh cornerstone pages
Date     : 2026-09-01
Estimate : 2 HOURS
Recurring: yes — MONTHLY, day 1
Create this custom work? (yes/no)
```

**Wait for explicit confirmation.** Do not proceed on ambiguous replies.

## Step 4 — create the custom work

One-time example:

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "SEO on-page work",
    "description": "Rewrote meta titles on 12 pages",
    "execution_date": "2026-08-26",
    "estimated_time": 2,
    "estimated_time_unit": "HOURS",
    "is_recurring": false
  }' \
  "https://public-api.wp-umbrella.com/projects/<ID>/custom-works" \
  | jq '{code, id: .data.id, name: .data.name, execution_date: .data.execution_date, is_recurring: .data.is_recurring, scheduledWorkId: .data.scheduledWorkId}'
```

Recurring example (every Monday, 30 minutes):

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "Weekly plugin update pass",
    "description": "Update plugins and verify site health",
    "execution_date": "2026-09-01",
    "estimated_time": 30,
    "estimated_time_unit": "MINUTES",
    "is_recurring": true,
    "frequency": "WEEKLY",
    "type_frequency": "MONDAY",
    "specific_day": 1
  }' \
  "https://public-api.wp-umbrella.com/projects/<ID>/custom-works" \
  | jq '{code, id: .data.id, scheduledWorkId: .data.scheduledWorkId}'
```

The response is **synchronous** — there is no `processId` to poll. `code: "success"` with a `data.id` means the work is created. Recurring works also return a `scheduledWorkId`.

## Step 5 — report

Tell the user, per project:

- ✅ *"Custom work #25 'Weekly plugin update pass' created on <site> — recurring weekly on Monday, first run 2026-09-01"*
- Mention `scheduledWorkId` only for recurring works (it's what the dashboard uses to identify the series)
- For edits/deletions, point them to the WP Umbrella dashboard (Project → Maintenance / Custom works), or use the `PUT`/`DELETE` endpoints from the spec if they ask you to do it (see the Endpoint section)

## Error paths

| Response | What to do |
|---|---|
| `400` `bad_params` | A required field is missing or an enum value is wrong (e.g. `is_recurring` omitted, `HOUR` instead of `HOURS`, `specific_day` missing on a recurring work). Re-read the table above, fix, and retry — do not re-ask for confirmation if the intended work is unchanged. |
| `500` on create | Temporary API quirk ([#30](https://github.com/WP-Umbrella/umbrella-skill/issues/30)): the endpoint fails when `description` is absent. Verify nothing was created (dashboard, or `GET /projects/{projectId}/custom-works`), then retry the same payload with a `description` (per the Step 2 rule: ask the user for a one-liner, fall back to the work's `name`). |
| `401` `unauthorized_request` | Token missing/invalid → `references/auth.md` |
| `404` `not_found` | Wrong project ID → go back to Step 1 |
| Batch: one site fails | Report which sites succeeded and which failed; do not silently retry the failed ones |
