# Generate Deckset Markdown Slidedeck

Generate a markdown presentation in Deckset format for the entire repository, current branch, or a custom topic.

## Your Task

Create a professional, well-structured markdown presentation following Deckset formatting rules.

## Step 1: Determine Scope

Ask the user to select the scope for the slidedeck using the AskUserQuestion tool:

**Question**: "What would you like to create a slidedeck about?"
**Options**:
1. **Entire Repository** - Overview of the entire codebase, architecture, and key features
2. **Current Branch** - Focus on changes and features in the current git branch
3. **Custom Topic** - Specify a custom topic or focus area

## Step 2: Gather Information

Based on the selected scope:

### For "Entire Repository":
- Examine the repository structure
- Identify key components, architecture patterns
- Review README and documentation
- Identify main features and technologies used
- Look for package.json, go.mod, requirements.txt, etc. to understand dependencies

### For "Current Branch":
- Run `git rev-parse --abbrev-ref HEAD` to get branch name
- Run `git log main..HEAD --format='%s%n%b'` to get commit messages
- Run `git diff main...HEAD --stat` to see changed files
- Run `git diff main...HEAD` to understand the changes
- Analyze what features or fixes were implemented

### For "Custom Topic":
- Ask follow-up questions to understand the topic
- Search the codebase for relevant files and code
- Gather examples and key points related to the topic

## Step 3: Create Slidedeck Content

Follow these Deckset formatting rules (from ~/slidedecks/deckset_basics.md):

### Slide Structure:
- Start with directives (footer, slidenumbers, autoscale) on first lines
- Use `---` with empty lines above and below to separate slides
- Headers: Use `#`, `##`, `###`, or `####` for different sizes
- Paragraphs: Just type, leave empty line for breaks
- Lists: Use `1.` for ordered, `-` or `*` for unordered
- Emphasis: `**bold**`, `_italic_`, `**_both_**`
- Code: Use triple backticks with language for syntax highlighting
- Quotes: Use `>` prefix, `--` for author
- Images: `![](path.jpg)`, `![right](path.jpg)`, `![fit](path.jpg)`
- Speaker notes: Use `^` prefix
- Line breaks: Use `<br/>` if needed

### Recommended Slide Structure:
1. **Title slide** - Project name and tagline
2. **Overview** - High-level summary (2-3 bullets)
3. **Architecture/Structure** - Key components
4. **Key Features** - Main capabilities (one per slide if many)
5. **Technical Stack** - Technologies and tools used
6. **Code Examples** - Relevant code snippets with syntax highlighting
7. **Challenges & Solutions** - If applicable
8. **Future Work** - Roadmap or next steps
9. **Conclusion** - Summary and takeaways

## Step 4: Determine Output Path

- Get repository/project name from current directory: `basename $(pwd)`
- Create output directory: `~/slidedecks/{PACKAGE_NAME}/`
- Output filename: `presentation.md` (or `{branch-name}.md` for branch scope, or `{topic}.md` for custom)

## Step 5: Generate the Slidedeck

Create a well-structured presentation with:
- Professional, concise content
- Clear headers and sections
- Code examples with proper syntax highlighting
- Speaker notes where helpful (using `^` prefix)
- Consistent formatting throughout
- Footer with project name and date
- Slide numbers enabled
- Autoscale enabled

Example header directives:
```
footer: © {Project Name} - {Current Year}
slidenumbers: true
autoscale: true
```

## Step 6: Save the File

- Ensure the directory exists (create if needed): `mkdir -p ~/slidedecks/{PACKAGE_NAME}`
- Write the slidedeck content to the file
- Confirm to user with the full path

## Guidelines:

- Keep slides concise - one main idea per slide
- Use bullet points liberally
- Include code examples that are relevant and well-formatted
- Add speaker notes for complex slides (use `^` prefix)
- Use emphasis (**bold**, _italic_) to highlight key points
- Break up dense information across multiple slides
- Use headers consistently (# for main titles, ## for subtitles, etc.)
- Include visual hierarchy with different header levels
- Consider adding quotes for key insights or principles
- End with clear next steps or conclusions

## Output Format:

After creating the slidedeck, provide:
1. Full path to the created file
2. Slide count
3. Brief summary of the content covered
4. Suggestion to open in Deckset app

## Example Output Message:

```
Created slidedeck: ~/slidedecks/my-project/presentation.md

Summary:
- 15 slides covering project overview, architecture, and key features
- Includes code examples for main components
- Speaker notes added for technical deep-dives

Open in Deckset to present!
```
