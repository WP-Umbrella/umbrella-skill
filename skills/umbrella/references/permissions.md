# Reducing permission prompts

By default, Claude Code asks your approval before every Bash command it runs — every `curl`, `jq`, `head`. This is safety-first behavior, but for a tool like umbrella that makes several API calls per request, it quickly gets noisy.

This guide shows how to trust umbrella's common read-only operations once, **without** weakening the safety gate on mutations (plugin updates, DB optimizations, etc.).

## Why this stays safe

The umbrella skill explicitly instructs Claude to **always confirm with you before any mutating call** (POST, PUT, DELETE). The allowlist below only covers **read-only** traffic (listing sites, fetching vulnerabilities, polling process status). State-changing actions continue to stop for your explicit approval — that gate lives in the skill itself, not in the permissions file.

## Option 1 — Automatic, tailored (recommended)

Claude Code ships with a built-in skill called `fewer-permission-prompts`. It:

1. Scans your recent Claude Code transcripts
2. Identifies commands you've repeatedly approved
3. Generates a prioritized allowlist scoped to your real usage
4. Writes it to your project's `.claude/settings.json`

Inside Claude Code, type:

```
/fewer-permission-prompts
```

Review what it proposes, approve, done. This is the cleanest path because the allowlist matches exactly what Claude actually runs — no guessing, no over-scoping.

## Option 2 — Manual allowlist (set it up once)

If you want to frontload the config before you ever see a prompt, add this to `~/.claude/settings.json` (global — applies across every project):

```json
{
  "permissions": {
    "allow": [
      "Bash(curl -sS -H \"Authorization: Bearer *\" https://public-api.wp-umbrella.com/*)",
      "Bash(jq *)",
      "Bash(head -n *)"
    ]
  }
}
```

This auto-approves:

- **`curl`** requests only to `public-api.wp-umbrella.com` carrying a Bearer token (nothing else — `curl` to any other host still prompts)
- **`jq`** for parsing JSON responses
- **`head`** (used by the token resolver)

All other Bash commands — and any `curl` to a different host — continue to require explicit approval.

### Where to put it

| File | Scope | Committed to git ? |
|---|---|---|
| `~/.claude/settings.json` | Global — all your projects | No |
| `<project>/.claude/settings.json` | This project, shared with your team | Yes |
| `<project>/.claude/settings.local.json` | This project, just you | No (gitignored) |

For umbrella, which operates on your **user-level** WP Umbrella account rather than on a specific codebase, **global** (`~/.claude/settings.json`) is usually the right scope.

## Verifying

After saving the settings file, restart Claude Code and run:

```
/umbrella:health
```

The underlying curl calls should execute without prompting.

If a prompt still appears:
1. Check the exact Bash command Claude is trying to run (shown in the prompt)
2. Adjust the pattern in your allowlist to match
3. Or fall back to Option 1 (`/fewer-permission-prompts`) — it generates patterns calibrated to what Claude actually runs

## Reverting

Remove the relevant entries from `permissions.allow` in your settings file. Next session, you're back to explicit prompts on every command.
