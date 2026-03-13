#!/bin/bash

# Gemini Skill & Command Installer

set -e

REPO_URL="https://github.com/ezchi/agent-skills.git"
INSTALL_PATH="$HOME/.gemini"
GLOBAL=true
TEMP_DIR=""

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --project    Install to current project (.gemini/)"
    echo "  --global     Install to home directory (~/.gemini/) [Default]"
    echo "  --all        Install all skills without prompting"
    echo "  --help       Show this help message"
}

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

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

# Check if we are in the repo or need to clone it
if [ ! -f "install.sh" ] || [ $(find . -maxdepth 2 -name "SKILL.md" | wc -l) -eq 0 ]; then
    echo "Skills not found locally. Preparing remote installation..."
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required for remote installation."
        exit 1
    fi
    TEMP_DIR=$(mktemp -d)
    echo "Cloning repository to $TEMP_DIR..."
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
fi

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
    
    # Copy skill files
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
    # Resolve relative path for clear reporting
    FULL_PATH=$(mkdir -p "$INSTALL_PATH" && cd "$INSTALL_PATH" && pwd)
    echo "Skills and commands installed to $FULL_PATH"
fi
echo "Run '/commands reload' in Gemini CLI to activate new slash commands."
