#!/usr/bin/env bash
# Fails if the committed docs views differ from a fresh regeneration off the
# asobi guides - i.e. a guide changed without regenerating, or a generated view
# was hand-edited. The generated modules carry a "do not edit by hand" header;
# this is what enforces it (ADR 0003).
#
# Fix a failure with: scripts/gen-docs.sh <asobi> <asobi_lua> && commit.
#
# Usage: scripts/check-generated-current.sh [ASOBI_DIR] [ASOBI_LUA_DIR]
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
asobi="${1:-$(dirname "$repo_root")/asobi}"
asobi_lua="${2:-$(dirname "$repo_root")/asobi_lua}"

for d in "$asobi/guides" "$asobi_lua/guides"; do
	[ -d "$d" ] || {
		echo "guides not found at $d" >&2
		exit 1
	}
done

# Deterministic regeneration writes only the generated view modules.
"$repo_root/scripts/gen-docs.sh" "$asobi" >/dev/null

if git -C "$repo_root" diff --quiet -- src/views/; then
	echo "OK: generated docs views are current with the guides."
	exit 0
fi

echo "DRIFT: committed docs views differ from a fresh regeneration." >&2
echo "A guide changed without regenerating, or a generated view was hand-edited:" >&2
git -C "$repo_root" --no-pager diff --stat -- src/views/ >&2
echo "Fix: run scripts/gen-docs.sh <asobi-checkout> and commit the result." >&2

# The regeneration above wrote into the working tree, so leave it there: it IS
# the fix, and a developer who just ran gen-docs.sh should not have it thrown
# away by the check that told them to run it. This used to `git checkout --
# src/views/`, which silently reverted both the regeneration and any hand edit
# to a view in the same directory.
#
# CI gets a fresh checkout per job, so nothing there needed restoring either.
exit 1
