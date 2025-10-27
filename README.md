# atm

_A Claude Code plugin and synchronization system for professional development workflows_

[![Claude Plugin](https://img.shields.io/badge/Claude-Plugin-blue)](PLUGIN.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What Is This?

Now available as a **Claude Code Plugin**! Get instant access to professional development workflows, JIRA integration, PR review tools, and powerful MCP servers.

`atm` is both:
1. **A Claude Code Plugin** - Install via `/plugin install atm@github` for instant workflow commands
2. **A Configuration Sync System** - Traditional shell integration for keeping settings synchronized across machines

In the beginning, there was chaos. Configuration files scattered across machines like socks in a cosmic dryer. Settings duplicated, aliases forgotten, and MCP servers living in blissful isolation. This was widely regarded as a bad move.

## What It Actually Does

### As a Plugin
- **14 Workflow Commands**: `/commit-msg`, `/pr-review`, `/scaffold`, and more
- **MCP Servers**: Pre-configured Context7 (documentation) and Serena (code analysis)
- **JIRA Integration**: Ticket research and commit message generation
- **PR Review Tools**: Comprehensive analysis with educational context
- **Project Scaffolding**: Interactive setup for React, Next.js, Python, Go, Rust, and more

### As a Sync System (Legacy)
- **Alias Management**: Clever shortcuts to your PATH
- **Configuration Sync**: Keep Claude config files synchronized across devices
- **Security Hardening**: Distributed locking, atomic operations, rollback capabilities
- **Dependency Management**: Automatic tool installation (homebrew, gh cli, jira-cli)

## Prerequisites

### For Plugin Installation
- **Claude Code** - The Claude CLI tool
- **Optional**: `gh` (GitHub CLI) for PR commands
- **Optional**: `jira` (JIRA CLI) for JIRA integration
- **Optional**: `uvx` for Serena MCP server

### For Traditional Installation
- **macOS or Linux** (Windows users, we feel your pain but haven't addressed it yet)
- **Homebrew** (the install script will tell you how to get it)
- **Git** (but you probably have this already)

## Installation

### As a Claude Code Plugin (Recommended)

The easiest way to use atm is as a Claude Code plugin:

```bash
# Add the marketplace
/plugin marketplace add aaronmaturen/claude-plugin

# Install the plugin
/plugin install atm@aaronmaturen-plugins

# Set up global rules (optional)
/setup-rules
```

**Alternative: Install from local clone**

```bash
# Clone the repository
git clone https://github.com/aaronmaturen/claude-plugin.git

# Install from local path
/plugin install /path/to/claude-plugin
```

This gives you instant access to all 15 workflow commands and pre-configured MCP servers.

See [PLUGIN.md](PLUGIN.md) for complete plugin documentation.

### Traditional Installation (Legacy)

For shell integration and synchronization features:

```bash
git clone https://github.com/aaronmaturen/claude-plugin.git
cd claude-plugin
./install.sh  # This script now exists and is, indeed, magnificent
```

The installer will:
- Check for required dependencies (and offer to install them)
- Create backups of your existing configurations
- Set up symlinks to keep everything synchronized
- Add source lines to your shell configuration
- Make you feel like a configuration wizard

## Usage

### Plugin Commands

All 14 workflow commands are available immediately after installation:

```bash
# Development Workflow
/commit-msg              # Generate JIRA-linked commit messages
/pr-review               # Comprehensive PR analysis
/implement-pr-feedback   # Systematically implement PR feedback
/self-review             # Self-code review before PR
/jira                    # JIRA ticket research and planning

# Code Analysis
/arch-review             # Architecture review
/simplify                # Code simplification
/proof                   # Mathematical analysis
/bug-investigation       # Systematic bug debugging
/feature-investigation   # Feature requirement analysis
/spike-investigation     # Technical spike research

# Project Setup
/scaffold                # Interactive project scaffolding

# Session Management
/clear                   # Session summary and context clearing
/reflect                 # Conversation pattern analysis

# Configuration
/setup-rules             # Install global rules
```

See [PLUGIN.md](PLUGIN.md) for detailed command documentation and examples.

### Shell Commands (Legacy Installation)

```bash
clair-sync              # Pull latest configuration changes
clair-sync --push -m "message"  # Push your changes to the repository
clair-add-alias name 'command'  # Add a new alias
clair-add-alias --edit  # Open aliases file in your editor
clair-status            # Check synchronization status and health
```

## Project Structure

```
claude-plugin/
├── .claude-plugin/
│   └── plugin.json     # Plugin manifest
├── commands/           # Slash commands for plugin
│   ├── *.md            # 14 workflow commands
│   └── setup-rules.md  # Rules installation command
├── claude/             # Legacy configuration directory
│   ├── CLAUDE.md       # Main Claude instructions (references rule modules)
│   ├── commands/       # Original commands (synced to /commands)
│   ├── rules/          # Modular rule files
│   │   ├── 01-general-instructions.md
│   │   ├── 02-git-workflow.md
│   │   ├── 03-available-tools.md
│   │   ├── 04-project-specific.md
│   │   └── 05-debugging-methodology.md
│   ├── hooks/          # Post-tool-use hooks
│   ├── mcp-servers.json # MCP server configuration
│   └── settings.json   # Claude CLI settings
├── bin/                # Utility scripts
│   └── clair-mcp       # MCP server wrapper
├── utilities           # Security and utility functions library
├── clair-sync          # Synchronization command
├── clair-add-alias     # Alias management command
├── clair-status        # Status checking command
├── install.sh          # Installation script with dependency checks
├── PLUGIN.md           # Complete plugin documentation
└── README.md           # This file
```

## Security Features

Because even configuration management deserves Fort Knox treatment:

- **Distributed Locking**: Prevents concurrent operations from creating chaos
- **Atomic File Operations**: Either it works completely or not at all
- **Input Validation**: Sanitizes paths and validates alias names
- **Rollback Capability**: Transaction logging for when things go sideways
- **Backup Creation**: Unique timestamped backups before any changes

## Customization

### Adding New Rules
Create a new markdown file in `claude/rules/` and reference it in `claude/CLAUDE.md`.

### Creating Custom Commands
Add a new `.md` file to `claude/commands/` following the existing patterns.

### Modifying Hooks
Edit the shell scripts in `claude/hooks/` to customize post-tool behavior.

## The Philosophy

Why spend time manually copying configuration files when you could spend that time contemplating the nature of configuration itself? This tool frees you from the mundane task of synchronization, allowing you to focus on more important questions, like "Why do we configure things at all?" and "Is my configuration truly mine, or merely a reflection of the universal configuration that binds us all?"

## Contributing

If you've found a bug, congratulations! You've discovered that perfection is a myth. Please file an issue so we can perpetuate the illusion of progress.

If you'd like to contribute code, remember: the best code is no code, but the second best code is someone else's code that works.

## License

This software is provided "as is", which is to say it exists in a quantum superposition of working and not working until you actually run it.

---

_Remember: The answer to the ultimate question of configuration, synchronization, and everything is probably not 42, but we haven't ruled it out entirely._
