# Changelog

All notable changes to Keystone will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v1.0.0.html).

## [1.0.0] - 2026-04-17

### Added
- Complete OSS skill set: req, est, hld, adr
- Cross-platform setup scripts (Windows PowerShell, macOS/Linux Bash)
- Host adapters for Claude Code, Kilo Code, Gemini CLI
- keystone-compress utility for CLAUDE.md token optimization
- keystone-analytics for session usage tracking
- Pipeline testing on 3 real systems (payments, chat, feed)
- Flagship demo for real-time payments platform
- Caveman protocol implementation across all skills

### Changed
- Updated installation instructions for multi-platform support

### Technical Details
- Token compression: 40-50% input reduction
- Pipeline execution: ~45 seconds for full architecture
- Cross-platform compatibility: Windows, macOS, Linux
- Host support: Claude Code, Kilo Code, Gemini CLI