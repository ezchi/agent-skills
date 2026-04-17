# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

This repository is a collection of modular **Agent Skills** for Gemini CLI, Codex, and Codex CLI, targeting hardware engineers working with SystemVerilog, RTL design, and Verilator-based verification.

Each skill lives in its own directory under `skills/` and consists of a `SKILL.md` (persona + procedures), `assets/` (templates), `references/` (style guides/docs), `commands/` (source TOML slash commands that are converted per target), and optionally `scripts/`. Helper scripts live in the top-level `scripts/` directory.

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
# Install all skills to Codex global (~/.Codex/)
./install.sh --Codex --all

# Install to current project (.Codex/)
./install.sh --Codex --project

# Install for Gemini CLI globally
./install.sh --all

# Install for Gemini CLI to project
./install.sh --project

# Install for Codex CLI globally
./install.sh --codex --all

# Install for Codex CLI to project
./install.sh --codex --project

# Package skills into .skill bundles (output: ./dist/)
./scripts/pack_skills.sh
```

After Gemini installation, run `/commands reload` in the Gemini CLI to activate slash commands.

## Adding a New Skill

1. Create a `kebab-case` directory under `skills/` with this structure:
   ```
   skills/<skill-name>/
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

3. For Gemini slash commands, use relative paths with the `../skills/` prefix so `install.sh` can rewrite them correctly:
   ```toml
   prompt = """
   Style Guide: @{../skills/<skill-name>/references/style-guide.md}
   User input: {{args}}
   """
   ```

4. For slash commands, only `.toml` files are needed. `install.sh` calls `scripts/toml_to_claude_cmd.sh` to generate `.md` files for Codex and `scripts/toml_to_codex_cmd.sh` to generate Codex plugin commands at install time. You can also run the Codex converter directly:
   ```bash
   ./scripts/toml_to_claude_cmd.sh <input.toml> <output.md> <skills_dir>
   ```
   It extracts the `prompt` block, replaces `{{args}}` → `$ARGUMENTS`, strips `!{cat PATH}` inlining wrappers (leaving the bare path for Codex to read at runtime), and substitutes `__SKILLS_DIR__`.

5. Update `GEMINI.md` with the new skill and any slash commands.

6. Test installation: `./install.sh --project --Codex` and `./install.sh --project --gemini`.

## Slash Commands

After installation, Codex slash commands are available in `.Codex/commands/` (project) or `~/.Codex/commands/` (global).

| Command | Description |
|---|---|
| `/sv-gen` | Generate SV RTL following clean-code style |
| `/sv-style-check` | Check code for naming/FSM/style violations |
| `/sv-synth-check` | Check for synthesis risks (latches, non-synth constructs) |
| `/sv-sva-check` | Review SVA best practices |
| `/sv-clean-code` | Review for Clean Code principles |
| `/sv-verilator-check` | Check for Verilator compatibility issues |

Commands are defined as `.md` files in each skill's `commands/` directory. The `__SKILLS_DIR__` placeholder is replaced with the absolute skills path at install time.

## Engineering Standards (Applied to All Generated Code)

All skills enforce the style guide at `skills/systemverilog-core/references/style-guide.md`:

- **Naming**: `snake_case` for modules/signals; `_t` for types; `_ct` for classes; `_if` for interfaces; `_pkg` for packages
- **FSMs**: Mandatory two-block structure — `always_ff` for state register (`state_curr`), `always_comb` for next-state logic (`state_next`)
- **File discipline**: One module/class per file; file name matches entity name; every file starts with `` `default_nettype none ``
- **Tool targets**: Verilator, Cocotb, synthesis tools
