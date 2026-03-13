# Creating New Agent Skills

This guide explains how to create and integrate a new agent skill into this repository. Following these standards ensures that your skill is compatible with the `install.sh` script and the Gemini CLI's slash command architecture.

## 1. Directory Structure

Each skill must reside in its own top-level directory. The name of the directory should match the skill name (use `kebab-case`).

```text
<skill-name>/
├── SKILL.md             # Mandatory: The main persona and procedures
├── assets/              # Optional: Templates, snippets, or boilerplate
├── references/          # Optional: Style guides, logic rules, or documentation
├── commands/            # Optional: TOML files for slash commands
└── scripts/             # Optional: Helper scripts or automation
```

## 2. Defining the Skill (`SKILL.md`)

The `SKILL.md` file is the heart of the skill. It must start with a YAML metadata block.

### **Metadata Template**
```yaml
---
name: <skill-name>
description: |
  A brief (1-3 sentence) summary of what the skill does.
metadata:
  version: "1.0.0"
  depends_on:
    - <other-skill-name>  # List any prerequisite skills
---
```

### **Content Sections**
- **Persona:** Define who the agent is when this skill is active (e.g., "You are an expert Verilog Linting Engineer").
- **Procedures:** Step-by-step workflows the agent should follow (e.g., "/lint procedure").
- **Available Resources:** List the files in `assets/` and `references/` so the agent knows what it can read.

## 3. Adding Slash Commands

Slash commands allow users to trigger specific skill workflows easily. Create a `.toml` file in the `commands/` directory for each command.

### **Command Template (`commands/my-command.toml`)**
```toml
description = "Brief description of what the command does"
prompt = """
Instructions for the model.
Use relative paths to reference skill assets:
- Style Guide: @{../skills/<skill-name>/references/style-guide.md}
- Template: @{../skills/<skill-name>/assets/my_template.sv}

User input: {{args}}
"""
```
*Note: The `../skills/` prefix is mandatory for the `install.sh` script to correctly resolve paths after installation.*

## 4. Integration & Testing

1.  **Update GEMINI.md**: Add your new skill to the "Project Overview" and list its slash commands in the "Slash Commands" section.
2.  **Test Installation**: Run `./install.sh --project` to verify the skill and commands are correctly copied to `.gemini/`.
3.  **Reload Commands**: In the Gemini CLI, run `/commands reload` to verify your new slash command appears in the `/help` menu.

## 5. Style Guidelines

- **Clarity over Cleverness**: Prompts should be explicit and easy for the model to follow.
- **Portability**: Never use absolute paths. Always use the relative path structure described above.
- **Documentation**: If your skill has complex logic, document the *why* in the `references/` folder.
