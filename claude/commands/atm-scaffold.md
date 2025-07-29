# ATM Scaffold Command

Interactive project scaffolding command that creates a new project with proper setup and initialization.

## Process:

1. **Framework/Language Selection**
   - Ask user to select from supported frameworks/languages:
     - React (TypeScript/JavaScript)
     - Next.js (TypeScript/JavaScript)
     - Node.js (TypeScript/JavaScript)
     - Python (Flask/FastAPI/Django)
     - Go
     - Rust
     - Vue.js (TypeScript/JavaScript)
     - Svelte/SvelteKit (TypeScript/JavaScript)
     - Other (user specifies)

2. **Project Information Gathering**
   - Ask for project name
   - Ask for project description (1-2 sentences)
   - Ask for any specific requirements or features needed
   - Ask clarifying questions based on framework choice:
     - For React/Next.js: UI library preference (Tailwind, Material-UI, etc.)
     - For Node.js: Database preference (PostgreSQL, MongoDB, etc.)
     - For Python: Framework preference and database choice
     - For Go: Web framework preference (Gin, Echo, etc.)
     - For any: Authentication needs, API requirements, deployment target

3. **Context7 Research & Planning**
   - Use Context7 to fetch up-to-date documentation for the selected framework
   - Research current best practices, latest features, and recommended setup patterns
   - Identify the most current tooling and configuration approaches
   - Gather framework-specific implementation patterns and conventions

4. **Generate TODO.md with Parallel Task Annotations**
   Create a comprehensive TODO.md file with the following structure (enhanced with Context7 insights and parallel execution markers):
   
   ```markdown
   # [Project Name] - Development Roadmap
   
   ## Project Overview
   [Description and key features]
   
   ## Phase 1: Project Initialization
   - [ ] Initialize git repository
   - [ ] Create appropriate .gitignore (framework + macOS) `[PARALLEL-1A]`
   - [ ] Set up project structure for [framework] `[PARALLEL-1A]`
   - [ ] Initialize package manager (npm/yarn/cargo/go mod/pip) `[PARALLEL-1B]`
   - [ ] Configure development environment `[PARALLEL-1B]`
   
   ## Phase 2: Core Setup (Context7-Enhanced)
   - [ ] [Framework-specific setup tasks based on latest docs] `[PARALLEL-2A]`
   - [ ] Configure linting and formatting (latest recommended configs) `[PARALLEL-2B]`
   - [ ] Set up testing framework (current best practices) `[PARALLEL-2C]`
   - [ ] Configure build system (optimized for chosen framework version) `[PARALLEL-2A]`
   
   ## Phase 3: Foundation Development
   - [ ] [Based on requirements gathered] `[PARALLEL-3A]`
   - [ ] Basic project skeleton `[PARALLEL-3A]`
   - [ ] Core functionality setup `[PARALLEL-3B]`
   
   ## Phase 4: Feature Development
   - [ ] [Specific features based on user input - marked individually]
   
   ## Phase 5: Testing & Documentation
   - [ ] Unit tests `[PARALLEL-5A]`
   - [ ] Integration tests (depends on Phase 4 completion)
   - [ ] README.md `[PARALLEL-5B]`
   - [ ] API documentation (if applicable) `[PARALLEL-5B]`
   
   ## Phase 6: Deployment Preparation
   - [ ] Production configuration `[PARALLEL-6A]`
   - [ ] CI/CD setup `[PARALLEL-6B]`
   - [ ] Deployment scripts `[PARALLEL-6A]`
   
   ## Parallel Execution Guide
   Tasks marked with the same `[PARALLEL-XY]` identifier can be executed simultaneously by different agents.
   Tasks without parallel markers must be completed sequentially or have dependencies.
   ```

5. **Interactive Execution with Context7 and Parallel Agents**
   After creating TODO.md, ask if the user wants to:
   - Start executing the Phase 1 tasks immediately (using Context7 + parallel agents)
   - Just provide the TODO.md for manual execution
   - Customize the roadmap further
   
   **During execution phases:**
   - Identify tasks marked with `[PARALLEL-XY]` identifiers
   - Create multiple sub-agents using the Task tool for simultaneous execution
   - Each agent gets Context7 access for implementation guidance
   - Coordinate parallel work while maintaining proper sequencing between phases
   - Use Context7 to fetch specific implementation examples and code snippets
   - Reference latest documentation for configuration files and setup commands
   - Apply current best practices from official framework documentation
   - Verify compatibility and optimal configuration for the chosen tech stack
   
   **Parallel Execution Strategy:**
   - Group tasks by parallel identifier (e.g., all `[PARALLEL-2A]` tasks run together)
   - Launch one Task agent per parallel group within each phase
   - Wait for all parallel tasks in a phase to complete before moving to next phase
   - Each agent reports back with completion status and any issues encountered

## Example Interaction Flow:

```
🚀 ATM Project Scaffolder

What framework/language would you like to use?
1. React (TypeScript/JavaScript)
2. Next.js (TypeScript/JavaScript) 
3. Node.js (TypeScript/JavaScript)
4. Python (Flask/FastAPI/Django)
5. Go
6. Rust
7. Vue.js (TypeScript/JavaScript)
8. Svelte/SvelteKit (TypeScript/JavaScript)
9. Other (specify)

> 2

Great! Next.js selected. TypeScript or JavaScript?
> TypeScript

What's your project name?
> my-awesome-app

Provide a brief description (1-2 sentences):
> A modern web application for managing personal tasks with real-time collaboration features.

Any specific UI library preference? (Tailwind, Material-UI, Chakra UI, or none)
> Tailwind

Do you need authentication? (yes/no)
> yes

What type of database? (PostgreSQL, MongoDB, SQLite, or none for now)
> PostgreSQL

Any API integrations needed?
> Stripe for payments, SendGrid for emails

🔍 Researching with Context7...
- Fetching latest Next.js documentation and best practices
- Getting current TypeScript + Tailwind configuration patterns
- Researching PostgreSQL integration approaches
- Finding Stripe and SendGrid implementation examples

✅ TODO.md created with Context7-enhanced roadmap!

Would you like me to:
1. Start executing Phase 1 tasks with parallel agents (git init, .gitignore, etc.)
2. Just provide the TODO.md for manual execution
3. Customize the roadmap further

> 1

🚀 Starting Phase 1 execution with parallel agents...

Creating agents for parallel task groups:
- Agent A: Handling [PARALLEL-1A] tasks (.gitignore, project structure)
- Agent B: Handling [PARALLEL-1B] tasks (package manager, dev environment)

✅ Phase 1 completed! All parallel tasks finished successfully.
Ready to proceed to Phase 2...
```

## Usage:
Run `/atm-scaffold` to start the interactive scaffolding process.

## Notes:
- Creates comprehensive TODO.md with phases enhanced by Context7 research
- Uses Context7 to fetch latest documentation and best practices for chosen framework
- Annotates tasks with `[PARALLEL-XY]` identifiers for concurrent execution
- Creates multiple sub-agents using Task tool for simultaneous work on parallel tasks
- Tailors questions based on framework selection
- Includes proper .gitignore for framework + macOS
- Can optionally execute initial setup tasks with Context7 guidance and parallel agents
- Focuses on current best practices for each framework from official docs
- Considers modern development workflows (TypeScript, testing, CI/CD)
- Leverages Context7 during implementation for up-to-date code examples and patterns
- Maximizes efficiency through intelligent parallel task execution while respecting dependencies