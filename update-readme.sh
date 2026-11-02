#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# The custom RSS template renders the five latest published posts as Markdown.
# Use a clean destination so a missing output cannot reuse a stale article list.
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
hugo --minify --enableGitInfo --destination "$build_dir"

python3 - "$build_dir/index.xml" <<'PYTHON'
from pathlib import Path
import sys

readme = Path("README.md")
start = "<!-- START_DYNAMIC_CONTENT -->"
end = "<!-- END_DYNAMIC_CONTENT -->"
original = readme.read_text()
if original.count(start) != 1 or original.count(end) != 1:
    raise SystemExit("README must contain exactly one pair of dynamic content markers")
before, remainder = original.split(start)
if end not in remainder:
    raise SystemExit("README dynamic content markers are out of order")
_, after = remainder.split(end)
articles = Path(sys.argv[1]).read_text().strip()
updated = before + start + "\n" + articles + "\n" + end + after
if updated != original:
    readme.write_text(updated)
    print("Updated README article list.")
else:
    print("Article list is unchanged.")
PYTHON
