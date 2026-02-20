Now I have enough context. Let me create the CLAUDE.md file for this project.

# Clair-de-Config (ATM)

Claude Code plugin and professional development workflow system with comprehensive command library and MCP server integration.

## Tech Stack

### Core
- **Platform**: Claude Code Plugin System
- **Runtime**: Bash shell commands
- **Integration**: GitHub CLI (`gh`), JIRA CLI (`jira`)

### MCP Servers
- **Context7**: Up-to-date documentation and web search via npx
- **Serena**: Intelligent code analysis (requires `uvx`)

### Development
- **VCS**: Git
- **Documentation**: Markdown
- **Package Manager**: None (shell-based plugin)

## Technologies

- bash
- git
- markdown
- claude-code
- mcp

## Project Structure

```
clair-de-config/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest with MCP server config
│   └── marketplace.json     # Marketplace metadata
├── commands/                # Slash command definitions (25 commands)
│   ├── commit-msg.md        # JIRA-linked commit message generation
│   ├── pr-review.md         # Comprehensive PR analysis
│   ├── scaffold.md          # Interactive project scaffolding
│   ├── bug-investigation.md # 5 Whys root cause analysis
│   ├── *-expert.md          # Framework-specific expert modes (Angular, Django)
│   ├── *-audit.md           # Specialized audits (security, performance, a11y)
│   └── ...                  # Additional workflow commands
├── README.md                # Project overview and installation
├── PLUGIN.md                # Complete plugin documentation
└── .gitignore               # Git ignore rules
```

## Development Setup

### As a Claude Code Plugin (Recommended)

1. **Install the plugin:**
   ```bash
   /plugin marketplace add aaronmaturen/claude-plugin
   /plugin install atm@aaronmaturen-plugins
   ```

2. **Verify installation:**
   ```bash
   /plugin list
   ```

3. **Optional - Install MCP server dependencies:**
   ```bash
   # Context7 requires no setup (uses npx)
   
   # Serena requires uvx
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

### External Tool Dependencies

Some commands require external CLIs:

```bash
# GitHub CLI (for PR review, implement-pr-feedback)
brew install gh
gh auth login

# JIRA CLI (for commit-msg, jira commands)
brew install ankitpokhrel/jira-cli/jira-cli
jira init
```

## Key Commands

### Development Workflow
- `/commit-msg` - Generate JIRA-linked commit messages from staged changes
- `/pr-review <PR>` - Comprehensive PR analysis with educational context
- `/implement-pr-feedback` - Systematically implement PR feedback
- `/self-review` - Self-code review before creating PR
- `/summarize-branch` - Branch summary for documentation

### Code Analysis
- `/bug-investigation <JIRA-ID>` - 5 Whys root cause analysis with FVC tracking
- `/feature-investigation <JIRA-ID>` - Feature requirement analysis
- `/spike-investigation` - Technical spike research
- `/simplify` - Code simplification recommendations
- `/problem-solver` - General problem-solving assistant

### Framework Experts
- `/angular-expert` - Angular 17+ specialist (signals, OnPush, Material M3)
- `/django-expert` - Django/DRF specialist (query optimization, Celery)
- `/a11y-expert` - Accessibility specialist (WCAG 2.2, ARIA)

### Specialized Audits
- `/ai-agent-audit` - AI agent prompt engineering audit
- `/angular-architecture-audit` - Angular structure, state management, subscriptions
- `/angular-performance-audit` - Bundle size, runtime performance, lazy loading
- `/angular-style-audit` - Material theming, CSS custom properties
- `/django-model-audit` - Query optimization, indexes, constraints
- `/django-api-audit` - DRF serializers, permissions, pagination
- `/django-security-audit` - SQL injection, auth, permissions
- `/a11y-audit` - Comprehensive accessibility audit
- `/release-architect` - CI/CD pipeline audit and analysis

### Project Setup
- `/scaffold` - Interactive project scaffolding with Context7 research

### Utilities
- `/git-revise-history` - Interactive git history revision
- `/generate-slidedeck` - Generate presentation decks

## Architecture

### Plugin System
- **Commands Directory**: Each `.md` file defines a slash command with frontmatter and instructions
- **Plugin Manifest**: `.claude-plugin/plugin.json` configures MCP servers and command location
- **MCP Integration**: Context7 MCP server provides real-time documentation lookup

### Command Structure
Commands follow a consistent pattern:
1. **Frontmatter** (YAML): Command description
2. **Process**: Step-by-step instructions for Claude
3. **Examples**: Sample outputs and usage patterns
4. **Guidelines**: Best practices and constraints

### Branch Mode Pattern
Many audit commands support `--branch` or `-b` flags to audit only changed files:
```bash
/angular-style-audit --branch
```

This pattern is consistent across audit commands for efficiency.

### Expert Mode Pattern
Expert mode commands (`*-expert.md`) configure Claude with:
- Framework-specific knowledge and best practices
- Code patterns to enforce
- Common anti-patterns to flag
- Related audit commands to suggest

### Investigation Pattern
Investigation commands (`*-investigation.md`) follow:
1. **Input Handling**: JIRA ticket or manual description
2. **Context Gathering**: Existing investigations, ticket details
3. **Analysis**: Root cause analysis (5 Whys methodology)
4. **Documentation**: Generate comprehensive reports in `~/Documents/technical-analysis/`
5. **FVC Tracking**: Fix Verification Criteria for bug fixes

## Code Conventions

### Command File Naming
- Lowercase with hyphens: `commit-msg.md`, `pr-review.md`
- Descriptive of action: `implement-pr-feedback.md`
- Pattern suffixes:
  - `-expert.md`: Framework expertise modes
  - `-audit.md`: Specialized audits
  - `-investigation.md`: Analysis commands

### Command Structure
```markdown
# Command Title

Brief description of what this command does.

**Arguments:** $ARGUMENTS (if applicable)

## Process:

### 1. Step Name
- Substep 1
- Substep 2

### 2. Next Step
...

## Example Output:
[Example showing expected result]

## Notes:
- Key constraints
- Required tools
- Important warnings
```

### Bash Code Blocks
- Use `bash` syntax highlighting
- Include descriptive comments
- Check for command availability before execution
- Provide fallback or error messages

### Report Generation
Commands that generate reports use:
```bash
REPORT_BASE="${REPORT_BASE:-$HOME/Documents/technical-analysis}"
```
Default location: `~/Documents/technical-analysis/`

## Common Workflows

### Adding a New Workflow Command

1. **Create command file:**
   ```bash
   touch commands/my-command.md
   ```

2. **Add frontmatter and structure:**
   ```markdown
   ---
   description: Brief description of command
   ---
   
   # My Command
   
   Full description...
   
   ## Process:
   
   ### 1. First Step
   ...
   ```

3. **Test the command:**
   ```bash
   # Reload plugins in Claude Code
   /plugin reload atm
   
   # Try the command
   /my-command
   ```

### Conducting a PR Review

1. **Get PR URL from GitHub:**
   ```bash
   gh pr list
   ```

2. **Run review command:**
   ```bash
   /pr-review 123
   ```

3. **Claude will:**
   - Fetch PR details via `gh` CLI
   - Checkout PR branch
   - Analyze patterns against existing codebase
   - Search documentation via Context7
   - Generate educational summary
   - Provide testing instructions with FVC

### Generating a Commit Message

1. **Stage your changes:**
   ```bash
   git add src/component.tsx
   ```

2. **Run commit message generator:**
   ```bash
   /commit-msg
   ```

3. **Claude will:**
   - Extract JIRA ticket from branch name (`PRO-1234`, `BUG-567`)
   - Analyze staged changes
   - Check for new TODO comments
   - Generate conventional commit message
   - Copy to clipboard via `pbcopy`

### Running an Audit

1. **For full project audit:**
   ```bash
   /angular-style-audit
   ```

2. **For branch-only audit:**
   ```bash
   /angular-style-audit --branch
   ```

3. **Claude will:**
   - Check eligibility (skip if not applicable)
   - Scan for issues with confidence scoring
   - Generate detailed report
   - Save to `~/Documents/technical-analysis/audits/`

## Environment Variables

### Optional Configuration

- **`REPORT_BASE`**: Base directory for generated reports
  - Default: `$HOME/Documents/technical-analysis`
  - Example: `export REPORT_BASE="$HOME/Projects/reports"`

- **`EDU_CLIENTS_PATH`**: Path to frontend repository (for multi-repo investigations)
  - Default: `../edu-clients`
  - Example: `export EDU_CLIENTS_PATH="/Users/dev/projects/edu-clients"`

- **`API_WORKPLACE_PATH`**: Path to backend repository
  - Default: `../api-workplace`
  - Example: `export API_WORKPLACE_PATH="/Users/dev/projects/api-workplace"`

### External Tool Configuration

Commands rely on authenticated CLIs:

```bash
# GitHub CLI authentication
gh auth status  # Check status
gh auth login   # Authenticate

# JIRA CLI authentication
jira init       # Configure JIRA instance
```

## Key Design Principles

1. **Commands are Declarative**: Each command file is instructions for Claude, not executable code
2. **Tool Agnostic**: Commands use external CLIs (`gh`, `jira`, `git`) rather than embedding logic
3. **Context-Aware**: Commands check for previous work, existing patterns, and available repositories
4. **Educational Focus**: PR reviews and investigations include learning points for junior engineers
5. **Verification-Driven**: Bug investigations enforce Fix Verification Criteria (FVC) before closing
6. **Progressive Disclosure**: Audit commands use confidence scoring to surface only high-signal findings
7. **Branch Mode Efficiency**: Audit only changed files when using `--branch` flag
8. **MCP Integration**: Commands leverage Context7 for real-time documentation research

## Testing Philosophy

This project consists of markdown command definitions, not traditional code. Testing approach:

1. **Manual Testing**: Run commands in real scenarios to verify behavior
2. **Pattern Consistency**: Ensure commands follow established patterns (branch mode, report generation)
3. **Example Validation**: Keep example outputs in commands up-to-date with actual results
4. **CLI Availability**: Commands gracefully handle missing CLIs (`gh`, `jira`) with informative errors

## Notes

- **No Build Step**: This is a plugin definition, not a compiled project
- **Command Discovery**: All `.md` files in `commands/` are automatically available as slash commands
- **MCP Servers**: Context7 runs via `npx` (no install), Serena requires `uvx`
- **Clipboard Integration**: macOS-specific (`pbcopy`) - Linux users need `xclip` or `xsel`
- **Report Storage**: Generated reports are standalone Markdown files, ideal for Obsidian
- **Git Hooks**: Includes `.git/hooks/prepare-commit-jira.sh` for JIRA ticket extraction