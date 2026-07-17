#!/usr/bin/env bash
# Fails if the committed docs views differ from a fresh regeneration off the
# asobi guides - i.e. a guide changed without regenerating, or a generated view
# was hand-edited. The generated modules carry a "do not edit by hand" header;
# this is what enforces it (ADR 0003).
#
# Fix a failure with: scripts/gen-docs.sh <asobi-checkout> && commit.
#
# Usage: scripts/check-generated-current.sh [ASOBI_DIR]
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
asobi="${1:-$(dirname "$repo_root")/asobi}"

if [ ! -d "$asobi/guides" ]; then
	echo "asobi guides not found at $asobi/guides" >&2
	exit 1
fi

# Deterministic regeneration writes only the generated view modules.
"$repo_root/scripts/gen-docs.sh" "$asobi" >/dev/null

if git -C "$repo_root" diff --quiet -- src/views/; then
	echo "OK: generated docs views are current with the asobi guides."
	exit 0
fi

echo "DRIFT: committed docs views differ from a fresh regeneration." >&2
echo "A guide changed without regenerating, or a generated view was hand-edited:" >&2
git -C "$repo_root" --no-pager diff --stat -- src/views/ >&2
echo "Fix: run scripts/gen-docs.sh <asobi-checkout> and commit the result." >&2
git -C "$repo_root" checkout -- src/views/ 2>/dev/null || true
exit 1
