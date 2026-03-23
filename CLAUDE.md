# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal Claude Code skills repository. Each top-level directory contains a single `SKILL.md` defining a reusable skill.

## Skill Structure

Each skill is a directory with one `SKILL.md` file:

```
<skill-name>/
└── SKILL.md
```

### SKILL.md Format

Required YAML frontmatter:
- `name` — skill identifier (matches directory name)
- `description` — when/how to trigger the skill; include trigger phrases, slash commands, and use cases

Body: Markdown instructions Claude follows when the skill is invoked. Include workflow steps, code blocks, constraints, and examples.

## Commits

Use Conventional Commits via gitflow-toolkit (`git ci -F`). Scope is required — use the skill name as scope (e.g., `feat(commit): ...`, `docs(mise): ...`). Use `general` when changes span multiple skills.
