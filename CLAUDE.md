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
4. **Each iteration:** picks one story, implements it, runs pre-commit tools, commits, updates PRD
5. **Stops when:** all stories have `passes: true` or max iterations reached

### Safety Features

- **Dedicated branch**: All work happens on a feature branch, easy to review/revert
- **Sandboxed execution**: Claude Code sandboxes destructive commands
- **Atomic commits**: Each story = 1 commit (implementation + prd.json + progress.md)
- **Pre-commit quality gates**: Code is simplified and reviewed before every commit
- **Runtime validation**: Browser-based validation for UI stories catches runtime bugs
- **No interactive prompts**: Runs fully in background, no blocking questions

## Debugging Commands

```bash
# Check story status
cat ./docs/prd/feature/prd.json | jq '.userStories[] | {id, title, passes, preCommit}'

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
- **Two-pass quality review**: Every story runs code-simplifier AND code-review before committing
- **Runtime validation**: Stories with `validationScenario` run browser/API tests before commit
- **Available skills**: frontend-design skill for UI work, Context7 for docs, Playwright for browser
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
6. **⛔ MANDATORY: Run Quality Review Phase (2 passes)**
   - Pass 1: code-simplifier (simplify code)
   - Pass 2: code-review (find bugs)
7. **Run Runtime Validation** (if story has `validationScenario` in PRD)
   - Start dev server, launch browser, execute validation steps
   - Check console for errors, verify success criteria
8. Update prd.json: `passes: true`, `preCommit: ["code-simplifier", "code-review"]`
9. Append detailed log to progress.md
10. **Single Commit (feat):** Stage implementation + prd.json + progress.md together
11. **Push to remote** (backup immediately, first push creates remote branch)
12. **Print confirmation block** (after all steps complete)

**Result: 1 commit per story (feat with everything)**

**⛔ NEVER set passes: true if preCommit doesn't contain BOTH tools. Both passes MUST be run.**
**⛔ NEVER commit if runtime validation fails (when validationScenario exists).**

---

## Quality Review Phase (MANDATORY - 2 PASSES)

**Both passes are MANDATORY before every commit.**

```
┌──────────────────────────────────────────────────────────────┐
│                 QUALITY REVIEW PHASE                         │
│                                                              │
│  Pass 1: code-simplifier  →  Apply Changes  →  Quality Check │
│                            ↓                                 │
│  Pass 2: code-review      →  Fix Issues     →  Quality Check │
│                            ↓                                 │
│  Validation Gate          →  Ready to Commit                 │
└──────────────────────────────────────────────────────────────┘
```

---

### Pass 1: Code Simplification

Spawn the `code-simplifier:code-simplifier` agent with fresh context.

**Invoke via Task tool:**
```json
{
  "subagent_type": "code-simplifier:code-simplifier",
  "prompt": "Simplify and refine these files for clarity and maintainability while preserving functionality:\n- /absolute/path/to/file1.ts\n- /absolute/path/to/file2.ts",
  "description": "Simplify modified files"
}
```

**What it does:**
- Simplifies code for clarity and maintainability
- Preserves exact functionality
- Applies project coding standards
- Improves naming, reduces complexity

**After running:**
1. Apply ALL suggested improvements
2. Re-run quality checks if code changed

---

### Pass 2: Code Review

Spawn a `general-purpose` agent with fresh context to review for bugs.

**Invoke via Task tool:**
```json
{
  "subagent_type": "general-purpose",
  "prompt": "You are a senior code reviewer. Review the following modified files for bugs and issues.\n\n## Review Focus\n1. **Bugs**: Logic errors, null handling, race conditions\n2. **Security**: Input validation, injection vulnerabilities\n3. **Edge Cases**: Error handling, boundary conditions\n4. **Correctness**: Does code do what it should?\n\n## Output Format\nFor each issue:\n- File: /path/to/file.ts\n- Line: 42\n- Severity: HIGH | MEDIUM | LOW\n- Description: What is wrong\n- Suggested Fix: How to fix\n\n## Rules\n- Only report >80% confidence issues\n- Do NOT report style issues (handled by code-simplifier)\n- If no issues: respond 'No issues found.'\n\n## Files to Review\n- /absolute/path/to/file1.ts\n- /absolute/path/to/file2.ts",
  "description": "Review modified files for bugs and issues"
}
```

**What it does:**
- Reviews code with fresh context (no implementation bias)
- Finds bugs, security issues, edge cases
- Provides severity ratings (HIGH/MEDIUM/LOW)

**After running:**
1. Fix ALL HIGH severity issues
2. Fix MEDIUM issues if reasonable
3. Re-run quality checks if code changed

---

### Validation Gate

Before committing, verify:
- ✓ Pass 1 (code-simplifier) executed
- ✓ Pass 2 (code-review) executed
- ✓ All HIGH severity issues fixed
- ✓ Quality checks pass

**preCommit must contain:** `["code-simplifier", "code-review"]`

---

## Commit Requirements

- Stage only files modified for THIS story (no `git add -A`)
- Use detailed commit format with: PRD context, acceptance criteria, files changed, decisions, validation
- Print confirmation block after successful commit
- Only set `passes: true` if:
  - BOTH quality review passes were run
  - Commit was successful
  - All acceptance criteria verified

### Console Output (for monitoring)

Print status at each phase:
1. **▶ STARTING** block when selecting story (shows dependencies, criteria)
2. **QUALITY CHECKS** results after running checks
3. **QUALITY REVIEW** results for both passes:
   - Pass 1: refinements applied
   - Pass 2: issues found/fixed by severity
4. **RUNTIME VALIDATION** results (if validationScenario exists):
   - Type, scenario, expected vs actual
   - Conclusion (PASSED/FAILED/SKIPPED)
5. **✓ STORY COMPLETE** block with:
   - Commit hash (single feat commit)
   - Files changed (+new, ~modified, -deleted)
   - Tools, skills, agents used
   - Runtime validation results
   - Quality review details (both passes)
   - Push status (success or failure)
   - Progress bar and percentage
   - Next story preview

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
