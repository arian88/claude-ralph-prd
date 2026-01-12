# Claude Ralph

An autonomous PRD-to-implementation AI agent system for Claude Code. Generate detailed Product Requirements Documents and let Ralph implement them iteratively.

## What is Ralph?

Ralph is an autonomous coding agent that implements features from PRDs iteratively. Each iteration spawns a fresh Claude instance with clean context. Memory persists via git history, `progress.md`, and `prd.json`.

**Single Command:** Use `/ralph-prd` for both creating PRDs and converting them to JSON.

**Workflow:**
1. `/ralph-prd Add user authentication` - generates detailed PRD
2. `/ralph-prd convert ./docs/prd/auth/prd.md` - converts PRD to JSON format
3. `ralph.sh` script runs an autonomous loop where Claude implements each user story iteratively

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- bash shell
- jq (for debugging commands): `brew install jq` (macOS) or `apt install jq` (Linux)

## Installation

### Option 1: Claude Code Plugin (Recommended)

Install via the Claude Code marketplace:

```bash
# Add the marketplace
/plugin marketplace add arian88/claude-ralph-prd

# Install the plugin
/plugin install ralph-prd@ralph-prd-marketplace

# Verify installation
/help ralph-prd
```

> **Note:** Plugin installation commands may vary depending on your Claude Code version. If these commands don't work, use Option 2 (Clone as Template) instead.

### Option 2: Clone as Template

Clone this repo and copy the relevant files to your project:

```bash
# Clone the repo
git clone https://github.com/arian88/claude-ralph-prd.git

# Copy to your project
cp -r claude-ralph-prd/skills your-project/.claude/skills
cp -r claude-ralph-prd/docs your-project/docs
cp claude-ralph-prd/CLAUDE.md your-project/CLAUDE.md
```

**Important:** When using the template method, the script path changes:
```bash
# Run Ralph with template installation
./.claude/skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/
```

## Quick Start

```bash
# Step 1: Create a PRD for your feature
/ralph-prd Add task priority levels to the app

# Step 2: Answer the clarifying questions, PRD saved to:
#         ./docs/prd/task-priority/prd.md

# Step 3: Convert PRD to JSON for Ralph
/ralph-prd convert ./docs/prd/task-priority/prd.md

# Step 4: Run Ralph (autonomous loop)
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/task-priority/
```

## Directory Structure

```
your-project/
├── .claude/                   # For template installation
│   └── skills/
│       └── ralph-prd/
│           ├── SKILL.md
│           ├── references/
│           └── scripts/
│               └── ralph.sh
├── docs/
│   └── prd/                   # PRD files stored here
│       └── <feature>/
│           ├── prd.md         # Human-readable PRD
│           ├── prd.json       # Machine-readable PRD
│           ├── progress.md    # Iteration log
│           └── archive/       # Previous runs
└── CLAUDE.md                  # Ralph agent instructions
```

## Commands Reference

### /ralph-prd

Single command for PRD creation and conversion:

```bash
# Create a new PRD
/ralph-prd Add user authentication to the app
/ralph-prd Create a dashboard for analytics

# Convert existing PRD to JSON
/ralph-prd convert ./docs/prd/task-priority/prd.md
```

**When creating a PRD**, the skill will:
1. Enter plan mode and explore your codebase
2. Interview you with clarifying questions
3. Generate a detailed PRD with user stories
4. Save to `./docs/prd/<feature>/prd.md`

**When converting to JSON**, the skill will:
1. Read and analyze the PRD
2. Validate story sizing and dependencies
3. Generate `prd.json` in the same directory
4. Provide the command to run Ralph

### ralph.sh

Run the autonomous agent loop:

```bash
# Basic usage (defaults to claude, 10 iterations)
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/

# With more iterations
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/ --max-iterations 15

# With amp instead of claude
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/ --tool amp
```

**Options:**
- `--tool <amp|claude>` - AI tool to use (default: claude)
- `--max-iterations <number>` - Maximum iterations (default: 10)

> **Note:** Script path depends on installation method:
> - Plugin: Skills are automatically available
> - Template clone to `.claude/`: `./.claude/skills/ralph-prd/scripts/ralph.sh`
> - Direct repo clone: `./skills/ralph-prd/scripts/ralph.sh`

## Key Concepts

### Fresh Context Each Iteration

Each Ralph iteration spawns a new Claude instance with no memory of previous work. Memory persists only via:
- Git history (commits from previous iterations)
- `progress.md` (learnings and patterns discovered)
- `prd.json` (story completion status)

### Small Tasks

Each user story must be completable in ONE context window. If a story is too big, Ralph will produce broken code.

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### Feedback Loops

Ralph relies on quality checks to keep code working across iterations:
- Typecheck must pass
- Tests must pass
- CI must be green

Every story includes "Typecheck passes" as acceptance criteria.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and exits.

## Debugging

```bash
# Check which stories are done
cat ./docs/prd/task-priority/prd.json | jq '.userStories[] | {id, title, passes}'

# View learnings from previous iterations
cat ./docs/prd/task-priority/progress.md

# Check git history
git log --oneline -10
```

## Troubleshooting

### "jq: command not found"
Install jq: `brew install jq` (macOS) or `apt install jq` (Linux)

### Script permission denied
```bash
chmod +x ./skills/ralph-prd/scripts/ralph.sh
# or for template installation:
chmod +x ./.claude/skills/ralph-prd/scripts/ralph.sh
```

### Skills not recognized
Ensure skills are in the correct location:
- **Plugin:** Automatically handled by Claude Code
- **Template:** `./.claude/skills/ralph-prd/`
- **Direct clone:** `./skills/ralph-prd/`

### Ralph not finding prd.json
Make sure you're passing the directory path, not the file path:
```bash
# Correct
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/task-priority/

# Incorrect
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/task-priority/prd.json
```

## Customization

### Adjusting Story Sizing

Edit `skills/ralph-prd/SKILL.md` to modify the story sizing guidelines in the "Story Size: The Number One Rule" section.

### Adding Quality Checks

Edit `skills/ralph-prd/references/prompt.md` to add additional quality requirements for the autonomous agent.

### Changing File Paths

The default PRD directory is `./docs/prd/<feature>/`. To change this:
1. Update paths in `skills/ralph-prd/SKILL.md`
2. Update paths in reference files

## Credits

- [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/) - Original concept
- [snarktank/ralph](https://github.com/snarktank/ralph) - Original implementation
- [Claude Code ralph-wiggum plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) - Reference implementation

## License

MIT License - see [LICENSE](LICENSE) for details.
