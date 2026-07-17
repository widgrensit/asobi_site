#!/usr/bin/env bash
# Guards docs error tables against the controllers they claim to describe.
#
# An error table is a contract, and a client acts on it: asobi_site#90 shipped a
# guest table missing four atoms, one of them the retryable 409
# device_already_registered, which a client reading the docs would treat as
# fatal and fail a launch that a retry resolves. Both directions are checked -
# every atom the controller returns is documented, and every atom documented is
# reachable from source.
#
# Usage: scripts/check-error-drift.sh [ASOBI_DIR]
#   ASOBI_DIR is a checkout of widgrensit/asobi (default: the repo's sibling).
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
asobi="${1:-$(dirname "$repo_root")/asobi}"
views="$repo_root/src/views"
fail=0

# Every "<status> <atom>" pair a module returns. Newlines are flattened and runs
# of spaces squeezed first, so erlfmt reflowing a return across lines can never
# hide it from the regex.
src_pairs() {
	tr '\n' ' ' <"$1" | tr -s ' ' |
		grep -oE '\{json, ?[0-9]+, ?#\{\}, ?#\{ ?error => ~"[a-z_]+"' |
		sed -E 's/.*\{json, ?([0-9]+).*error => ~"([a-z_]+)"/\1 \2/'
}

# Every "<status> <atom>" row of an ASCII error table in a docs view. Leading
# whitespace is tolerated so a reflowed table fails loudly on a real mismatch
# rather than quietly parsing to nothing. Rows with a blank status column are
# continuation lines and carry no pair.
doc_pairs() {
	grep -oE '^ *[0-9]{3} +\| +[a-z_]+ ' "$1" |
		sed -E 's/^ *([0-9]{3}) +\| +([a-z_]+) /\1 \2/'
}

indent() {
	local line
	while IFS= read -r line; do printf '        %s\n' "$line"; done
}

# check_table <label> <view> <module...>
#
# Every listed module is authoritative: the table must document exactly the
# union of what they return, no more and no less. asobi_auth_error is shared
# with register/login, but every atom it can return on this path is one the
# endpoint can genuinely return, so it earns the same exactness as the
# controller. A new atom there failing this check is the point - a human should
# look, not have the table drift silently.
check_table() {
	local label="$1" view="$2"
	shift 2
	local f
	for f in "$view" "$@"; do
		if [ ! -f "$f" ]; then
			echo "  ?   $label - $f not found, skipped"
			return
		fi
	done

	local documented returned missing extra m
	documented=$(doc_pairs "$view" | sort -u)
	returned=$(
		for m in "$@"; do src_pairs "$m"; done | sort -u
	)

	if [ -z "$documented" ]; then
		echo "  !!  $label - no error table found in $(basename "$view")"
		fail=1
		return
	fi

	missing=$(comm -23 <(echo "$returned") <(echo "$documented"))
	extra=$(comm -13 <(echo "$returned") <(echo "$documented"))

	if [ -n "$missing" ]; then
		echo "  !!  $label - returned by source, undocumented:"
		echo "$missing" | indent
		fail=1
	fi
	if [ -n "$extra" ]; then
		echo "  !!  $label - documented, but no source returns it:"
		echo "$extra" | indent
		fail=1
	fi
	if [ -z "$missing$extra" ]; then
		echo "  OK  $label - $(echo "$documented" | wc -l) rows match source"
	fi
}

echo "== Guest auth =="
check_table "guest error table" \
	"$views/asobi_site_docs_auth_view.erl" \
	"$asobi/src/controllers/asobi_guest_controller.erl" \
	"$asobi/src/asobi_auth_error.erl"

# Add a check_table line above as other exhaustive error tables are written. A
# table that is deliberately partial ("common errors") must not be listed here -
# this guard reads every table as a complete contract.

echo
if [ "$fail" -ne 0 ]; then
	echo "DRIFT: a docs error table no longer matches the controller it describes."
	exit 1
fi
echo "OK: every documented error atom matches source."
