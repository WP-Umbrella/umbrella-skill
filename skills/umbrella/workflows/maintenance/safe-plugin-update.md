# Workflow — safe plugin update

Full playbook for updating plugins on a production WordPress site through the WP Umbrella API. Use this whenever the user asks to update plugins and hasn't explicitly asked for a quick/unsafe path.

## Preconditions

- Token present (resolved per SKILL.md section 1 — `$CLAUDE_PLUGIN_OPTION_token`, `$WP_UMBRELLA_TOKEN`, or `~/.umbrella/token`)
- User has identified **which project** to operate on (by name or ID)

If the project is identified by name, resolve the ID first:

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects?per_page=100" \
  | jq '.data[] | select(.name | test("<NAME>"; "i")) | {id, name, base_url}'
```

## Step 1 — site health snapshot

Before touching anything, check the site is not already broken:

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects/<ID>" \
  | jq '{
      name, base_url,
      is_currently_down,
      latest_ping,
      wp_version: .warnings.wordpress_version,
      php_version: .warnings.php_current_version,
      wp_up_to_date: .warnings.is_up_to_date,
      last_sync: .last_synchronization.date_with_success
    }'
```

**Abort if:** `is_currently_down == true` — updating a down site risks worsening the state. Report to the user and suggest bringing the site back first.

## Step 2 — list outdated plugins

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects/<ID>/plugins?per_page=200" \
  | jq '[.data[] | select(.need_update and (.need_update | length > 0)) | {
      name, key,
      current: .version,
      next: .need_update.new_version,
      requires_php: .need_update.requires_php,
      is_active
    }]'
```

## Step 3 — cross-reference vulnerabilities

Prioritize plugins that are **both outdated and vulnerable**:

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects/<ID>/vulnerabilities" \
  | jq '.data.plugin_vulnerabilities[] | {
      name: .plugin.name,
      version: .plugin.version,
      latest: .plugin.latest_version,
      worst_cvss: ([.vulnerabilities[].cvss_score] | max),
      fixed_in: .vulnerabilities[-1].version_fixed_in
    }'
```

## Step 4 — present the plan to the user

Summarize to the user as a table:

```
Project: <name> (ID <id>)
Plugin                    Current → Next       Risk
─────────────────────────────────────────────────────
wp-seopress/seopress.php  7.5.1   → 7.6.0      low
woocommerce/woocommerce   8.2.0   → 8.3.1      ⚠ CVE (CVSS 7.5)
...

Proposed: SAFE_UPDATE mode with clear_cache=true.
Proceed? (yes/no)
```

**Wait for explicit confirmation.** Do not proceed on ambiguous replies.

## Step 5 — trigger the update

```bash
UPDATE_RESPONSE=$(mktemp)
curl -sS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "plugin_keys": ["wp-seopress/seopress.php", "woocommerce/woocommerce"],
    "update_type": "SAFE_UPDATE",
    "clear_cache": true,
    "advanced_safe_update_validation": false
  }' \
  "https://public-api.wp-umbrella.com/projects/<ID>/plugins/update" \
  | tee "$UPDATE_RESPONSE"

PROCESS_ID=$(jq -r '.data.processId' "$UPDATE_RESPONSE")
echo "Tracking process: $PROCESS_ID"
```

## Step 6 — poll until complete

```bash
for i in $(seq 1 24); do   # 24 × 5s = 2 min max
  STATUS=$(curl -sS -H "Authorization: Bearer $TOKEN" \
    "https://public-api.wp-umbrella.com/projects/<ID>/processes?per_page=20" \
    | jq -r ".data[] | select(.id==\"$PROCESS_ID\") | .code // empty")
  if [ -n "$STATUS" ]; then
    echo "Process finished with code: $STATUS"
    break
  fi
  sleep 5
done
```

If the loop times out, tell the user the update is still queued and give them the `processId` to check later with `GET /projects/<ID>/processes` (same endpoint as the poll).

## Step 7 — verify and report

Fetch the finalized process details:

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects/<ID>/processes?per_page=20" \
  | jq ".data[] | select(.id==\"$PROCESS_ID\") | {
      type,
      code,
      entity_name: .entities.name,
      old: .entities.old_version,
      new: .entities.version,
      http_status: .entities_result.status_code,
      visual_diff_percent: .entities_result.visual_regression.diff_percent
    }"
```

Report to the user:

- ✅ / ❌ per plugin (based on `code`)
- `http_status` — anything other than 200 is a red flag
- `visual_diff_percent` — above ~5% deserves human eyes on the site

## Step 8 — site re-check

Quick post-update health check:

```bash
curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://public-api.wp-umbrella.com/projects/<ID>" \
  | jq '{is_currently_down, latest_ping, count_php_issues}'
```

If `is_currently_down == true` post-update, this is a regression — surface it immediately and suggest the user review or roll back from their WP Umbrella backups.
