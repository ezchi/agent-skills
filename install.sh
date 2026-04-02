#!/bin/bash

# Agent Skill & Command Installer

set -e

REPO_URL="https://github.com/ezchi/agent-skills.git"
GLOBAL=true
AGENT="gemini"
ALL_SKILLS=false
TEMP_DIR=""
CODEX_PLUGIN_NAME="hardware-agent-skills"

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --project    Install to current project (.gemini/, .claude/, or .codex/)"
    echo "  --global     Install to home directory (~/.gemini/, ~/.claude/, or ~/.codex/) [Default]"
    echo "  --all        Install all skills without prompting"
    echo "  --agent NAME Agent to install for (gemini, claude, codex) [Default: gemini]"
    echo "  --claude     Alias for --agent claude"
    echo "  --codex      Alias for --agent codex"
    echo "  --gemini     Alias for --agent gemini"
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
        --project) GLOBAL=false ;;
        --global) GLOBAL=true ;;
        --all) ALL_SKILLS=true ;;
        --claude) AGENT="claude" ;;
        --codex) AGENT="codex" ;;
        --gemini) AGENT="gemini" ;;
        --agent) AGENT="$2"; shift ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# Set installation path based on agent and scope
if [ "$AGENT" = "claude" ]; then
    BASE_DIR=".claude"
elif [ "$AGENT" = "codex" ]; then
    BASE_DIR=".codex"
else
    BASE_DIR=".gemini"
fi

if [ "$GLOBAL" = "true" ]; then
    INSTALL_PATH="$HOME/$BASE_DIR"
else
    INSTALL_PATH="./$BASE_DIR"
fi

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

if [ "$AGENT" = "codex" ]; then
    if [ "$GLOBAL" = "true" ]; then
        CODEX_PLUGIN_PARENT="$HOME/plugins"
        CODEX_MARKETPLACE_PATH="$HOME/.agents/plugins/marketplace.json"
    else
        CODEX_PLUGIN_PARENT="./plugins"
        CODEX_MARKETPLACE_PATH="./.agents/plugins/marketplace.json"
    fi

    CODEX_PLUGIN_PATH="$CODEX_PLUGIN_PARENT/$CODEX_PLUGIN_NAME"
    mkdir -p "$CODEX_PLUGIN_PATH/skills"
    mkdir -p "$CODEX_PLUGIN_PATH/commands"
    mkdir -p "$CODEX_PLUGIN_PATH/.codex-plugin"
    mkdir -p "$(dirname "$CODEX_MARKETPLACE_PATH")"
fi

# Find available skills (directories with SKILL.md), including generic skills such as release-management
SKILLS=$(find . -maxdepth 2 -name "SKILL.md" | xargs -n1 dirname | sed 's|^\./||' | sort | uniq)

for skill in $SKILLS; do
    # Skip the current directory if it somehow gets included
    if [ "$skill" == "." ]; then continue; fi

    if [ "$ALL_SKILLS" != "true" ]; then
        printf "Install skill '%s' for %s? [Y/n] " "$skill" "$AGENT"
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

    if [ "$AGENT" = "codex" ]; then
        CODEX_SKILL_TARGET="$CODEX_PLUGIN_PATH/skills/$skill"
        mkdir -p "$CODEX_SKILL_TARGET"

        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude='commands/' "$skill/" "$CODEX_SKILL_TARGET/"
        else
            cp -r "$skill"/* "$CODEX_SKILL_TARGET/"
            rm -rf "$CODEX_SKILL_TARGET/commands"
        fi
    fi
    
    # Copy commands if they exist
    if [ -d "$skill/commands" ]; then
        # Get absolute path to skills directory for path substitution
        ABS_SKILLS_DIR=$(mkdir -p "$INSTALL_PATH/skills" && cd "$INSTALL_PATH/skills" && pwd)

        if [ "$AGENT" = "gemini" ]; then
            echo "Installing Gemini commands for $skill..."
            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                dest_file="$INSTALL_PATH/commands/$(basename "$cmd_file")"
                # Replace __SKILLS_DIR__ placeholder with absolute path
                sed "s|__SKILLS_DIR__|$ABS_SKILLS_DIR|g" "$cmd_file" > "$dest_file"
            done
        elif [ "$AGENT" = "claude" ]; then
            echo "Installing Claude commands for $skill..."
            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                base="$(basename "$cmd_file" .toml)"
                dest_file="$INSTALL_PATH/commands/${base}.md"
                "$SCRIPT_DIR/toml_to_claude_cmd.sh" "$cmd_file" "$dest_file" "$ABS_SKILLS_DIR"
            done
        elif [ "$AGENT" = "codex" ]; then
            echo "Installing Codex commands for $skill..."
            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                base="$(basename "$cmd_file" .toml)"
                dest_file="$CODEX_PLUGIN_PATH/commands/${base}.md"
                "$SCRIPT_DIR/toml_to_codex_cmd.sh" "$cmd_file" "$dest_file" "$skill"
            done
        fi
    fi
    
    echo "Successfully installed $skill"
done

if [ "$AGENT" = "codex" ]; then
    cat > "$CODEX_PLUGIN_PATH/.codex-plugin/plugin.json" <<EOF
{
  "name": "$CODEX_PLUGIN_NAME",
  "version": "1.0.0",
  "description": "Hardware engineering skills and slash commands for SystemVerilog and Verilator workflows.",
  "author": {
    "name": "ezchi",
    "url": "https://github.com/ezchi"
  },
  "homepage": "https://github.com/ezchi/agent-skills",
  "repository": "https://github.com/ezchi/agent-skills",
  "license": "AGPL-3.0-only",
  "keywords": [
    "systemverilog",
    "verilator",
    "rtl",
    "verification",
    "hardware"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Hardware Agent Skills",
    "shortDescription": "SystemVerilog and Verilator workflows for Codex",
    "longDescription": "Adds reusable hardware engineering skills plus slash commands for SystemVerilog RTL design, testbench review, and Verilator compatibility checks.",
    "developerName": "ezchi",
    "category": "Coding",
    "capabilities": ["Interactive", "Write"],
    "websiteURL": "https://github.com/ezchi/agent-skills",
    "privacyPolicyURL": "https://openai.com/policies/privacy-policy/",
    "termsOfServiceURL": "https://openai.com/policies/terms-of-use/",
    "defaultPrompt": [
      "Review this SystemVerilog RTL for style and synthesis issues",
      "Generate a Verilator-friendly module and testbench",
      "Check this RTL for Verilator compatibility"
    ],
    "screenshots": [],
    "brandColor": "#0F766E"
  }
}
EOF
    python3 - "$CODEX_MARKETPLACE_PATH" "$CODEX_PLUGIN_NAME" <<'PY'
import json
import os
import sys

marketplace_path = sys.argv[1]
plugin_name = sys.argv[2]

entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": f"./plugins/{plugin_name}",
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Coding",
}

if os.path.exists(marketplace_path):
    with open(marketplace_path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
else:
    data = {
        "name": "local-skills",
        "interface": {
            "displayName": "Local Skills",
        },
        "plugins": [],
    }

plugins = [plugin for plugin in data.get("plugins", []) if plugin.get("name") != plugin_name]
plugins.append(entry)
data["plugins"] = plugins
data.setdefault("name", "local-skills")
data.setdefault("interface", {"displayName": "Local Skills"})
data["interface"].setdefault("displayName", "Local Skills")

with open(marketplace_path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
PY
fi

echo ""
echo "Installation complete!"
FULL_INSTALL_PATH=$(mkdir -p "$INSTALL_PATH" && cd "$INSTALL_PATH" && pwd)
echo "Skills and configurations installed for $AGENT to: $FULL_INSTALL_PATH"

if [ "$AGENT" = "gemini" ]; then
    echo "Run '/commands reload' in Gemini CLI to activate new slash commands."
elif [ "$AGENT" = "claude" ]; then
    echo "Slash commands installed to $FULL_INSTALL_PATH/commands/ — use /command-name in Claude Code."
elif [ "$AGENT" = "codex" ]; then
    echo "Skills installed to: $FULL_INSTALL_PATH/skills"
    echo "Codex plugin written to: $(cd "$CODEX_PLUGIN_PATH" && pwd)"
    echo "Open Codex CLI and run '/plugins' to install the local plugin '$CODEX_PLUGIN_NAME'."
fi
