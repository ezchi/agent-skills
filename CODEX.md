# CODEX.md

This file provides guidance to Codex CLI when working with code in this repository.

## Project Overview

This repository is a collection of modular **Agent Skills** for Gemini CLI, Claude Code, and Codex CLI, targeting hardware engineers working with SystemVerilog, RTL design, and Verilator-based verification.

Each skill lives in its own top-level directory and consists of a `SKILL.md` (persona + procedures), `assets/` (templates), `references/` (style guides/docs), `commands/` (source TOML slash command definitions), and optionally `scripts/`.

## Skills in This Repository

| Skill                    | Purpose                                             | Depends On                                  |
|--------------------------|-----------------------------------------------------|---------------------------------------------|
| `systemverilog-core`     | RTL design, FSMs, modules, interfaces               | —                                           |
| `systemverilog-tests`    | SV testbench generation                             | `systemverilog-core`                        |
| `cocotb-verilator-tests` | Python/Cocotb testbench generation                  | —                                           |
| `verilator`              | Verilator-specific SV constraints and C++ debugging | —                                           |
| `verilator-cmake`        | CMake build system generation for Verilator         | `systemverilog-core`, `systemverilog-tests` |
| `verilator-simflow`      | End-to-end simulation and regression workflows      | `verilator-cmake`, `systemverilog-tests`    |

## Installation Commands

```bash
# Install all skills to Codex global (~/.codex/) and generate a local plugin
./install.sh --codex --all

# Install to current project (.codex/) and generate a repo-local plugin
./install.sh --codex --project

# Install for Claude Code globally
./install.sh --claude --all

# Install for Gemini CLI globally
./install.sh --all

# Package Gemini .skill bundles into ./dist/
./pack_skills.sh
```

After Codex installation:

1. Skills are copied into `.codex/skills/` or `~/.codex/skills/`.
2. A local plugin is generated at `plugins/hardware-agent-skills/` or `~/plugins/hardware-agent-skills/`.
3. The local Codex marketplace manifest is created or updated at `.agents/plugins/marketplace.json` or `~/.agents/plugins/marketplace.json`.
4. In Codex CLI, run `/plugins` and install the local `hardware-agent-skills` plugin to enable the generated slash commands.

## Codex Command Model

Codex uses two separate surfaces in this repo:

- **Skills**: copied directly to `.codex/skills/` and auto-discovered by Codex.
- **Slash commands**: generated as Markdown files inside the local plugin `commands/` directory.

The source of truth for slash commands remains the TOML files under each skill's `commands/` directory. During install:

- Gemini receives TOML commands directly.
- Claude receives generated Markdown commands via `toml_to_claude_cmd.sh`.
- Codex receives generated plugin commands via `toml_to_codex_cmd.sh`.

## Adding a New Skill

1. Create a `kebab-case` directory at the repo root with this structure:

   ```text
   <skill-name>/
   ├── SKILL.md        # Required: YAML frontmatter + persona + procedures
   ├── assets/         # Templates and boilerplate
   ├── references/     # Style guides and documentation
   ├── commands/       # Source TOML slash command definitions
   └── scripts/        # Helper scripts
   ```

2. `SKILL.md` must begin with YAML frontmatter:

   ```yaml
   ---
   name: <skill-name>
   description: |
     Brief summary.
   metadata:
     version: "1.0.0"
     depends_on:
       - <other-skill>
   ---
   ```

3. Keep slash command source files in TOML under `commands/`.

4. If a command references skill assets or references, use paths that the install pipeline can rewrite or convert correctly.

5. Test all three install paths:

   ```bash
   ./install.sh --project --gemini --all
   ./install.sh --project --claude --all
   ./install.sh --project --codex --all
   ```

## Slash Commands

After install, Codex slash commands are provided by the generated local plugin, not by `.codex/commands/`.

Current commands:

| Command | Description |
|---|---|
| `/sv-gen` | Generate SV RTL following clean-code style |
| `/sv-style-check` | Check code for naming/FSM/style violations |
| `/sv-synth-check` | Check for synthesis risks (latches, non-synth constructs) |
| `/sv-sva-check` | Review SVA best practices |
| `/sv-clean-code` | Review for Clean Code principles |
| `/sv-verilator-check` | Check for Verilator compatibility issues |

## Engineering Standards

All skills enforce the style guide at `systemverilog-core/references/style-guide.md`:

- **Naming**: `snake_case` for modules/signals; `_t` for types; `_ct` for classes; `_if` for interfaces; `_pkg` for packages
- **FSMs**: Mandatory two-block structure with `always_ff` for `state_curr` and `always_comb` for `state_next`
- **File discipline**: One module/class per file; file name matches entity name; every file starts with `` `default_nettype none ``
- **Tool targets**: Verilator, Cocotb, and synthesis tools
