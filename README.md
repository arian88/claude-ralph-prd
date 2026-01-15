# Ralph PRD

Autonomous PRD-to-implementation workflow for Claude Code. Create detailed Product Requirements Documents and run iterative development loops where Claude implements features until completion.

## What is Ralph PRD?

Ralph PRD is a Claude Code plugin that enables autonomous feature development through PRDs. It provides:

- **PRD Generation**: Create detailed Product Requirements Documents from feature descriptions
- **Autonomous Implementation**: Convert PRDs to JSON and let Claude implement features iteratively
- **Memory Persistence**: Each iteration spawns fresh context, with memory persisting via git history, `progress.md`, and `prd.json`

**Command:** `/ralph-prd`

| Action | Example |
|--------|---------|
| Create PRD | `/ralph-prd Add user authentication` |
| Convert to JSON | `/ralph-prd convert ./docs/prd/auth/prd.md` |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- bash shell
- jq (for debugging): `brew install jq` (macOS) or `apt install jq` (Linux)

## Recommended Skills (Optional)

Ralph can leverage additional skills for enhanced code quality and validation. These are not required but will be automatically used when available.

### Built-in Quality Passes (Always Mandatory)

These two passes run on EVERY commit, regardless of story type:

| Pass | What it does |
|------|--------------|
| **code-simplifier** | Simplifies code for clarity and maintainability while preserving functionality |
| **code-review** | Reviews code with fresh context to catch bugs, security issues, and edge cases |

> **Note:** These are built-in and do not require installation. The `preCommit` field must always contain both `["code-simplifier", "code-review"]` at minimum.

### Optional Quality Review Skills

| Skill | What it does | When Ralph uses it |
|-------|--------------|-------------------|
| **vercel-react-best-practices** | React/Next.js optimization guidelines from Vercel Engineering | Mandatory for React/Next.js stories. Reviews components for performance patterns, memoization, code splitting. |
| **web-design-guidelines** | Accessibility, keyboard support, forms, animation, and performance review | Mandatory for all frontend stories. Ensures WCAG compliance and UX best practices. |
| **rams** | Design engineer for visual polish and accessibility audits | Agent decides per story. Used for UI polish, color contrast, spacing consistency. |
| **frontend-design** | Creates distinctive, production-grade UI (avoids generic AI aesthetics) | Agent decides per story. Used when creating new components or pages. |

### Validation Tools

| Tool | What it does | When Ralph uses it |
|------|--------------|-------------------|
| **agent-browser** | Fast, natural language browser automation | Primary validation tool for frontend stories. Verifies UI renders correctly, checks for console errors. |

### Installation Commands

```bash
# vercel-react-best-practices (React/Next.js optimization)
# https://vercel.com/blog/introducing-react-best-practices
npx add-skill vercel-labs/agent-skills

# web-design-guidelines (accessibility and UX review)
# https://vercel.com/changelog/web-interface-guidelines-now-available-as-an-agent-command
curl -fsSL https://vercel.com/design/guidelines/install | bash

# agent-browser (browser automation for validation)
# https://github.com/vercel-labs/agent-browser
npm install -g agent-browser && agent-browser install

# rams (visual polish and accessibility)
# https://www.rams.ai
curl -fsSL https://rams.ai/install | bash

# frontend-design (production-grade UI creation)
# https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md
/plugin marketplace add anthropics/claude-code
/plugin install frontend-design@claude-code-plugins
```

### Skill Usage by Story Type

Ralph automatically determines which optional skills to use based on story type. The built-in passes (code-simplifier, code-review) always run.

| Story Type | Additional Mandatory Skills | Agent-Decided Skills |
|------------|----------------------------|----------------------|
| Frontend (React) | vercel-react-best-practices, web-design-guidelines | frontend-design, rams |
| Frontend (Other) | web-design-guidelines | frontend-design, rams |
| Backend | None | None |
| Config | None | None |

> **Note:** If an optional skill is not installed, Ralph will skip it and continue. The `preCommit` field in prd.json tracks which skills were actually executed for each story. It must always contain at minimum `["code-simplifier", "code-review"]`.

## Installation

### Plugin Installation (Recommended)

Install via the Claude Code plugin manager:

```bash
# Add the marketplace
/plugin marketplace add arian88/claude-ralph-prd

# Install the plugin
/plugin install ralph-prd@ralph-prd-marketplace

# Enable the plugin (required for 3rd party plugins)
/plugin enable ralph-prd

# Verify installation
/help ralph-prd
```

> **Note:** As a 3rd party plugin, Ralph PRD is not enabled by default after installation. You must run `/plugin enable ralph-prd` to activate it. Plugin commands may vary by Claude Code version. See [Manual Installation](#manual-installation-skills) if needed.

### Manual Installation (Skills)

For users who prefer to copy skills directly to their project:

```bash
# Clone the repo
git clone https://github.com/arian88/claude-ralph-prd.git

# Copy to your project's .claude directory
cp -r claude-ralph-prd/skills your-project/.claude/skills
cp -r claude-ralph-prd/docs your-project/docs
cp claude-ralph-prd/CLAUDE.md your-project/CLAUDE.md
```

When using manual installation, the script path is:
```bash
./.claude/skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root .
```

## Quick Start

```bash
# Step 1: Create a PRD for your feature
/ralph-prd Add task priority levels to the app

# Step 2: Answer clarifying questions, PRD saved to:
#         ./docs/prd/task-priority/prd.md

# Step 3: Convert PRD to JSON for Ralph
/ralph-prd convert ./docs/prd/task-priority/prd.md

# Step 4: Run Ralph (autonomous loop)
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/task-priority --root .
```

## Plugin Contents

| Component | Description |
|-----------|-------------|
| Skill: `ralph-prd` | Creates PRDs and converts them to JSON |
| Script: `ralph.sh` | Runs autonomous implementation loop |
| References | PRD examples, JSON schema, agent instructions |

### Directory Structure

```
your-project/
├── docs/
│   └── prd/                   # PRD files stored here
│       └── <feature>/
│           ├── prd.md         # Human-readable PRD
│           ├── prd.json       # Machine-readable PRD
│           ├── progress.md    # Iteration log
│           └── archive/       # Previous runs
└── CLAUDE.md                  # Ralph agent instructions
```

## Usage

### Creating a PRD

```bash
/ralph-prd Add user authentication to the app
/ralph-prd Create a dashboard for analytics
```

The plugin will:
1. Enter plan mode and explore your codebase
2. Interview you with clarifying questions
3. Generate a detailed PRD with user stories
4. Save to `./docs/prd/<feature>/prd.md`

### Converting to JSON

```bash
/ralph-prd convert ./docs/prd/task-priority/prd.md
```

The plugin will:
1. Read and analyze the PRD
2. Validate story sizing and dependencies
3. Generate `prd.json` in the same directory
4. Provide the command to run Ralph

### Running the Autonomous Loop

```bash
# Basic usage (defaults to claude, 10 iterations)
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root .

# With more iterations
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root . --max 15

# With amp instead of claude
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root . --tool amp
```

**Script path by installation method:**
| Installation | Script Path |
|--------------|-------------|
| Plugin | `./skills/ralph-prd/scripts/ralph.sh` |
| Manual (.claude/) | `./.claude/skills/ralph-prd/scripts/ralph.sh` |

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
# Check which stories are done (with commit tracking)
cat ./docs/prd/task-priority/prd.json | jq '.userStories[] | {id, title, passes, commit, preCommit}'

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
# or for manual installation:
chmod +x ./.claude/skills/ralph-prd/scripts/ralph.sh
```

### Plugin not recognized
Verify installation: `/plugin list` should show `ralph-prd`

### Ralph not finding prd.json
Use the `--prd` flag with the directory path:
```bash
# Correct
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/task-priority --root .

# Incorrect (passing file path instead of directory)
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/task-priority/prd.json --root .
```

## Customization

### Adjusting Story Sizing
Edit `skills/ralph-prd/SKILL.md` to modify story sizing guidelines.

### Adding Quality Checks
Edit `skills/ralph-prd/references/prompt.md` to add additional quality requirements.

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
