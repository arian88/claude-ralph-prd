# prd.json Format Reference

This document describes the JSON format that Ralph uses for autonomous PRD execution.

---

## File Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Feature folder | `kebab-case` | `task-priority`, `user-notifications` |
| PRD file | Always `prd.md` | `prd.md` |
| JSON file | Always `prd.json` (same directory) | `prd.json` |
| Branch name | `ralph/<feature-kebab-case>` | `ralph/task-priority` |

### Directory Structure

```
./docs/prd/<feature>/
├── prd.md          # PRD document (created by /ralph-prd)
├── prd.json        # JSON format (created by /ralph-prd convert)
├── progress.md     # Iteration log (created by Ralph agent)
└── archive/        # Previous runs (created by Ralph agent)
```

---

## Schema

```json
{
  "project": "string",
  "branchName": "string",
  "description": "string",
  "userStories": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "acceptanceCriteria": ["string"],
      "priority": "number",
      "dependencies": ["string"],
      "passes": "boolean",
      "commit": "string",
      "preCommit": ["string"],
      "notes": "string"
    }
  ]
}
```

## Field Descriptions

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `project` | string | Name of the project or application |
| `branchName` | string | Git branch for this feature. Convention: `ralph/feature-name-kebab-case` |
| `description` | string | One-line description of the feature being implemented |
| `userStories` | array | Ordered list of user stories to implement |

### User Story Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier. Format: `US-001`, `US-002`, etc. |
| `title` | string | Short, descriptive title (5-10 words) |
| `description` | string | Full user story in "As a... I want... so that..." format |
| `acceptanceCriteria` | array | List of verifiable criteria. Must include "Typecheck passes" |
| `priority` | number | Execution order. Lower numbers run first |
| `dependencies` | array | Story IDs that must be completed first. Empty array `[]` if no dependencies. Example: `["US-001", "US-002"]` |
| `passes` | boolean | `false` initially. Set to `true` ONLY when ALL conditions are met (see below) |
| `commit` | string | Git commit hash when story was completed. Empty string `""` initially, populated by agent after successful commit |
| `preCommit` | array | **REQUIRED for passes: true.** Must contain `["code-simplifier", "code-review"]` when story is complete. Empty array `[]` only for incomplete stories. |
| `notes` | string | Optional field for implementation notes or blockers |

### Important: `passes` Field Semantics

The `passes` field indicates whether a story is **fully complete**. It should ONLY be set to `true` when ALL of these conditions are met:

1. **Quality Review Pass 1 executed** - `code-simplifier` agent was spawned and feedback applied
2. **Quality Review Pass 2 executed** - `code-review` agent was spawned and issues fixed
3. **preCommit is populated** - Contains `["code-simplifier", "code-review"]`
4. **All acceptance criteria verified** - Every criterion in the array has been checked
5. **Quality checks pass** - Typecheck, lint, and tests all succeed
6. **Commit is successful** - Changes are committed to git with proper message
7. **commit is populated** - The commit hash is stored in the PRD

**⛔ NEVER set `passes: true` if:**
- `preCommit` is empty `[]` - this means quality review was not run
- `preCommit` only contains one tool - BOTH are required
- Any acceptance criterion is not met
- Quality checks fail
- The commit was not created
- You are unsure whether criteria are satisfied

**Valid completed story:**
```json
{
  "passes": true,
  "commit": "abc123...",
  "preCommit": ["code-simplifier", "code-review"]
}
```

**⛔ INVALID (will be rejected):**
```json
{
  "passes": true,
  "commit": "abc123...",
  "preCommit": ["code-simplifier"]  // Missing code-review!
}
```

```json
{
  "passes": true,
  "commit": "abc123...",
  "preCommit": []  // Empty - no quality review!
}
```

---

## Example

```json
{
  "project": "MyApp",
  "branchName": "ralph/task-priority",
  "description": "Task Priority System - Add priority levels to tasks",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add priority field to database",
      "description": "As a developer, I need to store task priority so it persists across sessions.",
      "acceptanceCriteria": [
        "Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "priority": 1,
      "dependencies": [],
      "passes": false,
      "commit": "",
      "preCommit": [],
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Display priority indicator on task cards",
      "description": "As a user, I want to see task priority at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored priority badge (red=high, yellow=medium, gray=low)",
        "Priority visible without hovering or clicking",
        "Typecheck passes",
        "Verify in browser using MCP browser tools"
      ],
      "priority": 2,
      "dependencies": ["US-001"],
      "passes": false,
      "commit": "",
      "preCommit": [],
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "Add priority selector to task edit",
      "description": "As a user, I want to change a task's priority when editing it.",
      "acceptanceCriteria": [
        "Priority dropdown in task edit modal",
        "Shows current priority as selected",
        "Saves immediately on selection change",
        "Typecheck passes",
        "Verify in browser using MCP browser tools"
      ],
      "priority": 3,
      "dependencies": ["US-001"],
      "passes": false,
      "commit": "",
      "preCommit": [],
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "Filter tasks by priority",
      "description": "As a user, I want to filter the task list to see only high-priority items.",
      "acceptanceCriteria": [
        "Filter dropdown with options: All | High | Medium | Low",
        "Filter persists in URL params",
        "Empty state message when no tasks match filter",
        "Typecheck passes",
        "Verify in browser using MCP browser tools"
      ],
      "priority": 4,
      "dependencies": ["US-001", "US-002"],
      "passes": false,
      "commit": "",
      "preCommit": [],
      "notes": ""
    }
  ]
}
```

### Example of Completed Story (with tracking fields)

```json
{
  "id": "US-001",
  "title": "Add priority field to database",
  "description": "As a developer, I need to store task priority so it persists across sessions.",
  "acceptanceCriteria": [
    "Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')",
    "Generate and run migration successfully",
    "Typecheck passes"
  ],
  "priority": 1,
  "dependencies": [],
  "passes": true,
  "commit": "a1b2c3d4e5f6789012345678901234567890abcd",
  "preCommit": ["code-simplifier", "code-review"],
  "notes": "Used Prisma enum for type safety. Code review found no issues."
}
```

---

## Best Practices

### Story Sizing
Each story must be completable in ONE Ralph iteration. If a story is too big, split it.

**Right-sized:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

### Story Ordering
Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views

### Dependencies
Use the `dependencies` field to declare which stories must be completed first.

**Examples:**
- UI component depends on database schema: `"dependencies": ["US-001"]`
- Filter feature depends on both schema and display: `"dependencies": ["US-001", "US-002"]`
- No dependencies (first story or independent): `"dependencies": []`

**Rules:**
- Dependencies must reference valid story IDs within the same PRD
- Agent will skip stories whose dependencies have `passes: false`
- Circular dependencies are not allowed

### Acceptance Criteria
Must be verifiable, not vague.

**Good:** "Button shows confirmation dialog before deleting"
**Bad:** "Works correctly"

**Always include:**
- `"Typecheck passes"` for every story
- `"Verify in browser using MCP browser tools"` for UI stories

---

## Next Step After Creating prd.json

After creating the prd.json, provide the user with this copy-paste command (using ACTUAL path):

```
prd.json saved to: `./docs/prd/task-priority/prd.json`

**Next step** - Run Ralph autonomous agent:
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/task-priority --root .
```

### Ralph Options

```bash
# Basic usage (defaults to claude tool, 10 iterations)
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root .

# With more iterations
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root . --max 15

# With different tool
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root . --tool amp

# With all options
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/<feature> --root . --max 20 --tool claude
```

**Options:**
- `--prd <dir>` - PRD directory containing prd.json (required)
- `--root <dir>` - Project root directory where code lives (required)
- `--tool <amp|claude>` - AI tool to use (default: claude)
- `--max <number>` - Maximum iterations (default: 10)

> **Note:** Script path depends on installation method:
> - Plugin installation: Skills are automatically available
> - Template clone to `.claude/`: `./.claude/skills/ralph-prd/scripts/ralph.sh`
> - Direct repo clone: `./skills/ralph-prd/scripts/ralph.sh`
