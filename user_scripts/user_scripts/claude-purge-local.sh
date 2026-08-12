#!/usr/bin/env bash
#
# claude-purge-local.sh — delete Claude Code chat transcripts, prompt history,
# memory files and derived caches stored on THIS machine.
#
#   ./claude-purge-local.sh                # dry run (default) — shows what would go
#   ./claude-purge-local.sh --apply        # actually delete
#   ./claude-purge-local.sh --apply --backup   # tar.gz everything first, then delete
#
# SCOPE — this is a LOCAL purge only.
#   You are on a team/org plan. Deleting these files does NOT delete anything
#   Anthropic holds server-side. Conversation retention on org plans is governed
#   by your workspace's data-retention settings and is an admin/Anthropic-side
#   action. Ask your org admin or Anthropic support for server-side deletion.
#
# WHAT IS KEPT ON PURPOSE:
#   ~/.claude/.credentials.json   auth (you stay logged in)
#   ~/.claude/settings*.json      your config
#   ~/.claude/plugins, skills     installed extensions
#   ~/.local/share/claude/versions installed CLI binaries (844M, not user data)
#   CLAUDE.md files inside your repos — those live in your projects, not here.
#
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"
NODEJS_CACHE="${HOME}/.cache/claude-cli-nodejs"
RECEIPT="${CLAUDE_DIR}/.purge-receipt.json"

APPLY=0
BACKUP=0
BACKUP_DIR="${HOME}/claude-local-backup-$(date +%Y%m%d-%H%M%S)"

for arg in "$@"; do
  case "$arg" in
    --apply)  APPLY=1 ;;
    --backup) BACKUP=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --- Directories/files that hold conversation or memory data -----------------
# Contents are removed; the directory itself is recreated empty.
PURGE_DIRS=(
  "${CLAUDE_DIR}/projects"        # chat transcripts (*.jsonl) AND memory/ dirs
  "${CLAUDE_DIR}/sessions"        # session state
  "${CLAUDE_DIR}/session-env"     # per-session environment snapshots
  "${CLAUDE_DIR}/file-history"    # pre-edit copies of your files
  "${CLAUDE_DIR}/paste-cache"     # pasted text/images
  "${CLAUDE_DIR}/shell-snapshots" # captured shell environments
  "${CLAUDE_DIR}/tasks"           # background task transcripts
  "${CLAUDE_DIR}/todos"           # todo lists (older versions)
  "${CLAUDE_DIR}/debug"           # debug logs
  "${CLAUDE_DIR}/backups"         # Claude's own file backups
  "${CLAUDE_DIR}/downloads"
  "${NODEJS_CACHE}"               # per-project MCP server logs
)

PURGE_FILES=(
  "${CLAUDE_DIR}/history.jsonl"           # every prompt you have typed
  "${CLAUDE_DIR}/stats-cache.json"        # usage stats
  "${CLAUDE_DIR}/mcp-needs-auth-cache.json"
  "${CLAUDE_DIR}/.last-update-result.json"
)

# Keys stripped from ~/.claude.json. `projects` is a map keyed by absolute
# project path — the key list alone is a record of what you worked on.
JSON_KEYS_TO_DROP='["projects","githubRepoPaths","skillUsage","seenNotifications"]'

# ---------------------------------------------------------------------------
say()  { printf '%b\n' "$*"; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

if [[ $APPLY -eq 0 ]]; then
  say "\033[33mDRY RUN\033[0m — nothing will be deleted. Re-run with --apply to commit."
fi

# --- Refuse to run while Claude Code is live --------------------------------
# A running session rewrites history.jsonl / projects/ on exit and would
# resurrect part of what you just deleted.
step "Checking for running Claude Code processes"
RUNNING="$(pgrep -a -f '(^|/)claude($| )' 2>/dev/null | grep -v 'claude-purge' || true)"
if [[ -n "$RUNNING" ]]; then
  say "$RUNNING"
  say ""
  say "\033[31mClaude Code is running.\033[0m Exit every session (including the one you"
  say "may be reading this from) before using --apply, or deleted files will be"
  say "rewritten when those sessions shut down."
  [[ $APPLY -eq 1 ]] && { say "Aborting."; exit 1; }
else
  say "none found — good."
fi

# --- Inventory --------------------------------------------------------------
step "Targets"
TOTAL_BYTES=0
for d in "${PURGE_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    sz=$(du -sk "$d" 2>/dev/null | cut -f1); n=$(find "$d" -type f 2>/dev/null | wc -l)
    TOTAL_BYTES=$((TOTAL_BYTES + sz))
    printf '  %-45s %6s KB  %5s files\n' "${d/#$HOME/\~}" "$sz" "$n"
  fi
done
for f in "${PURGE_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    sz=$(du -k "$f" 2>/dev/null | cut -f1)
    TOTAL_BYTES=$((TOTAL_BYTES + sz))
    printf '  %-45s %6s KB  %5s files\n' "${f/#$HOME/\~}" "$sz" "1"
  fi
done
printf '  %-45s %6s KB\n' "TOTAL" "$TOTAL_BYTES"
say ""
say "  ~/.claude.json  — will drop keys: ${JSON_KEYS_TO_DROP}"

# --- Backup -----------------------------------------------------------------
if [[ $BACKUP -eq 1 ]]; then
  step "Backup -> ${BACKUP_DIR}.tar.gz"
  if [[ $APPLY -eq 1 ]]; then
    mkdir -p "$BACKUP_DIR"
    for p in "${PURGE_DIRS[@]}" "${PURGE_FILES[@]}" "$CLAUDE_JSON"; do
      [[ -e "$p" ]] && cp -a "$p" "$BACKUP_DIR/" 2>/dev/null || true
    done
    tar czf "${BACKUP_DIR}.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
    rm -rf "$BACKUP_DIR"
    chmod 600 "${BACKUP_DIR}.tar.gz"
    say "wrote ${BACKUP_DIR}.tar.gz"
    say "\033[33mNote:\033[0m this archive contains everything you are deleting. Move it"
    say "off-box or delete it once you're satisfied."
  else
    say "(dry run — no archive written)"
  fi
fi

# --- Delete -----------------------------------------------------------------
step "Deleting"
for d in "${PURGE_DIRS[@]}"; do
  [[ -d "$d" ]] || continue
  if [[ $APPLY -eq 1 ]]; then
    find "$d" -mindepth 1 -delete 2>/dev/null || rm -rf "${d:?}"/* "${d:?}"/.[!.]* 2>/dev/null || true
    mkdir -p "$d"
    say "  cleared  ${d/#$HOME/\~}"
  else
    say "  would clear  ${d/#$HOME/\~}"
  fi
done
for f in "${PURGE_FILES[@]}"; do
  [[ -f "$f" ]] || continue
  if [[ $APPLY -eq 1 ]]; then
    rm -f "$f"; say "  removed  ${f/#$HOME/\~}"
  else
    say "  would remove  ${f/#$HOME/\~}"
  fi
done

# --- Prune ~/.claude.json ---------------------------------------------------
step "Pruning ~/.claude.json"
if [[ -f "$CLAUDE_JSON" ]]; then
  APPLY=$APPLY DROP="$JSON_KEYS_TO_DROP" TARGET="$CLAUDE_JSON" python3 - <<'PY'
import json, os, shutil

path  = os.environ["TARGET"]
drop  = set(json.loads(os.environ["DROP"]))
apply = os.environ["APPLY"] == "1"

with open(path) as fh:
    data = json.load(fh)

present = [k for k in drop if k in data]
if not present:
    print("  nothing to drop — already clean")
elif not apply:
    for k in present:
        v = data[k]
        n = len(v) if isinstance(v, (dict, list)) else 1
        print(f"  would drop  {k}  ({n} entries)")
else:
    shutil.copy2(path, path + ".prepurge")
    os.chmod(path + ".prepurge", 0o600)
    for k in present:
        del data[k]
    tmp = path + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=2)
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)
    print("  dropped: " + ", ".join(present))
    print(f"  pre-purge copy at {path}.prepurge — delete it once verified")
PY
else
  say "  ~/.claude.json not present"
fi

# --- Receipt ----------------------------------------------------------------
if [[ $APPLY -eq 1 ]]; then
  printf '{"purged_at":"%s","host":"%s","user":"%s"}\n' \
    "$(date -Is)" "$(hostname)" "$(id -un)" > "$RECEIPT"
  chmod 600 "$RECEIPT"
fi

step "Done"
if [[ $APPLY -eq 1 ]]; then
  say "Local Claude Code chat history, transcripts and memory removed."
  say "Verify with:  ${0%/*}/claude-verify-purge.sh"
  say ""
  say "\033[1mServer side:\033[0m on a team/org plan this script cannot touch data held by"
  say "Anthropic. Request deletion through your workspace admin / Anthropic support."
else
  say "Dry run complete. Re-run with --apply (add --backup to archive first)."
fi
