#!/usr/bin/env bash
# Regenerate the docs view modules that are single-sourced from guides.
# See docs/adr/0003 in the asobi repo: each page is generated from the repo
# whose CI can verify its claims - asobi for the library pages, asobi_lua for
# the Lua-runtime pages.
#
# Usage: scripts/gen-docs.sh [ASOBI_DIR] [ASOBI_LUA_DIR]
#   defaults: the repo's siblings ../asobi and ../asobi_lua
#
# Manifest columns: repo | guide-basename | module | page-id | title | breadcrumb | tab-slug
#   repo is `asobi` or `asobi_lua` - selects which checkout's guides/ to read.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
asobi="${1:-$(dirname "$repo_root")/asobi}"
asobi_lua="${2:-$(dirname "$repo_root")/asobi_lua}"
gen="$repo_root/scripts/gen-doc-view.mjs"
views="$repo_root/src/views"

for d in "$asobi/guides" "$asobi_lua/guides"; do
	[ -d "$d" ] || {
		echo "guides not found at $d" >&2
		exit 1
	}
done

# repo | guide | module | id | title | breadcrumb | slug
manifest=$(
	cat <<'EOF'
asobi|authentication|asobi_site_docs_auth_view|docs-auth|Authentication — Asobi docs|Authentication|auth
asobi|security-threat-model|asobi_site_docs_security_threat_model_view|docs-sec-threat|Threat model — Asobi docs|Security / Threat model|threat
asobi|websocket-protocol|asobi_site_docs_websocket_view|docs-ws|WebSocket protocol — Asobi docs|Protocols / WebSocket|ws
asobi|rest-api|asobi_site_docs_rest_view|docs-rest|REST API — Asobi docs|Protocols / REST|rest
asobi|matchmaking|asobi_site_docs_matchmaking_view|docs-matchmaking|Matchmaking — Asobi docs|Matchmaking|mm
asobi|economy|asobi_site_docs_economy_view|docs-economy|Economy & IAP — Asobi docs|Economy|econ
asobi|voting|asobi_site_docs_voting_view|docs-voting|Voting — Asobi docs|Voting|vote
asobi|world-server|asobi_site_docs_world_server_view|docs-world-server|World server — Asobi docs|World server|world
asobi|configuration|asobi_site_docs_configuration_view|docs-configuration|Configuration — Asobi docs|Configuration|config
asobi|security-auth|asobi_site_docs_security_auth_view|docs-sec-auth|Auth & rate limiting — Asobi docs|Security / Authentication & rate limiting|secauth
asobi|clustering|asobi_site_docs_clustering_view|docs-clustering|Clustering — Asobi docs|Clustering|cluster
asobi|security-known-limitations|asobi_site_docs_security_known_limits_view|docs-sec-known|Known limitations — Asobi docs|Security / Known limitations|seclim
asobi_lua|lua-bots|asobi_site_docs_lua_bots_view|docs-lua-bots|Lua bots — Asobi docs|Lua / Bots|luabots
asobi_lua|security-sandbox|asobi_site_docs_security_lua_sandbox_view|docs-sec-lua-sandbox|Lua sandbox — Asobi docs|Security / Lua sandbox|luasandbox
asobi_lua|security-trust-model|asobi_site_docs_security_lua_trust_view|docs-sec-lua-trust|Lua trust model — Asobi docs|Security / Lua trust model|luatrust
asobi_lua|security-known-limitations|asobi_site_docs_security_lua_known_limits_view|docs-sec-lua-known|Lua known limitations — Asobi docs|Security / Lua known limitations|lualim
EOF
)

count=0
while IFS='|' read -r repo guide mod id title crumb slug; do
	[ -z "$repo" ] && continue
	case "$repo" in
	asobi) guides_dir="$asobi/guides" ;;
	asobi_lua) guides_dir="$asobi_lua/guides" ;;
	*)
		echo "  !! $guide - unknown repo '$repo'" >&2
		exit 1
		;;
	esac
	src="$guides_dir/${guide}.md"
	out="$views/${mod}.erl"
	if [ ! -f "$src" ]; then
		echo "  !! $guide - $src not found" >&2
		exit 1
	fi
	node "$gen" "$src" "$mod" "$id" "$title" "$crumb" "$slug" >"$out"
	echo "  ok $repo/$guide -> $(basename "$out")"
	count=$((count + 1))
done <<<"$manifest"

# erlfmt the generated modules so `rebar3 fmt --check` in CI stays green. The
# generator emits valid but unformatted boilerplate around a triple-quoted HTML
# blob; erlfmt leaves the blob alone and tidies the boilerplate, converging in
# one pass. Run without file args - the erlfmt `files` globs in rebar.config
# cover src/**, and passing explicit paths alongside the `write` option is a no-op.
if [ "$count" -gt 0 ]; then
	(cd "$repo_root" && rebar3 fmt >/dev/null 2>&1)
fi

echo "generated $count view(s)"
