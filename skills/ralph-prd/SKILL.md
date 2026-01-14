---
name: ralph-prd
description: "Autonomous PRD-to-implementation system. PROACTIVELY activate for: (1) creating Product Requirements Documents from feature requests, (2) converting PRDs to JSON for autonomous execution, (3) planning iterative feature development. Use '/ralph-prd' to create a PRD or '/ralph-prd convert' to prepare for autonomous implementation. Examples: '/ralph-prd Add user authentication', '/ralph-prd convert ./docs/prd/auth/prd.md'. Triggers: ralph-prd, create prd, convert prd, ralph, prd json, feature planning."
model: opus
allowed-tools: EnterPlanMode, ExitPlanMode, AskUserQuestion, Read, Write, Glob, Grep, Bash, TodoWrite
---

# Ralph PRD Generator

Single command for PRD creation and JSON conversion. Ralph is an autonomous coding agent that implements features from PRDs iteratively.

## References

- **[prd-example.md](./references/prd-example.md)** - Complete PRD example with section breakdown
- **[prd-json-example.md](./references/prd-json-example.md)** - JSON schema and complete example
- **[prompt.md](./references/prompt.md)** - Agent instructions for each iteration

---

## Routing Logic

**CRITICAL: FIRST determine what the user wants before proceeding.**

Analyze the user's request and route to the appropriate phase:

| User Request Contains | Action |
|-----------------------|--------|
| "create", "new", "generate", "write prd", "plan", "design", "add", "build", "implement" (feature descriptions) | → Go to **PHASE A: Create PRD** |
| "convert", "json", "run ralph", "prepare", "execute", "to json", "prd.md" | → Go to **PHASE B: Convert to JSON** |
| Unclear or ambiguous | → Ask user which action they want |

### Examples

| User Says | Route To |
|-----------|----------|
| "/ralph-prd Add user authentication" | PHASE A |
| "/ralph-prd create dashboard feature" | PHASE A |
| "/ralph-prd convert ./docs/prd/auth/prd.md" | PHASE B |
| "/ralph-prd run on task-priority" | PHASE B |
| "/ralph-prd" (no context) | Ask user |

### If Unclear, Ask:

```
AskUserQuestion:
- question: "What would you like to do?"
- header: "Action"
- options:
  - label: "Create PRD"
    description: "Generate a new Product Requirements Document for a feature"
  - label: "Convert to JSON"
    description: "Convert an existing PRD to prd.json for Ralph execution"
```

---

# PHASE A: Create PRD

Create detailed Product Requirements Documents that are clear, actionable, and suitable for implementation.

## Phase A Workflow

This phase operates in **two sub-phases**. Follow these steps in order. Do NOT skip any step.

```
┌─────────────────────────────────────────────────────────────┐
│  SUB-PHASE A1: PLANNING (in Plan Mode)                      │
│  ─────────────────────────────────────────────────────────  │
│  1. Enter Plan Mode (call EnterPlanMode tool)               │
│     ↓                                                       │
│  2. Explore Codebase for Context                            │
│     (Use Glob, Grep, Read to understand existing patterns)  │
│     ↓                                                       │
│  3. Ultrathink Analysis                                     │
│     (Analyze request, identify gaps, formulate questions)   │
│     ↓                                                       │
│  4. Interview User with AskUserQuestion                     │
│     (Questions informed by ultrathink analysis)             │
│     ↓                                                       │
│  5. Iterative Clarification Loop                            │
│     (Ultrathink → Ask → Ultrathink → Ask until clear)       │
│     ↓                                                       │
│  6. Final Ultrathink Validation                             │
│     (Validate requirements, stories, edge cases)            │
│     ↓                                                       │
│  7. Write Requirements Summary to Plan File                 │
│     ↓                                                       │
│  8. Exit Plan Mode (call ExitPlanMode tool)                 │
│     ↓                                                       │
│  [USER APPROVAL CHECKPOINT]                                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  SUB-PHASE A2: GENERATION (after approval)                  │
│  ─────────────────────────────────────────────────────────  │
│  9. Generate PRD Content                                    │
│     ↓                                                       │
│  10. Save File                                              │
│     ↓                                                       │
│  11. Confirm & Provide Next Step Command                    │
└─────────────────────────────────────────────────────────────┘
```

---

## A1: Enter Plan Mode

**CRITICAL: This is the FIRST action you MUST take for PRD creation.**

Call the `EnterPlanMode` tool immediately. This ensures:
- Proper exploration of the codebase before generating requirements
- User approval checkpoint before PRD generation
- Clean separation between planning and execution

```
Action: Call EnterPlanMode tool
```

Do NOT proceed until you are in plan mode.

---

## A2: Explore Codebase for Context

**Before asking questions, understand the existing codebase.**

Use these tools to gather context:
- `Glob` - Find relevant files (e.g., `**/*.tsx`, `**/*.py`)
- `Grep` - Search for patterns (e.g., existing similar features)
- `Read` - Examine key files (schemas, components, routes)

### What to Explore:

1. **Existing Patterns:**
   - How are similar features implemented?
   - What components/utilities exist that could be reused?

2. **Technical Context:**
   - Database schema structure
   - API patterns
   - UI component library usage

3. **Dependencies:**
   - What systems might this feature interact with?
   - Are there constraints to be aware of?

Document your findings in the plan file for reference.

---

## A3: Ultrathink Analysis

**BEFORE asking any questions**, use `ultrathink` to deeply analyze:

### What to Analyze:

1. **Parse the Request:**
   - What is the user actually asking for?
   - What problem are they trying to solve?
   - What implicit assumptions are in their request?

2. **Identify Information Gaps:**
   - What critical information is missing?
   - What could be interpreted multiple ways?
   - What technical details are needed?

3. **Formulate Strategic Questions:**
   - What questions will give the most clarity?
   - What order should questions be asked?
   - What options should be provided for each question?

4. **Anticipate Edge Cases:**
   - What edge cases might exist?
   - What error scenarios need consideration?
   - What dependencies or integrations might be affected?

### Output:

A clear plan of:
- 3-5 initial questions to ask
- Priority order for questions
- Potential follow-up questions based on likely answers

---

## A4: Interview User with AskUserQuestion

**Use the questions formulated in Step A3** to interview the user.

### Interview Guidelines

1. **Initial questions** (3-5 questions):
   - Problem/Goal: What problem does this solve?
   - Core Functionality: What are the key actions?
   - Scope/Boundaries: What should it NOT do?
   - Target Users: Who will use this?
   - Success Criteria: How do we know it's done?

2. **Question Quality Principles:**
   - Each question should resolve a specific ambiguity
   - Options should cover the most likely scenarios
   - Use `multiSelect: true` when multiple options can apply
   - Add "(Recommended)" to the suggested option's label

### AskUserQuestion Guidelines

- Ask 1-4 questions per tool call
- Each question should have 2-4 options with short labels and descriptions
- An "Other" option is automatically included for custom input

---

## A5: Iterative Clarification Loop

**After receiving answers, use ultrathink again** to evaluate:

### Post-Answer Analysis

1. **Completeness Check:**
   - Do we now have enough information for unambiguous acceptance criteria?
   - Are there still multiple valid interpretations?
   - Can we define clear scope boundaries?

2. **Edge Case Discovery:**
   - Did the answers reveal new edge cases?
   - Are there error scenarios we haven't discussed?
   - What happens in failure modes?

3. **Gap Identification:**
   - What questions should we ask next?
   - What assumptions are we still making?

### Decision Criteria

**Ask MORE questions if:**
- User's answer was vague or incomplete
- You would have to guess about a requirement
- Multiple valid interpretations exist
- Edge cases aren't defined

**PROCEED to Step A6 if:**
- All user stories can have specific, verifiable acceptance criteria
- Scope boundaries are clear (what's in vs out)
- Technical constraints are known
- Edge cases have been discussed

---

## A6: Final Ultrathink Validation

**Before exiting plan mode, do a comprehensive final analysis:**

### Validation Checklist

1. **Requirements Validation:**
   - Are ALL requirements clear and unambiguous?
   - Can each requirement be verified objectively?
   - Are there any conflicting requirements?

2. **Story Sizing:**
   - Is each user story small enough to implement in one session?
   - Can each story be completed independently?
   - Are stories ordered by dependency (schema → backend → UI)?

3. **Acceptance Criteria:**
   - Is each criterion verifiable (not vague)?
   - Do UI stories include browser verification?
   - Does every story include typecheck requirement?

4. **Edge Cases & Risks:**
   - What could go wrong during implementation?
   - Are there security or performance implications?

### Final Check Questions

- "If I were implementing this, would I have any questions?"
- "Could a junior developer implement this without clarification?"
- "Will Ralph be able to implement each story in one iteration?"

**If any issues are found, return to Step A5 to clarify with the user.**

---

## A7: Write Requirements Summary to Plan File

Write a structured summary to the plan file containing:

```markdown
## PRD Planning Summary

### Target
- **Feature:** <feature-name-kebab-case>
- **File Path:** ./docs/prd/<feature>/prd.md

### Requirements Gathered
- [Key requirement 1]
- [Key requirement 2]
- [Key requirement 3]

### User Stories (Draft)
1. US-001: [Title] - [Brief description]
2. US-002: [Title] - [Brief description]
3. US-003: [Title] - [Brief description]

### Technical Considerations
- [Consideration 1]
- [Consideration 2]

### Out of Scope
- [Non-goal 1]
- [Non-goal 2]
```

---

## A8: Exit Plan Mode

Call the `ExitPlanMode` tool to signal that planning is complete.

```
Action: Call ExitPlanMode tool
```

This will present your plan summary to the user for approval.

**Wait for user approval before proceeding to Sub-Phase A2.**

---

## A9: Generate PRD Content

Generate the PRD with these sections:

### 9.1 Introduction/Overview
Brief description of the feature and the problem it solves. Keep it to 2-3 sentences.

### 9.2 Goals
Specific, measurable objectives (bullet list). Answer: "What does success look like?"

### 9.3 User Stories
Each story needs:
- **ID**: Sequential (US-001, US-002, etc.)
- **Title**: Short descriptive name
- **Description**: "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria**: Verifiable checklist

**Format:**
```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck passes
- [ ] **[UI stories only]** Verify in browser using MCP browser tools
```

**Requirements:**
- Each story must be small enough to implement in one focused session
- Acceptance criteria must be verifiable, not vague
- "Works correctly" is bad. "Button shows confirmation dialog before deleting" is good

### 9.4 Functional Requirements
Numbered list of specific functionalities:
- "FR-1: The system must allow users to..."
- "FR-2: When a user clicks X, the system must..."

### 9.5 Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope.

### 9.6 Design Considerations (Optional)
UI/UX requirements, mockups, existing components to reuse.

### 9.7 Technical Considerations (Optional)
Known constraints, dependencies, integration points, performance requirements.

### 9.8 Success Metrics
How will success be measured?

### 9.9 Open Questions
Remaining questions or areas needing clarification.

---

## A10: Save File

Execute these actions in order:

### 10.1 Create Directory

```bash
mkdir -p ./docs/prd/<feature>/
```

### 10.2 Save PRD File

```
Tool: Write
file_path: ./docs/prd/<feature>/prd.md
content: <the complete PRD markdown>
```

---

## A11: Confirm & Provide Next Step

After saving, you MUST:

1. **Confirm the save** with the actual file path
2. **Provide the copy-paste command** for the next step

### Output Format

```
PRD saved to: `./docs/prd/task-priority/prd.md`

**Next step** - Convert to JSON for Ralph:
/ralph-prd convert ./docs/prd/task-priority/prd.md
```

**IMPORTANT:** Use the ACTUAL path from your save, not placeholders.

---

# PHASE B: Convert to JSON

Converts existing PRDs (created with Phase A) to the `prd.json` format that Ralph uses for autonomous execution.

## Phase B Workflow

Follow these steps in order. Do NOT skip any step.

```
┌─────────────────────────────────────────────────────────────┐
│  1. Determine PRD Location                                   │
│     ↓                                                       │
│  2. Read PRD Content                                        │
│     ↓                                                       │
│  3. Initial Ultrathink Analysis                             │
│     (Analyze PRD quality, identify issues)                  │
│     ↓                                                       │
│  4. Clarify Ambiguities with AskUserQuestion                │
│     (Questions informed by ultrathink analysis)             │
│     ↓                                                       │
│  5. Iterative Clarification Loop                            │
│     (Ultrathink → Ask → Ultrathink → Ask until clear)       │
│     ↓                                                       │
│  6. Final Ultrathink Validation                             │
│     (Story sizing, dependencies, acceptance criteria)       │
│     ↓                                                       │
│  7. Generate prd.json Content                               │
│     ↓                                                       │
│  8. Present Summary & Confirm Save                          │
│     ↓                                                       │
│  9. Archive Previous Run (if exists)                        │
│     ↓                                                       │
│  10. Save File                                              │
│     ↓                                                       │
│  11. Confirm & Provide Next Step Command                    │
└─────────────────────────────────────────────────────────────┘
```

---

## B1: Determine PRD Location

**CRITICAL:** You MUST know where the PRD is located.

If the user's request doesn't specify the PRD path:

1. **If feature is unclear**, ask for clarification:
   ```json
   {
     "question": "Which feature's PRD should I convert?",
     "header": "Feature",
     "options": [
       {"label": "Browse existing", "description": "List PRDs in the docs/prd folder"}
     ]
   }
   ```

2. **If "Browse existing" selected**, use Glob to list PRDs:
   ```
   Glob: ./docs/prd/**/prd.md
   ```

**Never assume.** If unclear, ask.

The PRD should be at: `./docs/prd/<feature>/prd.md`
The JSON will be saved at: `./docs/prd/<feature>/prd.json` (same directory)

---

## B2: Read PRD Content

Read the PRD markdown file and note what it contains:

- Introduction/Overview section
- Goals section
- User Stories with IDs (US-001, US-002, etc.)
- Acceptance criteria for each story
- Functional requirements (FR-1, FR-2, etc.)
- Non-goals section

---

## B3: Initial Ultrathink Analysis

**BEFORE proceeding**, use `ultrathink` to deeply analyze the PRD:

### 3.1 PRD Quality Analysis

1. **Completeness Check:**
   - Does the PRD have all required sections?
   - Are any user stories incomplete?
   - Are acceptance criteria specified for each story?

2. **Ambiguity Detection:**
   - Are any requirements vague or unclear?
   - Could any story be interpreted multiple ways?
   - Are there missing technical details?

3. **Story Sizing Analysis:**
   - Is each story small enough for one Ralph iteration?
   - Are any stories too large and need splitting?
   - Are any stories too small and should be merged?

4. **Dependency Analysis:**
   - What is the correct execution order?
   - Do any stories depend on later stories? (wrong order)
   - Should order be: schema → backend → UI?

5. **Acceptance Criteria Quality:**
   - Is each criterion verifiable (not vague)?
   - Are "Typecheck passes" criteria missing?
   - Are "Verify in browser using MCP browser tools" missing for UI stories?

### 3.2 Identify Issues to Clarify

List specific issues that need clarification with the user:
- Vague acceptance criteria
- Stories that are too large
- Missing technical details
- Unclear dependencies
- Ambiguous requirements

---

## B4: Clarify Ambiguities with AskUserQuestion

**Use the issues identified in Step B3** to ask targeted questions.

### Question Examples

If you found vague criteria:
```json
{
  "question": "Story US-003 has vague criteria 'works correctly'. What specific behavior should be verified?",
  "header": "Clarify Criteria",
  "options": [
    {"label": "Shows success toast", "description": "Display confirmation message after save"},
    {"label": "Updates immediately", "description": "UI reflects change without page refresh"},
    {"label": "Both", "description": "Shows toast AND updates immediately"}
  ]
}
```

If you found a story that's too large:
```json
{
  "question": "Story US-002 'Build user dashboard' seems too large for one iteration. Should I split it?",
  "header": "Split Story",
  "options": [
    {"label": "Yes, split it (Recommended)", "description": "Create separate stories for schema, backend, UI"},
    {"label": "No, keep as-is", "description": "Attempt as single story"}
  ]
}
```

---

## B5: Iterative Clarification Loop

**After receiving answers, use ultrathink again** to evaluate:

### 5.1 Post-Answer Ultrathink Analysis

For each round of answers, analyze:

1. **Resolution Check:**
   - Did the answer resolve the ambiguity?
   - Is the requirement now clear and actionable?
   - Can we write verifiable acceptance criteria?

2. **New Issue Discovery:**
   - Did the answer reveal new issues?
   - Are there additional clarifications needed?
   - Are there cascading impacts on other stories?

3. **Story Impact:**
   - Does this affect story sizing?
   - Does this change the dependency order?
   - Do acceptance criteria need updating?

### 5.2 Continue or Proceed Decision

**Continue asking if:**
- Any requirement is still ambiguous
- Any story is still too large
- Any acceptance criterion is still vague
- Dependencies are still unclear

**Proceed to Step B6 if:**
- All stories are right-sized (completable in one iteration)
- All acceptance criteria are verifiable
- Dependency order is clear
- No ambiguities remain

---

## B6: Final Ultrathink Validation

**Before generating prd.json, do a comprehensive final analysis:**

### 6.1 Story Sizing Validation

For EACH story, verify:
- Can it be completed in ONE Ralph iteration (one context window)?
- Can you describe the change in 2-3 sentences?
- Is it focused on a single concern?

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (must split):**
- "Build the entire dashboard" → schema, queries, UI components, filters
- "Add authentication" → schema, middleware, login UI, session handling
- "Refactor the API" → one story per endpoint or pattern

### 6.2 Dependency Order Validation

Verify the order is:
1. Schema/database changes (migrations) - Priority 1, 2, ...
2. Server actions / backend logic - Priority 3, 4, ...
3. UI components that use the backend - Priority 5, 6, ...
4. Dashboard/summary views that aggregate data - Priority 7, 8, ...

**Check:** No story should depend on a later story.

### 6.3 Acceptance Criteria Validation

For EACH story, verify:
- [ ] All criteria are verifiable (not vague)
- [ ] "Typecheck passes" is included
- [ ] UI stories include "Verify in browser using MCP browser tools"

**Good criteria:** "Button shows confirmation dialog before deleting"
**Bad criteria:** "Works correctly", "Good UX", "Handles edge cases"

---

## B7: Generate prd.json Content

Generate the JSON following the schema in [prd-json-example.md](./references/prd-json-example.md).

### Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "dependencies": [],
      "passes": false,
      "commit": "",
      "preCommit": [],
      "notes": ""
    }
  ]
}
```

### Conversion Rules

1. **Each user story becomes one JSON entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All stories**: `passes: false`, empty `notes`, empty `commit`, empty `preCommit: []`
5. **dependencies**: Array of story IDs this story depends on (empty `[]` if no dependencies)
6. **branchName**: Derive from feature name, kebab-case, prefixed with `ralph/`
7. **Always add**: "Typecheck passes" to every story's acceptance criteria
8. **UI stories**: Add "Verify in browser using MCP browser tools"

---

## B8: Present Summary & Confirm Save

**Before saving, you MUST show a summary and get confirmation.**

### 8.1 Show Brief Summary

```
**prd.json Summary**

- **Feature:** task-priority
- **File:** ./docs/prd/task-priority/prd.json
- **Branch:** ralph/task-priority
- **Stories:** 4 user stories

**User Stories (in execution order):**
1. US-001: Add priority field to database (priority: 1)
2. US-002: Display priority indicator on task cards (priority: 2)
3. US-003: Add priority selector to task edit (priority: 3)
4. US-004: Filter tasks by priority (priority: 4)

**Validation:**
- All stories are right-sized for one iteration
- Dependencies ordered correctly (schema → backend → UI)
- All acceptance criteria are verifiable
```

### 8.2 Ask for Confirmation

Ask: **"Ready to save the prd.json. Should I proceed, or would you like any changes?"**

---

## B9: Archive Previous Run (if exists)

Before writing a new prd.json, check if there is an existing one from a different feature:

1. **Check if `prd.json` exists** in the target directory
2. **Check if `branchName` differs** from the new feature's branch name
3. **If different AND `progress.md` has content beyond the header:**
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.md` to archive
   - Reset `progress.md` with fresh header

---

## B10: Save File

```
Tool: Write
file_path: ./docs/prd/<feature>/prd.json
content: <the complete JSON content>
```

---

## B11: Confirm & Provide Next Step

After saving, you MUST:

1. **Confirm the save** with the actual file path
2. **Provide the copy-paste command** for the next step

### Output Format

```
prd.json saved to: `./docs/prd/task-priority/prd.json`

**Next step** - Run Ralph autonomous agent:
./skills/ralph-prd/scripts/ralph.sh --prd ./docs/prd/task-priority --root .
```

**IMPORTANT:** Use the ACTUAL path from your save, not placeholders.

---

# Common Reference

## File Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Feature folder | `kebab-case` | `task-priority`, `user-notifications` |
| PRD file | Always `prd.md` | `prd.md` |
| JSON file | Always `prd.json` (same directory) | `prd.json` |
| Progress log | Always `progress.md` | `progress.md` |
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

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration (one context window).**

Ralph spawns a fresh LLM instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" → Split into: schema, queries, UI components, filters
- "Add authentication" → Split into: schema, middleware, login UI, session handling
- "Refactor the API" → Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Running Ralph

After creating `prd.json`, run the Ralph agent loop:

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

---

## Skill Completion Criteria

This skill is **ONLY complete** when ALL of the following are true:

### For Phase A (Create PRD):
1. EnterPlanMode was called at the start
2. Codebase was explored for context
3. Ultrathink was used to formulate questions
4. User was interviewed until all requirements are clear
5. Final ultrathink validation was performed
6. ExitPlanMode was called and user approved
7. PRD content was generated with all required sections
8. File saved at `./docs/prd/<feature>/prd.md`
9. User was given the copy-paste command for next step

### For Phase B (Convert to JSON):
1. PRD location has been determined (asked if not specified)
2. PRD markdown has been read
3. Ultrathink has been used to analyze PRD and identify issues
4. Any issues have been clarified with the user using AskUserQuestion
5. Ultrathink has been used for final validation
6. Each story is completable in one iteration (small enough)
7. Stories are ordered by dependency (schema → backend → UI)
8. Every story has "Typecheck passes" as criterion
9. UI stories have "Verify in browser using MCP browser tools" as criterion
10. Summary has been shown and user confirmed save
11. prd.json file saved at `./docs/prd/<feature>/prd.json`
12. User has been shown the file path AND the copy-paste command for running Ralph

**If any of these are missing, the skill has FAILED.**
