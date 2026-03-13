#!/bin/bash

# Convert a Gemini CLI slash command (.toml) to a Claude Code slash command (.md).
#
# Usage:
#   toml_to_claude_cmd.sh <input.toml> <output.md> <skills_dir>
#
# Transformations applied:
#   - Extracts the prompt block between triple-quote delimiters
#   - Replaces {{args}} with $ARGUMENTS  (Claude's argument placeholder)
#   - Strips !{cat PATH} inlining wrappers, leaving the bare path
#     (Claude reads referenced files at runtime via the Read tool)
#   - Replaces __SKILLS_DIR__ with the provided skills_dir path

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename "$0") <input.toml> <output.md> <skills_dir>" >&2
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
SKILLS_DIR="$3"

if [ ! -f "$INPUT" ]; then
    echo "Error: input file not found: $INPUT" >&2
    exit 1
fi

awk '/^prompt = """/{found=1; next} found && /^"""/{found=0; next} found{print}' "$INPUT" \
    | sed 's/{{args}}/$ARGUMENTS/g' \
    | sed "s|!{cat \([^}]*\)}|\1|g" \
    | sed "s|__SKILLS_DIR__|$SKILLS_DIR|g" \
    > "$OUTPUT"
