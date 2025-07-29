# Debugging and Troubleshooting Methodology

## Systematic Debugging Approach
1. **Identify the root cause** - Don't just fix symptoms
2. **Analyze existing code** - Understand current implementation before making changes
3. **Implement targeted fixes** - Address the specific issue, avoid over-engineering
4. **Test thoroughly** - Verify the fix works and doesn't break existing functionality
5. **Clean up unnecessary complexity** - Remove code that was added to work around the original issue

## Investigation Patterns
- Use console logging and debugging output to understand current state
- Add temporary debugging code to gather information, then remove it
- Look for patterns of similar issues in the codebase
- Check for root causes rather than applying band-aid fixes

## Code Quality During Debugging
- Remove unnecessary code after identifying root causes
- Simplify overly complex solutions when possible
- Document why changes were made if the reasoning isn't obvious
- Prefer understanding over quick fixes

## Common Anti-Patterns to Avoid
- Adding workarounds without understanding the underlying issue
- Over-complicating solutions when simple fixes are available
- Leaving debugging code in production
- Fixing symptoms while ignoring root causes
- Making multiple unrelated changes simultaneously