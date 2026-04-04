# Gemini CLI Agent Skills: SystemVerilog & Verilator

This repository contains a suite of specialized **Agent Skills** for Gemini CLI, Claude Code, and Codex CLI. These skills provide the personas, procedures, templates, and style guides necessary for high-quality SystemVerilog development, RTL design, and Verilator-based verification workflows.

## Project Overview

The project is structured as a collection of modular skills, each focusing on a specific aspect of the hardware development lifecycle:

*   **`systemverilog-core`**: The foundational skill for RTL design. It enforces "Clean Code" principles for SystemVerilog, providing templates for modules, FSMs, and interfaces.
*   **`systemverilog-tests`**: Specialized in generating testbenches, including basic harnesses and self-checking environments compatible with Verilator.
*   **`cocotb-verilator-tests`**: Generates Cocotb-based Python testbenches and regression scripts for Verilator simulations.
*   **`verilator`**: Provides deep expertise in Verilator-specific SystemVerilog constraints, optimization, and debugging of C++ conversion issues.
*   **`verilator-cmake`**: Automates the creation and maintenance of CMake build systems for Verilator projects, ensuring portable and reproducible builds.
*   **`verilator-simflow`**: Manages end-to-end simulation tasks, from running single tests to executing full regressions and generating waveforms.

## Engineering Standards

All skills and generated code must adhere to the **SystemVerilog Style Guide** (`skills/systemverilog-core/references/style-guide.md`). Key mandates include:

*   **Clarity over Cleverness**: Prioritize explicit logic and readable naming over compact or obscure constructs.
*   **Naming Conventions**:
    *   **Modules/Signals**: `snake_case` (e.g., `fifo_async`, `clk_core`).
    *   **Types**: Suffix with `_t` (e.g., `state_t`, `packet_t`).
    *   **Classes**: Suffix with `_ct`, defined in `*.svh` files.
    *   **Interfaces**: Suffix with `_if`.
    *   **Packages**: Suffix with `_pkg`.
*   **FSM Style**: Mandatory **two-block structure**:
    *   `always_ff` for sequential state register (`state_curr`).
    *   `always_comb` for next-state logic (`state_next`).
*   **File Architecture**:
    *   One module/class per file.
    *   File names must match the entity name.
    *   No implicit nets: Always start files with `` `default_nettype none ``.
*   **Tool Compatibility**: Optimized for **Verilator**, **Cocotb**, and standard synthesis tools.

## Installation

You can install the skills and their associated configurations to your global agent environment or to a specific project.

### Gemini CLI (Default)

```bash
# Install all skills globally (~/.gemini/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --all

# Install to current project (.gemini/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --project
```

### Claude Code

```bash
# Install all skills globally (~/.claude/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --claude --all

# Install to current project (.claude/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --claude --project
```

### Codex CLI

```bash
# Install all skills globally (~/.codex/) and generate a local Codex plugin
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --codex --all

# Install to current project (.codex/) and generate a repo-local Codex plugin
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --codex --project
```

### Local Installation

The script will:
1.  Discover all skills in the repository.
2.  Optionally prompt you for each skill.
3.  Copy the skill files (`SKILL.md`, `assets/`, `references/`) to the target `skills/` directory.
4.  For Gemini, register custom slash commands by copying TOML files to the target `commands/` directory.
5.  For Claude, generate Markdown slash commands in the target `commands/` directory.
6.  For Codex, generate a local plugin with Markdown commands and add it to the local marketplace manifest.

## Slash Commands (Gemini CLI Only)

Once installed, the following slash commands are available to streamline your SystemVerilog development:

### SystemVerilog Core
- `/sv-gen <description>`: Generate SV RTL following clean-code style.
- `/sv-style-check <file>`: Analyze code for style guide violations (naming, FSMs, etc.).
- `/sv-synth-check <file>`: Assessment of synthesis risks (latches, non-synth constructs).
- `/sv-sva-check <file>`: Review SVA files for best practices.
- `/sv-clean-code <file>`: Review code for Clean Code principles (Single Responsibility, etc.).

### Verilator
- `/sv-verilator-check <file>`: Check for Verilator-specific compatibility issues.

*Note: After installation or modification, run `/commands reload` in the Gemini CLI to activate the new slash commands.*

## Development Workflows

### 1. RTL Generation (`systemverilog-core`)
- **Plan**: Define ports, parameters, and core logic.
- **Template**: Use `module_basic.sv`, `fsm_template.sv`, or `interface_template.sv`.
- **Verify**: Check against mandatory style checks (no latches, no implicit nets).

### 2. Build System Management (`verilator-cmake`)
- **Generate**: Create `CMakeLists.txt` for Verilator compiling SV to C++.
- **Standards**: Minimum CMake 3.14, C++20 standard, and explicit output directory management.

### 3. Simulation & Regression (`verilator-simflow`)
- **Run**: Execute simulation binaries, capturing logs and analyzing for `TEST PASS/FAIL`.
- **Regression**: Automate batch runs, summarizing results and generating waveforms on failure.

## Contributing

If you'd like to contribute a new skill to this repository, please see the **[CONTRIBUTING_SKILLS.md](./CONTRIBUTING_SKILLS.md)** guide for detailed instructions on the required file structure and metadata.

## Usage in Gemini CLI

These skills are designed to be activated via the `activate_skill` tool when relevant hardware engineering tasks are identified.
- **Directives**: "Create a FIFO," "Generate a CMakeLists for Verilator," "Run a regression."
- **Inquiries**: "Review this FSM for style violations," "Why is Verilator failing to compile this streaming operator?"

Each skill folder contains a `SKILL.md` defining its persona and specific procedures, along with `assets/` for templates and `references/` for detailed documentation.
