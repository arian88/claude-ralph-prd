# Ralph PRD Plugin

Autonomous PRD-to-implementation workflow for Claude Code. Create detailed Product Requirements Documents and run iterative development loops where Claude implements features until completion.

Each iteration spawns a fresh Claude instance with clean context. Memory persists via git history, `progress.md`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/). Original repo: [snarktank/ralph](https://github.com/snarktank/ralph)

## Quick Start

```bash
# 1. Create PRD
/ralph-prd Add dark mode to the settings page

# 2. Convert to JSON
/ralph-prd convert ./docs/prd/dark-mode/prd.md

# 3. Run Ralph
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/dark-mode --root .
```

## Script Usage

```
ralph.sh --prd <dir> --root <dir> [--max <n>] [--tool <name>]
```

### Parameters

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--prd` | Yes | - | PRD directory (contains prd.json) |
| `--root` | Yes | - | Project root (where code lives) |
| `--max` | No | 10 | Maximum iterations |
| `--tool` | No | claude | AI tool: `claude` or `amp` |

### One-liner Examples

```bash
# Basic usage
ralph.sh --prd ./docs/prd/feature --root .

# More iterations
ralph.sh --prd ./docs/prd/feature --root . --max 20

# Use amp instead of claude
ralph.sh --prd ./docs/prd/feature --root . --tool amp

# Full example with absolute paths
ralph.sh --prd /path/to/docs/prd/feature --root /path/to/project --max 15 --tool claude

# Monorepo example (app in subdirectory)
ralph.sh --prd ./apps/myapp/docs/prd/feature --root ./apps/myapp
```

> **Script path by installation:**
> - Plugin: `./skills/ralph-prd/scripts/ralph.sh`
> - Manual (.claude/): `./.claude/skills/ralph-prd/scripts/ralph.sh`

## How It Works

1. **Creates/switches to a git branch** (from PRD `branchName` or auto-generated)
2. **Initializes progress.md** with metadata and structure
3. **Runs Claude in autonomous mode** (no prompts, makes decisions based on PRD)
4. **Each iteration:** picks one story, implements it, commits, updates PRD
5. **Stops when:** all stories have `passes: true` or max iterations reached

### Safety Features

- **Dedicated branch**: All work happens on a feature branch, easy to review/revert
- **Sandboxed execution**: Claude Code sandboxes destructive commands
- **Atomic commits**: Each story = one commit with clear message
- **No interactive prompts**: Runs fully in background, no blocking questions

## Debugging Commands

```bash
# Check story status (with commit tracking)
cat ./docs/prd/feature/prd.json | jq '.userStories[] | {id, title, passes, commit, preCommit}'

# View progress and learnings
cat ./docs/prd/feature/progress.md

# Check git history on feature branch
git log --oneline ralph/feature-name

# Diff against main
git diff main..ralph/feature-name
```

## Directory Structure

```
/docs/prd/<feature-name>/
├── prd.md          # Human-readable PRD (from /ralph-prd)
├── prd.json        # Machine-readable PRD (from /ralph-prd convert)
├── progress.md     # Iteration log (managed by Ralph)
├── .last-branch    # Branch tracking (managed by Ralph)
└── archive/        # Previous runs (managed by Ralph)
```

## Key Concepts

- **Fresh context each iteration**: Each run spawns a new Claude instance
- **Memory via files**: Git history, progress.md, and prd.json persist knowledge
- **Small tasks**: Each story should complete in one context window
- **Autonomous decisions**: Agent makes choices based on PRD, documents them
- **Stop condition**: `<promise>COMPLETE</promise>` when all stories pass

---

# Ralph Agent Instructions

> For the autonomous agent during execution.

## Critical: Autonomous Mode

**NEVER ask questions.** This is non-interactive.

- Do NOT ask "Should I continue?" - Just continue
- Do NOT offer options - Make the best choice
- Do NOT wait for input - It will never come

**Make decisions based on the PRD. Document choices in progress.md.**

## Environment Variables

Provided at prompt start:
- `PRD_FILE` - path to prd.json
- `PROGRESS_FILE` - path to progress.md
- `PRD_DIR` - PRD directory
- `BRANCH_NAME` - git branch

Working directory = project root.

## Task Per Iteration

1. Read `PRD_FILE` and `PROGRESS_FILE` (Codebase Patterns section first)
2. Pick highest priority story with `passes: false` (check `dependencies` are met)
3. Run `git status` to capture pre-implementation state
4. Implement it (track every file modified)
5. Run quality checks (typecheck, lint, tests)
6. Run pre-commit tools if available (`code-simplifier`, then `code-review`)
7. Commit with detailed message (see prompt.md for format)
8. Update PRD: set `passes: true`, `commit: <hash>`, `preCommit: [tools used]`
9. Append detailed log to progress.md

### Commit Requirements
- Stage only files modified for THIS story (no `git add -A`)
- Use detailed commit format with: PRD context, acceptance criteria, files changed, decisions, validation
- Print confirmation block after successful commit
- Only set `passes: true` if commit was successful

## Decision Framework

| Situation | Action |
|-----------|--------|
| Multiple approaches | Pick simplest that meets criteria |
| Missing details | Use reasonable defaults, document |
| Unclear requirements | Interpret from context, document |
| Technical tradeoffs | Prioritize: correctness > simplicity > performance |

## Stop Condition

If ALL stories have `passes: true`:
```
<promise>COMPLETE</promise>
```

Otherwise, end normally for next iteration.
