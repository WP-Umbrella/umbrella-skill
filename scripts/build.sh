#!/usr/bin/env bash
#
# umbrella build — regenerates skills/ from src/.
#
# src/ is the canonical source of truth. Contributors edit there.
# The plugin loader (Claude Code, Cursor, etc.) reads from skills/, which is
# always built from src/ via this script.
#
# Build pipeline:
#   1. rm -rf skills/
#   2. cp -R src/skills skills/
#   3. run caveman compression on every .md file inside skills/
#   4. delete the .original.md sidecars caveman leaves behind
#
# Caveman mutates in place: compressing foo.md overwrites foo.md AND writes
# foo.original.md. NEVER run it on src/ — always on the copy under skills/.
#
# Compression backend: headless `claude -p "/caveman:compress <file>"`.
# Requires the caveman plugin installed in Claude Code AND a `claude` CLI on
# PATH. Set UMBRELLA_SKIP_COMPRESS=1 to short-circuit (pass-through copy).
#
# Usage:
#   ./scripts/build.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -d src/skills ]; then
  echo "ERROR: src/skills/ not found — nothing to build from." >&2
  exit 1
fi

echo "→ Regenerating skills/ from src/"

# 1. Clean the build output
rm -rf skills/

# 2. Mirror src/skills into skills/ (markdown + assets like openapi-public.json)
cp -R src/skills skills

# 3. Compression backend selection
SKIP_COMPRESS="${UMBRELLA_SKIP_COMPRESS:-0}"
if [ "$SKIP_COMPRESS" = "1" ]; then
  echo "  UMBRELLA_SKIP_COMPRESS=1 — skipping caveman compression"
elif ! command -v claude >/dev/null 2>&1; then
  echo "  WARN: 'claude' CLI not found on PATH — skipping caveman compression"
  SKIP_COMPRESS=1
fi

compress_file() {
  local file="$1"
  local abs_file
  abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

  echo "  · $file"
  # Headless invocation of the /caveman:compress slash command.
  # --permission-mode=acceptEdits lets the skill write its backup + compressed
  # output without an interactive prompt. stdout is noisy, keep it out of logs;
  # stderr passes through so caveman failures surface their underlying cause.
  if ! claude -p "/caveman:compress $abs_file" \
      --permission-mode=acceptEdits \
      >/dev/null; then
    echo "    ERROR: caveman compression failed for $file" >&2
    return 1
  fi
}

file_count=0
compressed_count=0
while IFS= read -r -d '' f; do
  file_count=$((file_count + 1))
  if [ "$SKIP_COMPRESS" = "1" ]; then
    continue
  fi
  compress_file "$f"
  compressed_count=$((compressed_count + 1))
done < <(find skills -type f -name '*.md' ! -name '*.original.md' -print0)

# 4. Remove the .original.md sidecars caveman wrote next to each compressed file.
find skills -type f -name '*.original.md' -delete 2>/dev/null || true

if [ "$SKIP_COMPRESS" = "1" ]; then
  echo "✓ Build complete — $file_count markdown file(s) copied (compression skipped)"
else
  echo "✓ Build complete — $compressed_count / $file_count markdown file(s) compressed"
fi
