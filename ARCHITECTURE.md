# Keystone Architecture

This document describes the architecture of the Keystone system itself.

## Overview

Keystone is composed of skills that each embody a specific architect/CTO persona.
Each skill follows a strict template and produces structured output.

## Components

- **Skills**: Individual capabilities like `/keystone-req`, `/keystone-hld`, etc.
- **Tools**: Utilities like `keystone-compress` for CLAUDE.md optimization
- **Adapters**: Host-specific integrations for Claude Code, Kilo Code, Gemini CLI
- **Decisions**: Auto-generated ADRs stored as markdown files

## Data Flow

1. User invokes a skill via slash command
2. Skill processes input according to its persona and process
3. Skill generates structured output following its schema
4. For skills like `/keystone-adr`, artifacts are written to the decisions directory
5. `/keystone-run` orchestrates the full pipeline

## Dependencies

- None beyond the host CLI capabilities
- Designed to work with any CLI that supports slash commands and file writing