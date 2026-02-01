# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Repository Overview

A collection of skills for agent workflows. Each skill packages instructions and optional scripts.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name
    SKILL.md              # Required: skill definition
    scripts/              # Optional: helper scripts
    references/           # Optional: supporting docs
  {skill-name}.zip        # Optional: packaged distribution
```

### Naming Conventions

- Skill directory: `kebab-case` (e.g., `qwen3-tts-mlx`)
- SKILL.md: uppercase and exact filename
- Scripts: `kebab-case` (e.g., `batch-dubbing.py`)
- Zip file: `{skill-name}.zip`

### SKILL.md Format

```markdown
---
name: {skill-name}
description: {One sentence describing when to use this skill. Include trigger phrases.}
metadata:
  author: {author}
  version: "1.0.0"
---

# {Skill Title}

{Brief description}

## When to Use

## Quick Start

## How It Works

## Usage

## Output

## Troubleshooting
```

### Packaging

After creating or updating a skill:

```bash
cd skills
zip -r {skill-name}.zip {skill-name}/
```

### Installation

Document these two installation methods:

**Agent CLI:**
```bash
npx skills add AGISeek/agent-skills
```

**Manual:**
```bash
cp -r skills/{skill-name} ~/.codex/skills/
```
