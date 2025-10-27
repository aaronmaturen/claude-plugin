# atm Claude Plugin

Professional development workflow plugin for Claude Code with JIRA integration, PR review tools, MCP servers, and comprehensive workflow commands.

## What's Included

### Commands

This plugin provides 14 specialized workflow commands plus a setup command:

#### Development Workflow
- `/commit-msg` - Generate JIRA-linked commit messages from staged changes
- `/pr-review` - Comprehensive PR analysis with educational context for junior engineers
- `/implement-pr-feedback` - Systematically implement PR feedback with categorization
- `/self-review` - Self-code review before creating PR
- `/jira` - JIRA ticket research and implementation planning

#### Code Analysis
- `/arch-review` - Architecture review and analysis
- `/simplify` - Code simplification recommendations
- `/proof` - Mathematical analysis and edge case discovery
- `/bug-investigation` - Systematic bug analysis and debugging
- `/feature-investigation` - Feature requirement analysis
- `/spike-investigation` - Technical spike research

#### Project Setup
- `/scaffold` - Interactive project scaffolding with framework selection

#### Session Management
- `/clear` - Create session summary and clear context
- `/reflect` - Analyze conversation patterns and suggest improvements

#### Configuration
- `/setup-rules` - Install atm rules to global Claude configuration

### MCP Servers

Two powerful MCP servers are pre-configured:

1. **Context7** - Documentation and web search capabilities
   - Enhances commands with up-to-date documentation
   - Used by scaffolding and review commands

2. **Serena** - Intelligent code analysis and language server integration
   - Provides deep codebase understanding
   - Symbol discovery and navigation
   - Project memory and context persistence

## Installation

### Method 1: From GitHub Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add aaronmaturen/claude-plugin

# Install the plugin
/plugin install atm@aaronmaturen-plugins

# Plugin is now ready to use!
```

### Method 2: Local Installation

1. Clone this repository:
```bash
git clone https://github.com/aaronmaturen/claude-plugin.git
```

2. Install as a local plugin:
```bash
/plugin install /path/to/claude-plugin
```

This method is useful for:
- Development and testing
- Customizing the plugin before use
- Working offline

### Setting Up Rules (Optional)

After installation, run the setup command to install global rules:

```bash
/setup-rules
```

This will install modular rule files that provide:
- General operational guidelines
- Git workflow best practices
- Available CLI tools configuration
- Project-specific conventions
- Debugging methodology

## Configuration

### MCP Server Requirements

#### Context7
No additional setup required - runs via `npx`.

#### Serena
Requires `uvx` (Python tool runner). Install via:

```bash
# On macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Or use the original installation path from your system if `uvx` is already installed.

### External Tool Dependencies

Some commands require external CLI tools:

- **GitHub CLI (`gh`)** - Required for `/pr-review`, `/implement-pr-feedback`
  ```bash
  brew install gh
  gh auth login
  ```

- **JIRA CLI (`jira`)** - Required for `/commit-msg`, `/jira`
  ```bash
  brew install ankitpokhrel/jira-cli/jira-cli
  jira init
  ```

Commands will gracefully handle missing dependencies and inform you what's needed.

## Usage Examples

### Generate a Commit Message

```bash
# Stage your changes
git add .

# Generate JIRA-linked commit message
/commit-msg
```

The command will:
- Extract JIRA ticket number from your branch name
- Analyze staged changes
- Generate a commit message with ticket link
- Check for new TODO comments
- Copy the message to your clipboard

### Review a Pull Request

```bash
/pr-review 123
```

Provides comprehensive analysis:
- Pattern consistency checking
- Documentation suggestions (using Context7)
- Testing strategy recommendations
- Educational explanations for junior engineers

### Scaffold a New Project

```bash
/scaffold
```

Interactive scaffolding with:
- Framework selection (React, Next.js, Vue, Node.js, Python, Go, Rust, Svelte)
- Documentation research via Context7
- Comprehensive TODO.md with implementation phases
- Parallel task annotations for multi-agent workflows

### Investigate a JIRA Ticket

```bash
/jira PRO-1234
```

Fetches ticket details and creates implementation roadmap using Serena for codebase analysis.

## Command Details

### Commit Message Generation (`/commit-msg`)

**Features:**
- Extracts ticket numbers from branch names (PRO-####, BUG-###, etc.)
- Analyzes git diff to understand changes
- Detects new TODO comments before committing
- Copies formatted message to clipboard
- Follows conventional commit format

**Example Output:**
```
feat: Add user authentication middleware [PRO-1234]

Implemented JWT-based authentication middleware with role-based access control.
Added unit tests for auth flows and error cases.

https://your-jira.atlassian.net/browse/PRO-1234
```

### PR Review (`/pr-review`)

**Features:**
- Comprehensive code analysis
- Pattern consistency checking
- Documentation linking with Context7
- Testing strategy recommendations
- Educational tone for junior engineers
- Security considerations
- Performance implications

**Usage:**
```bash
# Review a PR by number
/pr-review 123

# Review current branch
/pr-review
```

### Project Scaffolding (`/scaffold`)

**Supported Frameworks:**
- React (with Vite, TypeScript, Testing Library)
- Next.js (App Router, TypeScript, Tailwind)
- Node.js (Express, TypeScript, Jest)
- Python (FastAPI, Poetry, Pytest)
- Go (Gin, standard library, testing)
- Rust (Axum, Cargo, testing)
- Vue (Vite, TypeScript, Vitest)
- Svelte (SvelteKit, TypeScript, Vitest)

**Features:**
- Interactive framework selection
- Context7-enhanced documentation research
- Parallel task annotations
- Comprehensive TODO.md with phases:
  1. Foundation Setup
  2. Core Features
  3. Testing & Quality
  4. Documentation
  5. Deployment

### Investigation Commands

All investigation commands follow a systematic approach:

1. **Information Gathering**
   - JIRA ticket details (if applicable)
   - Codebase analysis with Serena
   - Recent changes and context

2. **Analysis**
   - Root cause identification
   - Impact assessment
   - Related code discovery

3. **Action Plan**
   - Step-by-step implementation
   - Test strategy
   - Rollback considerations

## Customization

### Adding Custom Commands

Create a new `.md` file in the `commands/` directory:

```markdown
---
description: Brief description of your command
---

# Your Command Name

Instructions for Claude on how to execute this command...
```

### Modifying Rules

After running `/setup-rules`, edit files in `~/.claude/rules/`:

- `01-general-instructions.md` - File management, command creation
- `02-git-workflow.md` - Git commit/push rules
- `03-available-tools.md` - CLI tool usage
- `04-project-specific.md` - Project conventions
- `05-debugging-methodology.md` - Debugging approach

### Customizing MCP Servers

Edit `.claude-plugin/plugin.json` to add or modify MCP servers:

```json
{
  "mcpServers": {
    "your-server": {
      "command": "npx",
      "args": ["-y", "your-mcp-package"]
    }
  }
}
```

## Architecture

### Plugin Structure

```
claude-plugin/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/                 # Slash commands
│   ├── *.md                 # Workflow commands
│   └── setup-rules.md       # Configuration command
├── claude/                   # Legacy configuration (for manual setup)
│   ├── CLAUDE.md            # Rules entry point
│   ├── rules/               # Modular rule files
│   ├── commands/            # Original commands (synced to /commands)
│   └── mcp-servers.json     # MCP configuration
└── bin/                      # Utility scripts
    └── clair-mcp            # MCP server wrapper
```

### Command Design Philosophy

Commands are designed to:
- **Be specific** - Each command has a clear, focused purpose
- **Use external tools** - Leverage gh, jira, git for functionality
- **Provide context** - Educational explanations for junior developers
- **Enable parallel work** - Task annotations for multi-agent execution
- **Fail gracefully** - Check dependencies and provide helpful errors

### MCP Integration

- **Context7** - Provides real-time documentation lookup
  - Used in: `/pr-review`, `/scaffold`, `/arch-review`
  - Enhances recommendations with current best practices

- **Serena** - Deep codebase understanding
  - Used in: `/jira`, investigation commands
  - Symbol navigation and pattern discovery
  - Project memory for context persistence

## Troubleshooting

### Commands Not Available

Ensure the plugin is installed and enabled:
```bash
/plugin list
/plugin enable atm
```

### MCP Servers Not Working

Check MCP server status:
```bash
# In Claude Code, check logs for MCP initialization
# Context7 should load automatically via npx
# Serena requires uvx - verify installation:
which uvx
```

### JIRA/GitHub Integration Issues

Verify CLI tools are authenticated:
```bash
# GitHub
gh auth status

# JIRA
jira issue list
```

### Rules Not Loading

Rules must be installed to `~/.claude/` to be global:
```bash
/setup-rules
```

Or manually verify:
```bash
ls ~/.claude/rules/
cat ~/.claude/CLAUDE.md
```

## Contributing

Contributions are welcome! Please:

1. Follow existing command patterns
2. Include descriptive frontmatter
3. Provide clear instructions
4. Test with actual workflows
5. Document any external dependencies

## License

MIT License - See LICENSE file for details

## Support

- Issues: https://github.com/aaronmaturen/claude-plugin/issues
- Discussions: https://github.com/aaronmaturen/claude-plugin/discussions

## Changelog

### 1.0.0 (Plugin Release)
- Converted to Claude Code plugin format
- Added 14 workflow commands
- Integrated Context7 and Serena MCP servers
- Added `/setup-rules` configuration command
- Comprehensive documentation
