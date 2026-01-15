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
      "preCommit": ["string"],
      "validationScenario": {
        "type": "frontend | api | database | none",
        "devServer": "string",
        "port": "number",
        "steps": "string",
        "successCriteria": ["string"]
      },
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
| `preCommit` | array | **REQUIRED for passes: true.** Must contain all mandatory passes for story type. Minimum: `["code-simplifier", "code-review"]` (all stories). Frontend React stories add: `"vercel-react-best-practices"`, `"web-design-guidelines"`, optionally `"rams"`. Empty array `[]` only for incomplete stories. |
| `validationScenario` | object | **Optional.** Runtime validation config (see validationScenario Fields below). Omit or set `type: "none"` to skip. |
| `notes` | string | Optional field for implementation notes or blockers |

### validationScenario Fields

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Type of validation: `"frontend"`, `"api"`, `"database"`, or `"none"` |
| `devServer` | string | Command to start dev server (e.g., `"npm run dev"`) |
| `port` | number | Port the dev server runs on (e.g., `3000`) |
| `steps` | string | Natural language description of validation steps to execute |
| `successCriteria` | array | List of success criteria to verify (e.g., `["No console errors", "Page renders correctly"]`) |

**When to use each type:**
- `frontend`: UI components, pages, visual changes. Uses **agent-browser** (primary) or Playwright MCP tools (fallback).
- `api`: Backend endpoints, server actions. Uses CURL requests or agent-browser.
- `database`: Data persistence, migrations. Uses database queries.
- `none`: No runtime validation needed (code-only changes).

**Validation Tools:**
- **Primary:** `/agent-browser` - Faster, natural language browser automation
- **Fallback:** Playwright MCP tools - Used if agent-browser unavailable

### Important: `passes` Field Semantics

The `passes` field indicates whether a story is **fully complete**. It should ONLY be set to `true` when ALL mandatory conditions for the story type are met.

#### Tiered Quality Review System

**Tier 1 - Mandatory (ALL stories):**
- `code-simplifier` - Code simplification and cleanup
- `code-review` - Bug detection with fresh context

**Tier 2 - Conditional Mandatory (based on story type):**
- `vercel-react-best-practices` - MANDATORY for frontend-react stories
- `web-design-guidelines` - MANDATORY for all frontend stories (react and other)

**Tier 3 - Agent-Decided:**
- `rams` - Visual polish (MANDATORY/RECOMMENDED/UNUSED based on story analysis)
- `frontend-design` - Used during implementation, tracked in `notes`

#### Conditions for `passes: true`

**For ALL stories:**
1. ✓ `code-simplifier` executed and improvements applied
2. ✓ `code-review` executed and issues fixed
3. ✓ Quality checks pass (typecheck, lint, tests)
4. ✓ Commit is successful

**For frontend-react stories, ALSO:**
5. ✓ `vercel-react-best-practices` executed
6. ✓ `web-design-guidelines` executed
7. ✓ `rams` executed OR documented reason for skip
8. ✓ Runtime validation passed (if validationScenario exists) using agent-browser

**For frontend-other stories, ALSO:**
5. ✓ `web-design-guidelines` executed
6. ✓ `rams` executed OR documented reason for skip
7. ✓ Runtime validation passed (if validationScenario exists)

**⛔ NEVER set `passes: true` if:**
- `preCommit` is empty `[]`
- `preCommit` missing mandatory passes for story type
- Runtime validation failed (when `validationScenario` exists)
- Any acceptance criterion is not met
- Quality checks fail

#### Examples by Story Type

**Backend story (minimal):**
```json
{
  "passes": true,
  "preCommit": ["code-simplifier", "code-review"],
  "notes": "API endpoint implementation. No frontend skills applicable."
}
```

**Frontend React story (all passes):**
```json
{
  "passes": true,
  "preCommit": ["code-simplifier", "vercel-react-best-practices", "web-design-guidelines", "code-review", "rams"],
  "notes": "frontend-design used for PriorityBadge component. agent-browser validation passed."
}
```

**Frontend React story (rams skipped):**
```json
{
  "passes": true,
  "preCommit": ["code-simplifier", "vercel-react-best-practices", "web-design-guidelines", "code-review"],
  "notes": "rams skipped: no new visual elements, only logic changes. agent-browser validation passed."
}
```

**⛔ INVALID (will be rejected):**
```json
{
  "passes": true,
  "preCommit": ["code-simplifier"]  // Missing code-review (mandatory for all)!
}
```

```json
{
  "passes": true,
  "preCommit": ["code-simplifier", "code-review"]  // Frontend React but missing vercel-react-best-practices!
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
        "Typecheck passes"
      ],
      "priority": 2,
      "dependencies": ["US-001"],
      "passes": false,
      "preCommit": [],
      "validationScenario": {
        "type": "frontend",
        "devServer": "npm run dev",
        "port": 3000,
        "steps": "Navigate to /tasks, verify task cards display priority badges with correct colors",
        "successCriteria": [
          "No console errors",
          "Priority badges visible on each task card",
          "Colors match specification (red/yellow/gray)"
        ]
      },
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
        "Typecheck passes"
      ],
      "priority": 3,
      "dependencies": ["US-001"],
      "passes": false,
      "preCommit": [],
      "validationScenario": {
        "type": "frontend",
        "devServer": "npm run dev",
        "port": 3000,
        "steps": "Navigate to /tasks, click edit on a task, change priority dropdown, verify change persists",
        "successCriteria": [
          "No console errors",
          "Priority dropdown renders with current value",
          "Selection change triggers save",
          "New priority reflects in task card"
        ]
      },
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
        "Typecheck passes"
      ],
      "priority": 4,
      "dependencies": ["US-001", "US-002"],
      "passes": false,
      "preCommit": [],
      "validationScenario": {
        "type": "frontend",
        "devServer": "npm run dev",
        "port": 3000,
        "steps": "Navigate to /tasks, select 'High' filter, verify URL updates and only high priority tasks shown",
        "successCriteria": [
          "No console errors",
          "URL contains priority filter param",
          "Only high priority tasks displayed",
          "Empty state shows when no matches"
        ]
      },
      "notes": ""
    }
  ]
}
```

### Example of Completed Backend Story (minimal passes)

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
  "preCommit": ["code-simplifier", "code-review"],
  "notes": "Backend story - frontend skills not applicable. Used Prisma enum for type safety."
}
```

### Example of Completed Frontend React Story (all passes)

```json
{
  "id": "US-002",
  "title": "Display priority indicator on task cards",
  "description": "As a user, I want to see task priority at a glance.",
  "acceptanceCriteria": [
    "Each task card shows colored priority badge",
    "Priority visible without hovering",
    "Typecheck passes"
  ],
  "priority": 2,
  "dependencies": ["US-001"],
  "passes": true,
  "preCommit": ["code-simplifier", "vercel-react-best-practices", "web-design-guidelines", "code-review", "rams"],
  "validationScenario": {
    "type": "frontend",
    "devServer": "npm run dev",
    "port": 3000,
    "steps": "Navigate to /tasks, verify badges render correctly",
    "successCriteria": [
      "No console errors",
      "Priority badges visible"
    ]
  },
  "notes": "frontend-design used for PriorityBadge component. agent-browser validation passed. vercel-react: memoized component. web-design-guidelines: added aria-label. rams: improved color contrast."
}
```

### Example of Frontend Story (rams skipped with reason)

```json
{
  "id": "US-003",
  "title": "Add priority selector to task edit",
  "description": "As a user, I want to change a task's priority when editing it.",
  "acceptanceCriteria": [
    "Priority dropdown in task edit modal",
    "Saves immediately on selection change",
    "Typecheck passes"
  ],
  "priority": 3,
  "dependencies": ["US-001"],
  "passes": true,
  "preCommit": ["code-simplifier", "vercel-react-best-practices", "web-design-guidelines", "code-review"],
  "validationScenario": {
    "type": "frontend",
    "devServer": "npm run dev",
    "port": 3000,
    "steps": "Click edit, change priority, verify save",
    "successCriteria": ["Priority updates correctly"]
  },
  "notes": "rams skipped: using existing dropdown component, no new visual elements. agent-browser validation passed."
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
