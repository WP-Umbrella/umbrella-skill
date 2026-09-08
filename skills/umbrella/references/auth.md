# Authentication

umbrella calls the WP Umbrella Public API with a **Bearer token** tied to your account. The token grants the same access you have in the dashboard — treat it like a password.

## Getting a token

1. Sign in at https://app.wp-umbrella.com
2. Go to your **Profile → Public API (for developers)**
3. Generate a new token with the `public_api` scope
4. Copy it immediately — most UIs only show tokens once

> ⚠️ **Don't confuse this with the connection key.** The Public API token (Profile → Public API for developers) is an *account-level* developer token that authenticates this plugin against the Public API. It is **not** the dashboard↔plugin **connection key** used to link an individual WordPress site to WP Umbrella. Using the connection key here will fail — and pasting the wrong secret around is a security risk.

## Storing the token

umbrella checks three sources, in order of priority. **Pick the one that matches your setup.**

### Option A — Native Claude Code plugin config (best for Claude users)

If you install umbrella via the plugin marketplace:

```
/plugin marketplace add wp-umbrella/umbrella-skill
/plugin install umbrella@wp-umbrella
```

Claude Code prompts you for the token at install time. The input is hidden, and the value is stored in your **OS keychain** — macOS Keychain, Windows Credential Manager, or Linux Secret Service. Nothing lands in plaintext on disk.

**Lifecycle:**
- Survives `/plugin update` and `/plugin disable` + `/plugin enable`
- Deleted on `/plugin uninstall`
- To change it: uninstall + reinstall, or `/plugin configure umbrella` if your Claude Code version supports it

### Option B — Dotfile at `~/.umbrella/token` (for non-Claude agents, or if you prefer files)

Run these three commands, replacing `PASTE_YOUR_TOKEN_HERE`:

```bash
mkdir -p ~/.umbrella
echo "PASTE_YOUR_TOKEN_HERE" > ~/.umbrella/token
chmod 600 ~/.umbrella/token
```

The dot-prefixed folder follows the UNIX convention for user-level credentials — same pattern as `~/.aws/`, `~/.ssh/`, `~/.docker/`. The `chmod 600` restricts the file to your user only.

**Why `~/.umbrella/` and not something at your project root:** your WP Umbrella token is a *user* credential (like your GitHub or AWS token), not project config. Keeping it in `~/.umbrella/` means it travels with you across every project, and — critically — it cannot be `git commit`ed by accident.

**Paranoid variant** (keeps the token out of shell history):

```bash
mkdir -p ~/.umbrella && \
  read -s -p "Paste your WP Umbrella token: " T && \
  echo "$T" > ~/.umbrella/token && \
  chmod 600 ~/.umbrella/token && \
  echo && echo "✓ Token saved"
```

### Option C — Environment variable (CI, ephemeral shells)

```bash
export WP_UMBRELLA_TOKEN="your-token-here"
```

Useful for CI pipelines, Docker containers, or one-off sessions where you don't want to persist anything. **Never** commit this into a repo-local `.env`.

## What NOT to do

- **Never paste the token into chat** with the AI. The plugin is designed so the AI reads it from your environment or keychain — pasting leaks it into conversation history and any telemetry that follows.
- **Never commit the token to git.** The `.gitignore` already ignores `.umbrella/` and `.env*`, but double-check on new repos.
- **Never share it in screenshots** or copy it into shared docs.

## Verifying the token works

```bash
curl -sS -H "Authorization: Bearer $WP_UMBRELLA_TOKEN" \
  https://public-api.wp-umbrella.com/projects?per_page=1
```

Expected: `{"code":"success","data":[...]}`.

If you get:

| Response | Cause | Fix |
|---|---|---|
| `401 unauthorized_request` | Token missing, wrong, or expired | Re-check the source you're using; regenerate in the dashboard |
| `403` | Token valid but lacks `public_api` scope | Regenerate with the correct scope |
| Connection refused / timeout | Network or firewall issue | Check your connection; verify the base URL |
| HTML login page | You hit the wrong host (`app.wp-umbrella.com`) | Use `public-api.wp-umbrella.com` |

## Revoking a token

If you suspect the token is compromised:

1. Go to *Profile → Public API (for developers)* in your dashboard
2. Revoke the exposed token
3. Generate a fresh one
4. Update wherever you stored it (replay Option A, B, or C above)
