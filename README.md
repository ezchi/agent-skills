# Gemini CLI Agent Skills: Hardware Engineering

A collection of specialized [Gemini CLI](https://github.com/google/gemini-cli) and [Claude Code](https://claude.ai) Agent Skills designed for high-quality **SystemVerilog (SV)** development, RTL design, and **Verilator**-based verification.

## 🚀 Overview

These skills provide structured personas, expert workflows, and high-quality templates to ensure hardware designs are readable, maintainable, and compatible with modern engineering tools like Verilator and Cocotb.

### Supported Agents
- **Gemini CLI**: Full support for skills and custom slash commands.
- **Claude Code**: Support for skills and custom instructions.

### Included Skills
- **`systemverilog-core`**: RTL design following "Clean Code" principles and a strict style guide.
- **`systemverilog-tests`**: Generation of basic and self-checking SV testbenches.
- **`cocotb-verilator-tests`**: Generation of Cocotb Python testbenches and Pytest runners for Verilator.
- **`verilator`**: Expertise in Verilator-specific conversion, optimization, and C++ pitfalls.
- **`verilator-cmake`**: Automation of CMake build systems for Verilator projects.
- **`verilator-simflow`**: End-to-end simulation management, regressions, and waveform tracing.

## 📦 Installation

You can install these skills and their associated configurations to your global agent directory or directly to a specific project.

### Gemini CLI
The default installation target is the Gemini CLI.

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

### Local Installation
If you have already cloned the repository:

```bash
./install.sh --all            # Gemini (default)
./install.sh --claude --all   # Claude
```

*Note: After installing for Gemini, run `/commands reload` in the Gemini CLI to activate the new slash commands.*

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

## 🛠️ Contributing

We welcome new skills! Please refer to the **[CONTRIBUTING_SKILLS.md](./CONTRIBUTING_SKILLS.md)** guide for instructions on:
- Using the built-in `skill-creator` to bootstrap new skills.
- Packaging skills with **`./pack_skills.sh`**.
- Defining custom slash commands.
- Ensuring path portability for the installation script.

## 📄 License

This project is licensed under the GNU Affero General Public License Version 3. See the [LICENSE](./LICENSE) file for details.
