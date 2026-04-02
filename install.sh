#!/bin/bash

# Agent Skill & Command Installer

set -e

REPO_URL="https://github.com/ezchi/agent-skills.git"
GLOBAL=true
AGENT="gemini"
ALL_SKILLS=false
TEMP_DIR=""
CODEX_PLUGIN_NAME="hardware-agent-skills"
AGENTS=""
INSTALLED_PATHS=""
CODEX_PLUGIN_PATH=""

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --project    Install to current project (.gemini/, .claude/, or .codex/)"
    echo "  --global     Install to home directory (~/.gemini/, ~/.claude/, or ~/.codex/) [Default]"
    echo "  --all        Install all skills without prompting"
    echo "  --agent NAME Agent to install for (gemini, claude, codex, all) [Default: gemini]"
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

set_agent_paths() {
    local agent="$1"

    if [ "$agent" = "claude" ]; then
        BASE_DIR=".claude"
    elif [ "$agent" = "codex" ]; then
        BASE_DIR=".codex"
    else
        BASE_DIR=".gemini"
    fi

    if [ "$GLOBAL" = "true" ]; then
        INSTALL_PATH="$HOME/$BASE_DIR"
    else
        INSTALL_PATH="./$BASE_DIR"
    fi

    if [ "$agent" = "codex" ]; then
        if [ "$GLOBAL" = "true" ]; then
            CODEX_PLUGIN_PARENT="$HOME/plugins"
            CODEX_MARKETPLACE_PATH="$HOME/.agents/plugins/marketplace.json"
        else
            CODEX_PLUGIN_PARENT="./plugins"
            CODEX_MARKETPLACE_PATH="./.agents/plugins/marketplace.json"
        fi

        CODEX_PLUGIN_PATH="$CODEX_PLUGIN_PARENT/$CODEX_PLUGIN_NAME"
    fi
}

prepare_agent_dirs() {
    local agent="$1"

    set_agent_paths "$agent"

    mkdir -p "$INSTALL_PATH/skills"
    mkdir -p "$INSTALL_PATH/commands"

    if [ "$agent" = "codex" ]; then
        mkdir -p "$CODEX_PLUGIN_PATH/skills"
        mkdir -p "$CODEX_PLUGIN_PATH/commands"
        mkdir -p "$CODEX_PLUGIN_PATH/.codex-plugin"
        mkdir -p "$(dirname "$CODEX_MARKETPLACE_PATH")"
    fi
}

install_skill_for_agent() {
    local agent="$1"
    local skill="$2"
    local script_dir
    local abs_skills_dir

    set_agent_paths "$agent"

    echo "Installing $skill for $agent..."

    SKILL_TARGET="$INSTALL_PATH/skills/$skill"
    mkdir -p "$SKILL_TARGET"

    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude='commands/' "$skill/" "$SKILL_TARGET/"
    else
        cp -r "$skill"/* "$SKILL_TARGET/"
        rm -rf "$SKILL_TARGET/commands"
    fi

    if [ "$agent" = "codex" ]; then
        CODEX_SKILL_TARGET="$CODEX_PLUGIN_PATH/skills/$skill"
        mkdir -p "$CODEX_SKILL_TARGET"

        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude='commands/' "$skill/" "$CODEX_SKILL_TARGET/"
        else
            cp -r "$skill"/* "$CODEX_SKILL_TARGET/"
            rm -rf "$CODEX_SKILL_TARGET/commands"
        fi
    fi

    if [ -d "$skill/commands" ]; then
        abs_skills_dir=$(mkdir -p "$INSTALL_PATH/skills" && cd "$INSTALL_PATH/skills" && pwd)
        script_dir="$(cd "$(dirname "$0")" && pwd)"

        if [ "$agent" = "gemini" ]; then
            echo "Installing Gemini commands for $skill..."
            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                dest_file="$INSTALL_PATH/commands/$(basename "$cmd_file")"
                sed "s|__SKILLS_DIR__|$abs_skills_dir|g" "$cmd_file" > "$dest_file"
            done
        elif [ "$agent" = "claude" ]; then
            echo "Installing Claude commands for $skill..."
            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                base="$(basename "$cmd_file" .toml)"
                dest_file="$INSTALL_PATH/commands/${base}.md"
                "$script_dir/toml_to_claude_cmd.sh" "$cmd_file" "$dest_file" "$abs_skills_dir"
            done
        elif [ "$agent" = "codex" ]; then
            echo "Installing Codex commands for $skill..."
            for cmd_file in "$skill/commands"/*.toml; do
                [ -e "$cmd_file" ] || continue
                base="$(basename "$cmd_file" .toml)"
                dest_file="$CODEX_PLUGIN_PATH/commands/${base}.md"
                "$script_dir/toml_to_codex_cmd.sh" "$cmd_file" "$dest_file" "$skill"
            done
        fi
    fi

    echo "Successfully installed $skill for $agent"
}

write_codex_plugin() {
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
        --agent)
            if [ -z "$2" ]; then
                echo "Error: --agent requires a value."
                usage
                exit 1
            fi
            AGENT="$2"
            shift
            ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

case "$AGENT" in
    gemini|claude|codex) AGENTS="$AGENT" ;;
    all) AGENTS="gemini claude codex" ;;
    *)
        echo "Error: unsupported agent '$AGENT'."
        usage
        exit 1
        ;;
esac

# Check if we are in the repo or need to clone it
if [ ! -f "install.sh" ] || [ "$(find . -maxdepth 2 -name "SKILL.md" | wc -l)" -eq 0 ]; then
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

for agent in $AGENTS; do
    prepare_agent_dirs "$agent"
done

# Find available skills (directories with SKILL.md), including generic skills such as release-management
SKILLS=$(find . -maxdepth 2 -name "SKILL.md" | xargs -n1 dirname | sed 's|^\./||' | sort | uniq)

for skill in $SKILLS; do
    if [ "$skill" = "." ]; then
        continue
    fi

    if [ "$ALL_SKILLS" != "true" ]; then
        printf "Install skill '%s' for %s? [Y/n] " "$skill" "$AGENTS"
        read -r confirm
        if [[ $confirm =~ ^[Nn] ]]; then
            continue
        fi
    fi

    for agent in $AGENTS; do
        install_skill_for_agent "$agent" "$skill"
    done
done

for agent in $AGENTS; do
    set_agent_paths "$agent"
    full_install_path=$(mkdir -p "$INSTALL_PATH" && cd "$INSTALL_PATH" && pwd)
    INSTALLED_PATHS="${INSTALLED_PATHS}${agent}:${full_install_path}
"

    if [ "$agent" = "codex" ]; then
        write_codex_plugin
    fi
done

echo ""
echo "Installation complete!"
printf "%s" "$INSTALLED_PATHS" | while IFS=: read -r agent path; do
    [ -n "$agent" ] || continue
    echo "Skills and configurations installed for $agent to: $path"

    if [ "$agent" = "gemini" ]; then
        echo "Run '/commands reload' in Gemini CLI to activate new slash commands."
    elif [ "$agent" = "claude" ]; then
        echo "Slash commands installed to $path/commands/ - use /command-name in Claude Code."
    elif [ "$agent" = "codex" ]; then
        echo "Skills installed to: $path/skills"
        echo "Codex plugin written to: $(cd "$CODEX_PLUGIN_PATH" && pwd)"
        echo "Open Codex CLI and run '/plugins' to install the local plugin '$CODEX_PLUGIN_NAME'."
    fi
done
