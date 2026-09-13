#!/usr/bin/env bash
# Symlink every skill in this repo into the device-level agent skill dirs.
# Idempotent. Run via: bash install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$HOME/.agents/skills"
CLAUDE_DIR="$HOME/.claude/skills"
mkdir -p "$AGENTS_DIR" "$CLAUDE_DIR"

# Validate frontmatter before linking anything: an unquoted YAML scalar cannot
# contain ": " — strict parsers then see no name or description at all.
fail=0
for skill in "$REPO_DIR"/skills/*/; do
  f="${skill}SKILL.md"
  if [ ! -f "$f" ]; then
    echo "ERROR: ${skill} has no SKILL.md" >&2; fail=1; continue
  fi
  awk -v file="$f" '
    /^---$/ { n++; if (n >= 2) exit; next }
    n == 1 && /^(name|description): / {
      key = substr($1, 1, length($1) - 1); seen[key] = 1
      v = substr($0, index($0, ": ") + 2)
      first = substr(v, 1, 1)
      if (v ~ /: / && first != "\"" && first != sprintf("%c", 39)) {
        printf "ERROR: %s: unquoted %s contains \": \" — breaks YAML\n", file, key > "/dev/stderr"
        bad = 1
      }
    }
    END {
      if (!("name" in seen))        { print "ERROR: " file ": frontmatter has no name"        > "/dev/stderr"; bad = 1 }
      if (!("description" in seen)) { print "ERROR: " file ": frontmatter has no description" > "/dev/stderr"; bad = 1 }
      exit bad ? 1 : 0
    }
  ' "$f" || fail=1
done
if [ "$fail" -ne 0 ]; then
  echo "nothing linked — fix the frontmatter above and re-run" >&2
  exit 1
fi

for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  ln -sfn "${skill%/}" "$AGENTS_DIR/$name"
  ln -sfn "$AGENTS_DIR/$name" "$CLAUDE_DIR/$name"
  echo "linked $name"
done
