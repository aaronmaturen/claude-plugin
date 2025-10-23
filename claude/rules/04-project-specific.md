# Project-Specific Rules

## Jira Integration
- Branch names typically follow the pattern: `PRO-####-description`
- Always extract ticket numbers from branch names when generating commit messages
- PRO prefix may vary based on project

## Code Style
- Follow existing patterns in the codebase
- Match indentation and formatting of surrounding code
- Don't add comments unless explicitly requested
- Preserve existing code style over personal preferences
- **Always default to Tailwind CSS classes for styling** - avoid Less, Sass, or vanilla CSS unless explicitly required

## Testing
- Check for test commands in package.json, Makefile, or similar
- Never assume specific test frameworks
- Ask user for test commands if unclear
- Run tests only when explicitly requested

### Django/Python Testing
- Always use `--keepdb` flag when running Django tests to preserve test database
- Example: `python manage.py test --keepdb` or `pytest --keepdb`
- For containerized Django apps: `docker exec DOCKER_CONTAINER python manage.py test --keepdb`

### TypeScript/Angular Testing
- Use Jest as the testing framework, not Jasmine
- Use MSW (Mock Service Worker) to mock API endpoints
- **NEVER mock code** - only mock external dependencies like API calls
- Test actual implementations, not mocked versions of your own code

### Frontend Testing
- Prefer adding `data-testid` attributes to components for test targeting
- Use `data-testid` instead of CSS selectors or class names for test queries
- This ensures tests remain stable when styling changes

## Angular Development Patterns

### Component Architecture
- Prefer component composition over inheritance or base classes
- Extract reusable functionality into separate components rather than creating shared base classes
- Keep components focused on single responsibilities
- Use clear Input/Output interfaces for component communication

### Forms and Validation
- Use reactive forms with proper form validation
- Implement custom validators as pure functions when possible
- Separate form logic from business logic
- Use Angular Material form fields with proper error handling

### Date Handling
- Avoid using UTC timezone parameters in DatePipe.transform() for date-only operations
- Use local timezone for date formatting when only dealing with dates (no times)
- Be cautious of timezone conversion issues that can shift dates by one day

## Task Management Guidelines

### TodoWrite Tool Usage
- Use TodoWrite tool proactively for complex multi-step tasks (3+ steps)
- Create todos BEFORE starting work on complex refactoring or feature development
- Mark todos as "in_progress" when starting work, "completed" immediately when finished
- Only have ONE task marked as "in_progress" at a time
- Use todos for planning and tracking, not just for user visibility

### When to Use TodoWrite
- Complex refactoring tasks that involve multiple components
- Multi-step implementations with clear sequential dependencies
- Tasks that require coordination across different files or systems
- Any work that benefits from breaking down into smaller, trackable pieces

### When NOT to Use TodoWrite
- Single, straightforward tasks that can be completed in one step
- Simple bug fixes or minor changes
- Tasks that are purely conversational or informational

## Meta-Tool Development
- When building tools that analyze or work with the rule system itself, use dynamic discovery rather than hard-coded file lists
- Use LS tool or similar to discover rule files at runtime to ensure completeness
- Design commands to be self-updating as the rule system evolves
