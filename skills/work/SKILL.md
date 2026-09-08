---
name: work
description: Power-user shortcut to log or schedule a custom maintenance work (one-time or recurring) on a WP Umbrella project. Invoke as /umbrella:work <site> <what you did / want scheduled>.
user-invocable: true
argument-hint: <site> <description of the work, duration, optional recurrence>
---

# /umbrella:work

Shortcut to the custom-work-scheduling workflow. Follow `skills/umbrella/workflows/maintenance/custom-work-scheduling.md` end-to-end with `$ARGUMENTS` as the user's request.

## Argument handling

- The **first token** is the site (name fragment or numeric project ID) → Step 1 of the workflow
- Everything after it describes the work: name, duration, date, recurrence → Step 2
- If `$ARGUMENTS` is empty, ask the user in one message for: site, what the work is, how long it took/takes, when, and whether it recurs

Examples:

| Invocation | Interpreted as |
|---|---|
| `/umbrella:work acme 2h SEO work today` | one-time, 2 HOURS, today |
| `/umbrella:work 123 monthly content review on the 1st, 1h` | recurring MONTHLY, specific_day 1, 1 HOURS |
| `/umbrella:work acme weekly plugin pass every monday 30min` | recurring WEEKLY, MONDAY, 30 MINUTES |

Multi-word site names get split (only the first token is the site — same behavior as `/umbrella:sites` and `/umbrella:health`): tell the user to pass a distinctive name fragment or the numeric project ID instead.

Creating a custom work is a **mutation** — always present the plan and wait for explicit confirmation (workflow Step 3) before the POST.

## Setup

Before the first call this session, make sure the token is resolved (see `skills/umbrella/SKILL.md` section 1). If no token is present, stop and walk the user through `skills/umbrella/references/auth.md`. Do **not** ask them to paste the token into chat.

## Arguments received

`$ARGUMENTS`
