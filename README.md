# Hardware Engineering Agent Skills

A collection of specialized [Gemini CLI](https://github.com/google/gemini-cli), [Claude Code](https://claude.ai), and Codex CLI agent skills designed for high-quality **SystemVerilog (SV)** development, RTL design, and **Verilator**-based verification.

## 🚀 Overview

These skills provide structured personas, expert workflows, and high-quality templates to ensure hardware designs are readable, maintainable, and compatible with modern engineering tools like Verilator and Cocotb.

For synthesizable SystemVerilog RTL, the shared style guide requires `logic` for normal ports and internal signals; `wire` is reserved only for true tri-state or `inout` net semantics.

### Supported Agents
- **Gemini CLI**: Full support for skills and custom slash commands.
- **Claude Code**: Support for skills and custom instructions.
- **Codex CLI**: Support for skills plus a local plugin wrapper for slash commands.

### Included Skills
- **`systemverilog-core`**: RTL design following "Clean Code" principles and a strict style guide.
- **`systemverilog-tests`**: Generation of basic and self-checking SV testbenches.
- **`cocotb-verilator-tests`**: Generation of Cocotb Python testbenches and Pytest runners for Verilator.
- **`verilator`**: Expertise in Verilator-specific conversion, optimization, and C++ pitfalls.
- **`verilator-cmake`**: Automation of CMake build systems for Verilator projects.
- **`verilator-simflow`**: End-to-end simulation management, regressions, and waveform tracing.
- **`release-management`**: Generic repository release planning, branch/tag confirmation, and optional GitHub release publishing.

## 📦 Installation

You can install these skills and their associated configurations to your global agent directory or directly to a specific project.

### Install For All Supported Agents

Use `--agent all` to install for Gemini CLI, Claude Code, and Codex CLI in one pass.

```bash
# Global installation (~/.gemini/, ~/.claude/, ~/.codex/, plus Codex plugin)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --agent all --all

# Project-specific installation (.gemini/, .claude/, .codex/, plus local Codex plugin)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --project --agent all --all
```

### Gemini CLI
Gemini is still the default single-agent installation target.

```bash
# Global installation (~/.gemini/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --all

# Project-specific installation (.gemini/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --project
```

### Claude Code
Use the `--claude` flag to install skills to Claude's configuration directory.

```bash
# Global installation (~/.claude/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --claude --all

# Project-specific installation (.claude/)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --claude --project
```

### Codex CLI
Use the `--codex` flag to install skills to Codex and generate a local plugin for slash commands.

```bash
# Global installation (~/.codex/skills + ~/plugins/hardware-agent-skills)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --codex --all

# Project-specific installation (.codex/skills + ./plugins/hardware-agent-skills)
curl -fsSL https://raw.githubusercontent.com/ezchi/agent-skills/main/install.sh | bash -s -- --codex --project
```

### Local Installation
If you have already cloned the repository:

```bash
./install.sh --agent all --all  # Gemini + Claude + Codex
./install.sh --all              # Gemini only (default)
./install.sh --claude --all     # Claude only
./install.sh --codex --all      # Codex only
```

*Notes: After installing for Gemini, run `/commands reload` in Gemini CLI to activate the new slash commands. After installing for Codex, run `/plugins` in Codex CLI and install the local `hardware-agent-skills` plugin. When using `--agent all`, both of those post-install steps still apply.*

## ⌨️ Slash Commands

Once installed, use these commands to streamline your hardware development workflow:

| Command | Skill | Description |
| :--- | :--- | :--- |
| `/sv-gen` | `core` | Generate SV RTL following clean-code style. |
| `/sv-style-check` | `core` | Analyze code for style guide violations. |
| `/sv-synth-check` | `core` | Assess synthesis risks (latches, non-synth logic). |
| `/sv-sva-check` | `core` | Review SystemVerilog Assertions (SVA) for best practices. |
| `/sv-verilator-check` | `verilator` | Check for Verilator-specific compatibility issues. |
| `/sv-clean-code` | `core` | Review code for Single Responsibility and clarity. |
| `/repo-release` | `release-management` | Inspect and execute a repository release with interactive branch/tag confirmation. |

Gemini uses native TOML commands, Claude receives generated Markdown commands, and Codex receives generated plugin commands.

## 🛠️ Contributing

We welcome new skills! Please refer to the **[CONTRIBUTING_SKILLS.md](./CONTRIBUTING_SKILLS.md)** guide for instructions on:
- Using the built-in `skill-creator` to bootstrap new skills.
- Packaging skills with **`./scripts/pack_skills.sh`**.
- Defining custom slash commands.
- Ensuring path portability for the installation script.

## 📄 License

This project is licensed under the GNU Affero General Public License Version 3. See the [LICENSE](./LICENSE) file for details.
