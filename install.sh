#!/bin/bash

# Gemini Skill & Command Installer

set -e

# Default to global installation
INSTALL_PATH="$HOME/.gemini"
GLOBAL=true

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --project    Install to current project (.gemini/)"
    echo "  --global     Install to home directory (~/.gemini/) [Default]"
    echo "  --all        Install all skills without prompting"
    echo "  --help       Show this help message"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) INSTALL_PATH="./.gemini"; GLOBAL=false ;;
        --global) INSTALL_PATH="$HOME/.gemini"; GLOBAL=true ;;
        --all) ALL_SKILLS=true ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

mkdir -p "$INSTALL_PATH/skills"
mkdir -p "$INSTALL_PATH/commands"

# Find available skills (directories with SKILL.md)
SKILLS=$(find . -maxdepth 2 -name "SKILL.md" | xargs -n1 dirname | sed 's|^\./||' | sort | uniq)

for skill in $SKILLS; do
    # Skip the current directory if it somehow gets included
    if [ "$skill" == "." ]; then continue; fi

    if [ "$ALL_SKILLS" != "true" ]; then
        printf "Install skill '%s'? [Y/n] " "$skill"
        read -r confirm
        if [[ $confirm =~ ^[Nn] ]]; then
            continue
        fi
    fi

    echo "Installing skill: $skill..."
    
    # Target directory for the skill
    SKILL_TARGET="$INSTALL_PATH/skills/$skill"
    mkdir -p "$SKILL_TARGET"
    
    # Copy skill files (using a temporary directory to avoid copying the command folder into the skill target)
    # We use rsync if available, otherwise cp -r and manual cleanup
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude='commands/' "$skill/" "$SKILL_TARGET/"
    else
        cp -r "$skill"/* "$SKILL_TARGET/"
        rm -rf "$SKILL_TARGET/commands"
    fi
    
    # Copy commands if they exist
    if [ -d "$skill/commands" ]; then
        echo "Installing commands for $skill..."
        cp -r "$skill/commands/"* "$INSTALL_PATH/commands/"
    fi
    
    echo "Successfully installed $skill"
done

echo ""
echo "Installation complete!"
if [ "$GLOBAL" = "true" ]; then
    echo "Skills and commands installed to $HOME/.gemini"
else
    echo "Skills and commands installed to $INSTALL_PATH"
fi
echo "Run '/commands reload' in Gemini CLI to activate new slash commands."
