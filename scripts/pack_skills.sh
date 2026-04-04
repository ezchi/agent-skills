#!/bin/bash

# Path to the official packaging script
PACKAGER="/opt/homebrew/lib/node_modules/@google/gemini-cli/node_modules/@google/gemini-cli-core/dist/src/skills/builtin/skill-creator/scripts/package_skill.cjs"
DIST_DIR="./dist"

# Ensure the output directory exists
mkdir -p "$DIST_DIR"

# Function to package a single skill
package_one() {
    local skill_path=$1
    # Remove trailing slash if present
    skill_path=${skill_path%/}
    
    if [ -f "$skill_path/SKILL.md" ]; then
        echo "--- Packaging: $skill_path ---"
        node "$PACKAGER" "$skill_path" "$DIST_DIR"
    else
        echo "Error: '$skill_path' is not a valid skill directory (missing SKILL.md)"
        return 1
    fi
}

# Main logic
if [ -z "$1" ] || [ "$1" == "all" ]; then
    echo "Scanning for all skills in the repository..."
    # Find all directories containing a SKILL.md file, excluding the dist folder and hidden dirs
    find ./skills -maxdepth 2 -name "SKILL.md" -not -path "*/.*" | while read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        # Strip the './' prefix for cleaner output
        skill_dir=${skill_dir#./}
        package_one "$skill_dir"
    done
else
    package_one "$1"
fi

echo ""
echo "Done! Packaged skills are available in: $DIST_DIR"
ls -1 "$DIST_DIR"
