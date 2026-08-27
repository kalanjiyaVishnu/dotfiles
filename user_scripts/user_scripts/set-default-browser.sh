#!/usr/bin/env bash
#
# set-default-browser.sh — set the default web browser on Linux, correctly.
#
#   ./set-default-browser.sh                  # show current defaults + available browsers
#   ./set-default-browser.sh list             # list installed browsers only
#   ./set-default-browser.sh get              # show current handler for each scheme
#   ./set-default-browser.sh set firefox      # set Firefox as default (fuzzy name match)
#   ./set-default-browser.sh set firefox --mailto     # also route mailto: to it
#   ./set-default-browser.sh set org.mozilla.firefox.desktop   # exact desktop-file id
#
# WHY THIS EXISTS
#   `xdg-settings set default-web-browser firefox.desktop` fails SILENTLY when
#   that desktop file does not exist. Flatpak browsers are registered under their
#   reverse-DNS app id — Firefox is `org.mozilla.firefox.desktop`, never
#   `firefox.desktop` — so the obvious command looks like it worked and changed
#   nothing. This script resolves a friendly name to the real desktop id,
#   sets every handler a browser actually needs (not just the one xdg-settings
#   touches), and verifies the result instead of trusting the exit code.
#
# WHAT IT SETS
#   default-web-browser (via xdg-settings) plus these MIME/scheme handlers:
#     x-scheme-handler/http, x-scheme-handler/https,
#     x-scheme-handler/about, x-scheme-handler/unknown,
#     text/html, application/xhtml+xml
#   `mailto:` is left alone unless you pass --mailto, because a mail client is a
#   separate choice. If mailto currently points at some *other browser*, the
#   script says so rather than quietly leaving a stale handler behind.
#
# NOTE
#   Running apps cache the handler at startup — restart them to pick up a change.
#
set -euo pipefail

# --- pretty output (disabled when not a tty) ---------------------------------
if [ -t 1 ]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GRN=$'\e[32m'; YEL=$'\e[33m'; RST=$'\e[0m'
else
  BOLD=; DIM=; RED=; GRN=; YEL=; RST=
fi

die()  { echo "${RED}error:${RST} $*" >&2; exit 1; }
warn() { echo "${YEL}warn:${RST}  $*" >&2; }
ok()   { echo "${GRN}✓${RST} $*"; }

# Handlers a browser should own. Deliberately excludes text/xml — that is
# commonly bound to an editor on purpose, and a browser has no business
# stealing it.
HANDLERS=(
  x-scheme-handler/http
  x-scheme-handler/https
  x-scheme-handler/about
  x-scheme-handler/unknown
  text/html
  application/xhtml+xml
)

# --- desktop-file discovery --------------------------------------------------

# Echo every directory that can hold .desktop files, per the XDG spec plus the
# flatpak export dirs (which are usually in XDG_DATA_DIRS but not always).
app_dirs() {
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local data_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  {
    echo "$data_home/applications"
    echo "$data_dirs" | tr ':' '\n' | sed 's:/*$::;s:$:/applications:'
    echo "/var/lib/flatpak/exports/share/applications"
    echo "$data_home/flatpak/exports/share/applications"
  } | awk 'NF && !seen[$0]++'
}

# Absolute path of a desktop id, searching in XDG precedence order (first wins).
find_desktop_file() {
  local id="$1" dir
  while IFS= read -r dir; do
    [ -r "$dir/$id" ] && { echo "$dir/$id"; return 0; }
  done < <(app_dirs)
  return 1
}

# Read a key from the [Desktop Entry] group only — later action groups
# ("New Window", "Private Window") repeat Name= and Exec= and would otherwise win.
desktop_key() {
  local file="$1" key="$2"
  awk -F= -v k="$key" '
    /^\[/  { inentry = ($0 == "[Desktop Entry]") ; next }
    inentry && $1 == k { sub("^" k "=", ""); print; exit }
  ' "$file"
}

# Every installed browser, as "<desktop-id>\t<display name>".
# A browser is anything declaring it can handle http(s) URLs.
list_browsers() {
  local dir file id name
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    for file in "$dir"/*.desktop; do
      [ -r "$file" ] || continue
      grep -qi '^MimeType=.*x-scheme-handler/https\?' "$file" || continue
      [ "$(desktop_key "$file" NoDisplay)" = "true" ] && continue
      id="$(basename "$file")"
      name="$(desktop_key "$file" Name)"
      printf '%s\t%s\n' "$id" "${name:-$id}"
    done
  done < <(app_dirs) | sort -u -t$'\t' -k1,1
}

# Resolve a user-supplied name ("firefox", "Firefox", "org.mozilla.firefox.desktop")
# to exactly one desktop id. Prints the id, or explains the ambiguity and exits.
resolve_browser() {
  local query="$1" matches

  # Exact desktop id, if it exists and is real.
  if [[ "$query" == *.desktop ]] && find_desktop_file "$query" >/dev/null; then
    echo "$query"; return 0
  fi

  local browsers; browsers="$(list_browsers)"
  [ -n "$browsers" ] || die "no browsers found on this system"

  # Match against desktop id or display name, case-insensitively.
  matches="$(awk -F'\t' -v q="${query,,}" '
    { id = tolower($1); nm = tolower($2)
      sub(/\.desktop$/, "", id)
      if (id == q || nm == q) { print "0\t" $0; next }        # exact
      if (index(id, q) || index(nm, q)) print "1\t" $0        # substring
    }' <<<"$browsers")"

  [ -n "$matches" ] || die "no installed browser matches '$query' — try: $0 list"

  # Prefer exact matches (rank 0) over substring matches (rank 1).
  local best; best="$(sort -t$'\t' -k1,1 <<<"$matches" | head -1 | cut -f1)"
  matches="$(awk -F'\t' -v r="$best" '$1 == r' <<<"$matches")"

  if [ "$(wc -l <<<"$matches")" -gt 1 ]; then
    echo "${RED}error:${RST} '$query' is ambiguous:" >&2
    awk -F'\t' '{ printf "         %-40s %s\n", $2, $3 }' <<<"$matches" >&2
    echo "       re-run with the exact desktop id." >&2
    exit 1
  fi
  cut -f2 <<<"$matches"
}

# --- commands ----------------------------------------------------------------

cmd_list() {
  echo "${BOLD}Installed browsers${RST}"
  local current; current="$(xdg-settings get default-web-browser 2>/dev/null || true)"
  while IFS=$'\t' read -r id name; do
    if [ "$id" = "$current" ]; then
      printf '  %s%-42s%s %s%s (current default)%s\n' "$BOLD" "$id" "$RST" "$GRN" "$name" "$RST"
    else
      printf '  %-42s %s%s%s\n' "$id" "$DIM" "$name" "$RST"
    fi
  done < <(list_browsers)
}

cmd_get() {
  echo "${BOLD}Current defaults${RST}"
  printf '  %-28s %s\n' "default-web-browser" "$(xdg-settings get default-web-browser 2>/dev/null || echo '(unset)')"
  local m
  for m in "${HANDLERS[@]}" x-scheme-handler/mailto; do
    printf '  %-28s %s\n' "$m" "$(xdg-mime query default "$m" 2>/dev/null || echo '(unset)')"
  done
}

cmd_set() {
  local query="${1:-}" want_mailto="${2:-0}"
  [ -n "$query" ] || die "usage: $0 set <browser> [--mailto]"

  local id; id="$(resolve_browser "$query")"
  local file; file="$(find_desktop_file "$id")" || die "desktop file '$id' vanished"
  local name; name="$(desktop_key "$file" Name)"

  echo "${BOLD}Setting default browser → ${name:-$id}${RST} ${DIM}($id)${RST}"
  echo "${DIM}  $file${RST}"
  echo

  # xdg-settings can fail silently on some desktops, so verify rather than
  # trusting the exit code.
  xdg-settings set default-web-browser "$id" 2>/dev/null || true

  local mimes=("${HANDLERS[@]}")
  [ "$want_mailto" = "1" ] && mimes+=(x-scheme-handler/mailto)
  xdg-mime default "$id" "${mimes[@]}"

  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" 2>/dev/null || true

  # --- verify ---
  local failed=0 got
  got="$(xdg-settings get default-web-browser 2>/dev/null || true)"
  if [ "$got" = "$id" ]; then
    ok "default-web-browser"
  else
    echo "${RED}✗${RST} default-web-browser is '${got:-unset}', expected '$id'"; failed=1
  fi

  local m
  for m in "${mimes[@]}"; do
    got="$(xdg-mime query default "$m" 2>/dev/null || true)"
    if [ "$got" = "$id" ]; then
      ok "$m"
    else
      echo "${RED}✗${RST} $m is '${got:-unset}', expected '$id'"; failed=1
    fi
  done

  # If we did not touch mailto, flag it only when it points at a *different
  # browser* — that is a stale leftover, not a deliberate mail-client choice.
  if [ "$want_mailto" != "1" ]; then
    got="$(xdg-mime query default x-scheme-handler/mailto 2>/dev/null || true)"
    if [ -n "$got" ] && [ "$got" != "$id" ] && list_browsers | cut -f1 | grep -qxF "$got"; then
      echo
      warn "mailto: still opens '$got' — pass --mailto to move it too."
    fi
  fi

  [ "$failed" -eq 0 ] || die "some handlers did not apply (see ✗ above)"

  echo
  echo "${DIM}Already-running apps cache the handler — restart them to pick this up.${RST}"
}

# --- dispatch ----------------------------------------------------------------

main() {
  command -v xdg-mime     >/dev/null 2>&1 || die "xdg-mime not found (install xdg-utils)"
  command -v xdg-settings >/dev/null 2>&1 || die "xdg-settings not found (install xdg-utils)"

  case "${1:-}" in
    -h|--help|help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    list|ls)        cmd_list ;;
    get|status)     cmd_get ;;
    set)
      shift
      local target= mailto=0 arg
      for arg in "$@"; do
        case "$arg" in
          --mailto) mailto=1 ;;
          -*)       die "unknown flag: $arg" ;;
          *)        [ -n "$target" ] && die "too many arguments: $arg"; target="$arg" ;;
        esac
      done
      cmd_set "$target" "$mailto"
      ;;
    "")             cmd_get; echo; cmd_list ;;
    *)              die "unknown command '$1' — try: $0 --help" ;;
  esac
}

main "$@"
