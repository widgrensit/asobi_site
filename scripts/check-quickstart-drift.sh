#!/usr/bin/env bash
# Guards the SDK quickstart pages against calling symbols that no longer exist
# in their client SDKs (the drift that shipped a fictional Godot API and a
# non-compiling Unity snippet - asobi_site#87).
#
# For each engine it extracts the SDK call sites from the quickstart view and
# checks every method/signal/event resolves in the sibling SDK repo. Heuristic
# and scoped to symbols reached through the SDK client, so engine builtins are
# never flagged.
#
# Usage: scripts/check-quickstart-drift.sh [SDK_BASE_DIR]
#   SDK_BASE_DIR holds the asobi-<engine> repos (default: the repo's parent dir).
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
sdk_base="${1:-$(dirname "$repo_root")}"
views="$repo_root/src/views"
fail=0

# check <label> <symbol> <sdk_dir> <grep-extended-regex>
check() {
	local label="$1" sym="$2" dir="$3" re="$4"
	if [ ! -d "$dir" ]; then
		echo "  ? $label $sym - SDK repo $dir not found, skipped"
		return
	fi
	if grep -qrE "$re" "$dir"; then
		echo "  OK  $label $sym"
	else
		echo "  !!  $label $sym - not found in $(basename "$dir")"
		fail=1
	fi
}

# extract <view> <extended-regex> <sed-capture>
extract() {
	grep -oE "$2" "$1" | sed -E "$3" | sort -u
}

echo "== Godot =="
gv="$views/asobi_site_docs_quickstart_godot_view.erl"
gsdk="$sdk_base/asobi-godot"
for m in $(extract "$gv" "(auth|realtime)\.[a-z_]+\(" 's/.*\.([a-z_]+)\(/\1/'); do
	check "method" "$m" "$gsdk" "func $m\b"
done
for s in $(extract "$gv" "\.[a-z_]+\.connect\(" 's/\.([a-z_]+)\.connect\(/\1/'); do
	check "signal" "$s" "$gsdk" "signal $s\b"
done

echo "== Unity =="
uv="$views/asobi_site_docs_quickstart_unity_view.erl"
usdk="$sdk_base/asobi-unity"
for m in $(extract "$uv" "_client\.(Auth|Realtime|Matchmaker)\.[A-Za-z]+\(" 's/.*\.([A-Za-z]+)\(/\1/'); do
	check "method" "$m" "$usdk" "public .*\b$m\s*\("
done
for e in $(extract "$uv" "\.On[A-Za-z]+ *[-+]=" 's/.*\.(On[A-Za-z]+) *[-+]=/\1/'); do
	check "event" "$e" "$usdk" "event .*\b$e\b"
done

echo "== Defold =="
dv="$views/asobi_site_docs_quickstart_defold_view.erl"
dsdk="$sdk_base/asobi-defold"
for m in $(extract "$dv" "asobi\.[a-z_]+\(" 's/asobi\.([a-z_]+)\(/\1/'); do
	check "method" "$m" "$dsdk" "function M[.:]$m\b"
done
for m in $(extract "$dv" "\.auth\.[a-z_]+\(" 's/.*\.auth\.([a-z_]+)\(/\1/'); do
	check "auth" "$m" "$dsdk" "function M[.:]$m\b"
done
for m in $(extract "$dv" "realtime:[a-z_]+\(" 's/realtime:([a-z_]+)\(/\1/'); do
	check "realtime" "$m" "$dsdk" "function M[.:]$m\b"
done

echo
if [ "$fail" -ne 0 ]; then
	echo "DRIFT: a quickstart calls an SDK symbol that no longer exists. Fix the page or the reference."
	exit 1
fi
echo "OK: every SDK symbol cited by the quickstarts resolves."
