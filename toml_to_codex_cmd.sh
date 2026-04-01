#!/bin/bash

# Convert a Gemini CLI slash command (.toml) to a Codex plugin command (.md).
#
# Usage:
#   toml_to_codex_cmd.sh <input.toml> <output.md> <skill_name>
#
# Transformations applied:
#   - Extracts the description value for YAML frontmatter
#   - Extracts the prompt block between triple-quote delimiters
#   - Replaces {{args}} with $ARGUMENTS
#   - Rewrites !{cat __SKILLS_DIR__/...} to relative plugin paths like skills/<skill>/...

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename "$0") <input.toml> <output.md> <skill_name>" >&2
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
SKILL_NAME="$3"

if [ ! -f "$INPUT" ]; then
    echo "Error: input file not found: $INPUT" >&2
    exit 1
fi

DESCRIPTION=$(sed -n 's/^description = "\(.*\)"/\1/p' "$INPUT" | head -n 1)
TITLE=$(basename "$OUTPUT" .md)

{
    echo "---"
    printf 'description: %s\n' "$DESCRIPTION"
    echo "argument-hint: [file-or-request]"
    echo "allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]"
    echo "---"
    echo
    printf '# %s\n' "$TITLE"
    echo
    echo "## Arguments"
    echo
    echo "The user invoked this command with: \$ARGUMENTS"
    echo
    echo "## Instructions"
    echo
    awk '/^prompt = """/{found=1; next} found && /^"""/{found=0; next} found{print}' "$INPUT" \
        | sed 's/{{args}}/$ARGUMENTS/g' \
        | sed "s|!{cat __SKILLS_DIR__/|\`|g" \
        | sed 's|}|`|g' \
        | sed "s|\`$SKILL_NAME/|\`skills/$SKILL_NAME/|g"
} > "$OUTPUT"
