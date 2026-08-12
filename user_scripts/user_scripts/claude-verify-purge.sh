#!/usr/bin/env bash
#
# claude-verify-purge.sh — independently verify that claude-purge-local.sh
# actually removed Claude Code's local chat history, transcripts and memory.
#
#   ./claude-verify-purge.sh          # human-readable report
#   ./claude-verify-purge.sh --json   # machine-readable
#
# Exit status: 0 = all checks passed, 1 = at least one FAIL, 2 = usage error.
# WARN does not fail the run — it flags data you chose to keep (backups) or
# things outside this script's reach (server-side org retention).
#
# This re-derives every check from the filesystem. It does not trust the
# receipt file the purge script wrote.
#
set -uo pipefail

CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"
NODEJS_CACHE="${HOME}/.cache/claude-cli-nodejs"

JSON_OUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUT=1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '2,16p' "$0"; exit 0; }
[[ -n "${1:-}" && $JSON_OUT -eq 0 ]] && { echo "unknown flag: $1" >&2; exit 2; }

FAILS=0
WARNS=0
PASSES=0
ROWS=()

record() { # status  check  detail
  local st="$1" name="$2" detail="$3"
  case "$st" in
    PASS) PASSES=$((PASSES+1)) ;;
    FAIL) FAILS=$((FAILS+1))  ;;
    WARN) WARNS=$((WARNS+1))  ;;
  esac
  ROWS+=("${st}|${name}|${detail}")
}

# --- 1. Directories that must be empty --------------------------------------
EMPTY_DIRS=(
  "${CLAUDE_DIR}/projects"
  "${CLAUDE_DIR}/sessions"
  "${CLAUDE_DIR}/session-env"
  "${CLAUDE_DIR}/file-history"
  "${CLAUDE_DIR}/paste-cache"
  "${CLAUDE_DIR}/shell-snapshots"
  "${CLAUDE_DIR}/tasks"
  "${CLAUDE_DIR}/todos"
  "${CLAUDE_DIR}/debug"
  "${CLAUDE_DIR}/backups"
  "${CLAUDE_DIR}/downloads"
  "${NODEJS_CACHE}"
)
for d in "${EMPTY_DIRS[@]}"; do
  label="dir empty: ${d/#$HOME/\~}"
  if [[ ! -d "$d" ]]; then
    record PASS "$label" "absent"
  else
    n=$(find "$d" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$n" -eq 0 ]]; then
      record PASS "$label" "empty"
    else
      sample=$(find "$d" -mindepth 1 2>/dev/null | head -3 | sed "s|$HOME|~|" | paste -sd', ' -)
      record FAIL "$label" "$n entries remain: $sample"
    fi
  fi
done

# --- 2. Files that must be gone ---------------------------------------------
GONE_FILES=(
  "${CLAUDE_DIR}/history.jsonl"
  "${CLAUDE_DIR}/stats-cache.json"
  "${CLAUDE_DIR}/mcp-needs-auth-cache.json"
)
for f in "${GONE_FILES[@]}"; do
  label="file gone: ${f/#$HOME/\~}"
  if [[ -e "$f" ]]; then
    record FAIL "$label" "still present ($(du -h "$f" 2>/dev/null | cut -f1))"
  else
    record PASS "$label" "removed"
  fi
done

# --- 3. Sweep for ANY surviving transcript ----------------------------------
# Transcripts are .jsonl; memory files are .md under a projects/*/memory dir.
STRAY_JSONL=$(find "$CLAUDE_DIR" -type f -name '*.jsonl' 2>/dev/null | sed "s|$HOME|~|")
if [[ -z "$STRAY_JSONL" ]]; then
  record PASS "no .jsonl transcripts under ~/.claude" "clean"
else
  record FAIL "no .jsonl transcripts under ~/.claude" \
    "$(echo "$STRAY_JSONL" | wc -l | tr -d ' ') found: $(echo "$STRAY_JSONL" | head -3 | paste -sd', ' -)"
fi

STRAY_MEM=$(find "$CLAUDE_DIR" -type d -name memory 2>/dev/null \
            -exec find {} -type f \; 2>/dev/null | sed "s|$HOME|~|")
if [[ -z "$STRAY_MEM" ]]; then
  record PASS "no memory files under ~/.claude" "clean"
else
  record FAIL "no memory files under ~/.claude" \
    "$(echo "$STRAY_MEM" | wc -l | tr -d ' ') found: $(echo "$STRAY_MEM" | head -3 | paste -sd', ' -)"
fi

# --- 4. ~/.claude.json key + path residue -----------------------------------
if [[ -f "$CLAUDE_JSON" ]]; then
  JSON_REPORT=$(TARGET="$CLAUDE_JSON" HOMEDIR="$HOME" python3 - <<'PY' 2>/dev/null
import json, os

path = os.environ["TARGET"]; home = os.environ["HOMEDIR"]
drop = ["projects", "githubRepoPaths", "skillUsage", "seenNotifications"]

try:
    with open(path) as fh:
        data = json.load(fh)
except Exception as exc:
    print(f"FAIL|unparseable: {exc}")
    raise SystemExit

left = [k for k in drop if k in data and data[k]]
if left:
    det = ", ".join(f"{k}({len(data[k]) if isinstance(data[k], (dict, list)) else 1})" for k in left)
    print(f"FAIL|history keys still present: {det}")
else:
    print("PASS|history keys absent")

# Any absolute path under $HOME left anywhere in the blob is a residual
# record of what was worked on.
hits = set()
def walk(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if isinstance(k, str) and k.startswith(home):
                hits.add(k)
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)
    elif isinstance(node, str) and node.startswith(home):
        hits.add(node)
walk(data)

if hits:
    print(f"WARN|{len(hits)} project paths remain in config: " +
          ", ".join(sorted(hits)[:3]).replace(home, "~"))
else:
    print("PASS|no project paths in config")
PY
)
  if [[ -z "$JSON_REPORT" ]]; then
    record FAIL "~/.claude.json inspection" "python3 check failed to run"
  else
    while IFS='|' read -r st detail; do
      [[ -z "$st" ]] && continue
      record "$st" "~/.claude.json: ${detail%%:*}" "$detail"
    done <<< "$JSON_REPORT"
  fi
else
  record PASS "~/.claude.json" "absent"
fi

# --- 5. Copies of the data that still exist on disk -------------------------
LEFTOVERS=()
[[ -f "${CLAUDE_JSON}.prepurge" ]] && LEFTOVERS+=("~/.claude.json.prepurge")
while IFS= read -r b; do
  [[ -n "$b" ]] && LEFTOVERS+=("${b/#$HOME/\~}")
done < <(find "$HOME" -maxdepth 1 -name 'claude-local-backup-*.tar.gz' 2>/dev/null)

if [[ ${#LEFTOVERS[@]} -eq 0 ]]; then
  record PASS "no purge backups left on disk" "clean"
else
  record WARN "no purge backups left on disk" \
    "still readable: $(printf '%s, ' "${LEFTOVERS[@]}" | sed 's/, $//')"
fi

# --- 6. Live process would repopulate ---------------------------------------
RUNNING="$(pgrep -a -f '(^|/)claude($| )' 2>/dev/null | grep -v 'claude-verify' || true)"
if [[ -z "$RUNNING" ]]; then
  record PASS "no Claude Code process running" "clean"
else
  record WARN "no Claude Code process running" \
    "$(echo "$RUNNING" | wc -l | tr -d ' ') live session(s) — they rewrite history on exit; re-verify after they close"
fi

# --- 7. Scope reminder ------------------------------------------------------
record WARN "server-side (team/org plan)" \
  "not verifiable from this machine — org retention is admin/Anthropic-controlled"

# --- Output -----------------------------------------------------------------
if [[ $JSON_OUT -eq 1 ]]; then
  printf '{\n  "checked_at": "%s",\n  "pass": %d, "fail": %d, "warn": %d,\n  "checks": [\n' \
    "$(date -Is)" "$PASSES" "$FAILS" "$WARNS"
  for i in "${!ROWS[@]}"; do
    IFS='|' read -r st name detail <<< "${ROWS[$i]}"
    esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
    printf '    {"status": "%s", "check": "%s", "detail": "%s"}%s\n' \
      "$st" "$(esc "$name")" "$(esc "$detail")" \
      "$([[ $i -lt $((${#ROWS[@]}-1)) ]] && echo ,)"
  done
  printf '  ],\n  "result": "%s"\n}\n' "$([[ $FAILS -eq 0 ]] && echo PASS || echo FAIL)"
else
  printf '\n\033[1mClaude Code local purge verification\033[0m  (%s)\n\n' "$(date -Is)"
  for row in "${ROWS[@]}"; do
    IFS='|' read -r st name detail <<< "$row"
    case "$st" in
      PASS) c='\033[32m' ;;
      FAIL) c='\033[31m' ;;
      WARN) c='\033[33m' ;;
    esac
    printf "  ${c}%-4s\033[0m %-46s %s\n" "$st" "$name" "$detail"
  done
  printf '\n  %d passed, %d failed, %d warnings\n' "$PASSES" "$FAILS" "$WARNS"
  if [[ $FAILS -eq 0 ]]; then
    printf '\n  \033[32mLocal deletion verified.\033[0m\n'
  else
    printf '\n  \033[31mLocal deletion incomplete.\033[0m Re-run claude-purge-local.sh --apply\n'
    printf '  with all Claude Code sessions closed.\n'
  fi
fi

[[ $FAILS -eq 0 ]] && exit 0 || exit 1
