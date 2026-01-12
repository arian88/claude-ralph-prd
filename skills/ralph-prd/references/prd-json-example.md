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
  "project": "string",           // Project name
  "branchName": "string",        // Git branch (format: ralph/feature-name)
  "description": "string",       // Brief feature description
  "userStories": [
    {
      "id": "string",            // Story ID (format: US-001, US-002, etc.)
      "title": "string",         // Short descriptive title
      "description": "string",   // User story format: "As a [user], I want [feature] so that [benefit]"
      "acceptanceCriteria": [    // Array of verifiable criteria
        "string"
      ],
      "priority": "number",      // Execution order (1 = first)
      "passes": "boolean",       // true when story is complete
      "notes": "string"          // Optional notes from implementation
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
| `priority` | number | Execution order. Lower numbers run first. Use for dependencies |
| `passes` | boolean | `false` initially, set to `true` when story is complete |
| `notes` | string | Optional field for implementation notes or blockers |

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
      "passes": false,
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
      "passes": false,
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
      "passes": false,
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
      "passes": false,
      "notes": ""
    }
  ]
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
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/task-priority/
```

### Ralph Options

```bash
# Basic usage (defaults to claude tool, 10 iterations)
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/

# With more iterations
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/ --max-iterations 15

# With different tool
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/ --tool amp

# With both options
./skills/ralph-prd/scripts/ralph.sh ./docs/prd/<feature>/ --tool amp --max-iterations 5
```

**Options:**
- `--tool <amp|claude>` - AI tool to use (default: claude)
- `--max-iterations <number>` - Maximum iterations (default: 10)

> **Note:** Script path depends on installation method:
> - Plugin installation: Skills are automatically available
> - Template clone to `.claude/`: `./.claude/skills/ralph-prd/scripts/ralph.sh`
> - Direct repo clone: `./skills/ralph-prd/scripts/ralph.sh`
