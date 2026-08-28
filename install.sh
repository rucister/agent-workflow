#!/usr/bin/env bash
# Symlink every skill in this repo into the device-level agent skill dirs.
# Idempotent. Run via: bash install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$HOME/.agents/skills"
CLAUDE_DIR="$HOME/.claude/skills"
mkdir -p "$AGENTS_DIR" "$CLAUDE_DIR"

for skill in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill")"
  ln -sfn "${skill%/}" "$AGENTS_DIR/$name"
  ln -sfn "$AGENTS_DIR/$name" "$CLAUDE_DIR/$name"
  echo "linked $name"
done
