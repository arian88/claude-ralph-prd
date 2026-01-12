# PRD Example Reference

This document provides a complete example of a well-structured PRD.

---

## File Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Feature folder | `kebab-case` | `task-priority`, `user-notifications` |
| PRD file | Always `prd.md` | `prd.md` |
| JSON file | Always `prd.json` (same directory) | `prd.json` |

### Directory Structure

```
./docs/prd/<feature>/
├── prd.md          # PRD document (created by /ralph-prd)
├── prd.json        # JSON format (created by /ralph-prd convert)
├── progress.md     # Iteration log (created by Ralph agent)
└── archive/        # Previous runs (created by Ralph agent)
```

---

## Example: Task Priority System

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering to help users manage their workload effectively.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering and sorting by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field to database
**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration successfully
- [ ] Typecheck passes

### US-002: Display priority indicator on task cards
**Description:** As a user, I want to see task priority at a glance so I know what needs attention first.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering or clicking
- [ ] Typecheck passes
- [ ] Verify in browser using MCP browser tools

### US-003: Add priority selector to task edit
**Description:** As a user, I want to change a task's priority when editing it.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] Typecheck passes
- [ ] Verify in browser using MCP browser tools

### US-004: Filter tasks by priority
**Description:** As a user, I want to filter the task list to see only high-priority items when I'm focused.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] Typecheck passes
- [ ] Verify in browser using MCP browser tools

## Functional Requirements

- FR-1: Add `priority` field to tasks table ('high' | 'medium' | 'low', default 'medium')
- FR-2: Display colored priority badge on each task card
- FR-3: Include priority selector in task edit modal
- FR-4: Add priority filter dropdown to task list header
- FR-5: Sort by priority within each status column (high to medium to low)

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
- Priority stored in database, not computed

## Success Metrics

- Users can change priority in under 2 clicks
- High-priority tasks immediately visible at top of lists
- No regression in task list performance

## Open Questions

- Should priority affect task ordering within a column?
- Should we add keyboard shortcuts for priority changes?
```

---

## Section Breakdown

### 1. Introduction/Overview
Brief description of the feature and the problem it solves. Keep it to 2-3 sentences.

### 2. Goals
Specific, measurable objectives as a bullet list. Answer: "What does success look like?"

### 3. User Stories
The core of the PRD. Each story needs:
- **ID**: Sequential (US-001, US-002)
- **Title**: Short descriptive name
- **Description**: "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria**: Verifiable checklist

**Important:**
- Each story should be small enough to implement in one session
- Always include "Typecheck passes" as a criterion
- For UI stories, always include "Verify in browser using MCP browser tools"

### 4. Functional Requirements
Numbered list of specific functionalities. Be explicit and unambiguous.
- "FR-1: The system must allow users to..."
- "FR-2: When a user clicks X, the system must..."

### 5. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope and preventing scope creep.

### 6. Technical Considerations (Optional)
- Known constraints or dependencies
- Integration points with existing systems
- Performance requirements
- Existing components to reuse

### 7. Success Metrics
How will success be measured?
- "Reduce time to complete X by 50%"
- "Increase conversion rate by 10%"

### 8. Open Questions
Remaining questions or areas needing clarification before implementation.

---

## Writing Tips

### For Junior Developers / AI Agents
The PRD reader may be a junior developer or AI agent. Therefore:
- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful

### Acceptance Criteria Best Practices

**Good (verifiable):**
- "Add status column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"

**Bad (vague):**
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Story Size Guidelines

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Next Step After Creating PRD

After creating the PRD, provide the user with this copy-paste command (using ACTUAL path):

```
PRD saved to: `./docs/prd/task-priority/prd.md`

**Next step** - Convert to JSON for Ralph:
/ralph-prd convert ./docs/prd/task-priority/prd.md
```
