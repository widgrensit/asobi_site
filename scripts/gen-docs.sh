#!/usr/bin/env bash
# Regenerate the docs view modules that are single-sourced from asobi guides.
# See docs/adr/0003 in the asobi repo: each page is generated from the repo
# whose CI can verify its claims. This driver holds the asobi-owned pages.
#
# Usage: scripts/gen-docs.sh [ASOBI_DIR]
#   ASOBI_DIR is a checkout of widgrensit/asobi (default: the repo's sibling).
#
# The manifest below is the source of truth for which guide maps to which view.
# Columns: guide-basename | module | page-id | title | breadcrumb | tab-slug
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
asobi="${1:-$(dirname "$repo_root")/asobi}"
gen="$repo_root/scripts/gen-doc-view.mjs"
views="$repo_root/src/views"

if [ ! -d "$asobi/guides" ]; then
	echo "asobi guides not found at $asobi/guides" >&2
	exit 1
fi

# guide | module | id | title | breadcrumb | slug
manifest=$(
	cat <<'EOF'
authentication|asobi_site_docs_auth_view|docs-auth|Authentication — Asobi docs|Authentication|auth
security-threat-model|asobi_site_docs_security_threat_model_view|docs-sec-threat|Threat model — Asobi docs|Security / Threat model|threat
websocket-protocol|asobi_site_docs_websocket_view|docs-ws|WebSocket protocol — Asobi docs|Protocols / WebSocket|ws
rest-api|asobi_site_docs_rest_view|docs-rest|REST API — Asobi docs|Protocols / REST|rest
matchmaking|asobi_site_docs_matchmaking_view|docs-matchmaking|Matchmaking — Asobi docs|Matchmaking|mm
economy|asobi_site_docs_economy_view|docs-economy|Economy & IAP — Asobi docs|Economy|econ
voting|asobi_site_docs_voting_view|docs-voting|Voting — Asobi docs|Voting|vote
world-server|asobi_site_docs_world_server_view|docs-world-server|World server — Asobi docs|World server|world
configuration|asobi_site_docs_configuration_view|docs-configuration|Configuration — Asobi docs|Configuration|config
security-auth|asobi_site_docs_security_auth_view|docs-sec-auth|Auth & rate limiting — Asobi docs|Security / Authentication & rate limiting|secauth
EOF
)

count=0
while IFS='|' read -r guide mod id title crumb slug; do
	[ -z "$guide" ] && continue
	src="$asobi/guides/${guide}.md"
	out="$views/${mod}.erl"
	if [ ! -f "$src" ]; then
		echo "  !! $guide - $src not found" >&2
		exit 1
	fi
	node "$gen" "$src" "$mod" "$id" "$title" "$crumb" "$slug" >"$out"
	echo "  ok $guide -> $(basename "$out")"
	count=$((count + 1))
done <<<"$manifest"

# erlfmt the generated modules so `rebar3 fmt --check` in CI stays green. The
# generator emits valid but unformatted boilerplate around a triple-quoted HTML
# blob; erlfmt leaves the blob alone and tidies the boilerplate, converging in
# one pass, so the committed output is stable across regenerations. Run without
# file args - the erlfmt `files` globs in rebar.config cover src/**, and passing
# explicit paths alongside the `write` option is a no-op.
if [ "$count" -gt 0 ]; then
	(cd "$repo_root" && rebar3 fmt >/dev/null 2>&1)
fi

echo "generated $count view(s)"
