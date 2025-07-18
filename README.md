# clair-de-config

_A synchronization ballet for your Claude configuration files_

## What Is This Madness?

In the beginning, there was chaos. Configuration files scattered across machines like socks in a cosmic dryer. Settings duplicated, aliases forgotten, and MCP servers living in blissful isolation. This was widely regarded as a bad move.

`clair-de-config` exists to solve a problem that shouldn't exist but definitely does: keeping your Claude configuration synchronized across the vast expanses of your digital existence.

## The Improbability of It All

Consider, if you will, the sheer statistical unlikelihood that your Claude settings on your personal machine will spontaneously match those on your work machine. The probability is roughly equivalent to a pot of petunias suddenly appearing in mid-air and thinking "Oh no, not again."

This tool ensures that such improbabilities become certainties.

## What It Actually Does (The Boring Bit)

- **Alias Management**: Adds clever shortcuts to your PATH, because typing is effort and effort is the enemy of elegance
- **Configuration Sync**: Keeps your Claude config files (settings, hooks, commands, rules) in harmonious agreement across all your devices
- **Custom Commands**: Includes powerful `atm-*` commands for PR reviews, commit messages, and mathematical proofs
- **Security Hardening**: Implements distributed locking, atomic operations, and rollback capabilities (because chaos is only fun in theory)
- **Dependency Management**: Automatically checks for and installs required tools (homebrew, gh cli, jira-cli)

## Prerequisites

The install script will check for these, but you'll need:
- **macOS or Linux** (Windows users, we feel your pain but haven't addressed it yet)
- **Homebrew** (the install script will tell you how to get it)
- **Git** (but you probably have this already)

## Installation

```bash
git clone https://github.com/aaronmaturen/clair-de-config.git
cd clair-de-config
./install.sh  # This script now exists and is, indeed, magnificent
```

The installer will:
- Check for required dependencies (and offer to install them)
- Create backups of your existing configurations
- Set up symlinks to keep everything synchronized
- Add source lines to your shell configuration
- Make you feel like a configuration wizard

## Usage

### Basic Commands

```bash
clair-sync              # Pull latest configuration changes
clair-sync --push -m "message"  # Push your changes to the repository
clair-add-alias name 'command'  # Add a new alias
clair-add-alias --edit  # Open aliases file in your editor
clair-status            # Check synchronization status and health
```

### Advanced ATM Commands

These specialized commands enhance your Claude CLI experience:

```bash
/atm-commit-msg     # Generate JIRA-linked commit messages from staged changes
/atm-pr-review      # Comprehensive PR analysis with educational context
/atm-implement-pr-feedback  # Systematically implement PR feedback
/atm-proof          # Mathematical analysis and edge case discovery
/atm-clear          # Create session summary and clear context
```

## Project Structure

```
clair-de-config/
├── aliases             # Your shell aliases (only 'dangerzone' by default)
├── claude/             # Claude CLI configurations
│   ├── CLAUDE.md       # Main Claude instructions (references rule modules)
│   ├── commands/       # Custom /atm-* commands
│   ├── hooks/          # Post-tool-use hooks for formatting and testing
│   ├── rules/          # Modular rule files
│   │   ├── 01-general-instructions.md
│   │   ├── 02-git-workflow.md
│   │   ├── 03-available-tools.md
│   │   └── 04-project-specific.md
│   └── settings.json   # Claude CLI settings
├── utilities           # Security and utility functions library
├── clair-sync          # Synchronization command
├── clair-add-alias     # Alias management command
├── clair-status        # Status checking command
└── install.sh          # Installation script with dependency checks
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
