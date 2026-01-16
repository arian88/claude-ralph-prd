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
- **Browser validation**: Playwright MCP validation for UI stories catches runtime bugs
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
- **Tiered quality review**: Every story runs mandatory passes (code-simplifier, code-review) plus story-type-specific passes
- **Browser validation**: Frontend stories require Playwright MCP validation before commit
- **Available skills**: See Skill Applicability Matrix below for full list
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
6. **⛔ MANDATORY: Run Quality Review Phase (tiered)**
   - Tier 1: code-simplifier, code-review (ALL stories)
   - Tier 2: vercel-react-best-practices, web-design-guidelines (frontend)
7. **⛔ MANDATORY FOR FRONTEND: Run Browser Validation (Playwright MCP)**
   - Start dev server, navigate to relevant page
   - Take screenshot for visual assessment (UI/UX stories)
   - Perform minimal functional checks if needed
   - Check console for errors
   - **DO NOT SKIP THIS STEP FOR FRONTEND STORIES**
8. Update prd.json: `passes: true`, `preCommit: [all mandatory passes for story type]`
9. Append detailed log to progress.md
10. **Single Commit (feat):** Stage implementation + prd.json + progress.md together
11. **Push to remote** (backup immediately, first push creates remote branch)
12. **Print confirmation block** (after all steps complete)

**Result: 1 commit per story (feat with everything)**

**⛔ NEVER set passes: true if mandatory passes for story type are missing.**
**⛔ NEVER commit frontend stories without browser validation.**
**⛔ NEVER skip browser validation for UI/UX changes. Launch the browser. See the output.**

---

## Quality Review Phase (MANDATORY - TIERED SYSTEM)

**Execute passes based on story type analysis.**

```
┌────────────────────────────────────────────────────────────────────────┐
│              QUALITY REVIEW PHASE (TIERED SYSTEM)                      │
│                                                                        │
│  TIER 1 - MANDATORY (All Stories)                                      │
│  ├─ Pass 1: code-simplifier                                            │
│  └─ Pass 2: code-review                                                │
│                                                                        │
│  TIER 2 - CONDITIONAL MANDATORY (Based on Story Type)                  │
│  ├─ Pass 3: vercel-react-best-practices (React/Next.js only)           │
│  └─ Pass 4: web-design-guidelines (all frontend)                       │
│                                                                        │
│  TIER 3 - RECOMMENDED (Agent-Decided)                                  │
│  └─ Pass 5: rams (visual polish - can skip with documented reason)     │
│                                                                        │
│  IMPLEMENTATION SKILL (During Step 4)                                  │
│  └─ frontend-design (for new UI components)                            │
│                                                                        │
│  VALIDATION GATE → Ready to Commit                                     │
└────────────────────────────────────────────────────────────────────────┘
```

### Skill Applicability Matrix

| Skill | Backend | Config | Frontend (React) | Frontend (Other) |
|-------|---------|--------|------------------|------------------|
| code-simplifier | MANDATORY | MANDATORY | MANDATORY | MANDATORY |
| code-review | MANDATORY | MANDATORY | MANDATORY | MANDATORY |
| vercel-react-best-practices | UNUSED | UNUSED | **MANDATORY** | UNUSED |
| web-design-guidelines | UNUSED | UNUSED | **MANDATORY** | **MANDATORY** |
| frontend-design | UNUSED | UNUSED | Agent-Decided | Agent-Decided |
| rams | UNUSED | UNUSED | Agent-Decided | Agent-Decided |
| Playwright MCP | UNUSED | UNUSED | **MANDATORY** | **MANDATORY** |

> **Note:** Browser validation is required for ALL frontend stories. Use your judgment to determine what needs validation.

### Skill Invocations

**Tier 1 (Mandatory):**
- `code-simplifier:code-simplifier` via Task tool
- `general-purpose` via Task tool (for code-review)

**Tier 2 (Conditional):**
- `/vercel-react-best-practices` - React/Next.js optimization
- `/web-design-guidelines` - Accessibility and UX review

**Tier 3 (Recommended):**
- `/rams` - Visual polish and accessibility fixes

**Implementation:**
- `/frontend-design` or `frontend-design:frontend-design` via Task tool

**Validation:**
- Playwright MCP tools (ONLY METHOD) - See Browser Validation Protocol below

### Validation Gate

Before committing, verify ALL mandatory passes for story type:

**For ALL stories:**
- ✓ code-simplifier executed
- ✓ code-review executed

**For frontend-react, ALSO:**
- ✓ vercel-react-best-practices executed
- ✓ web-design-guidelines executed
- ✓ **Browser validation executed (Playwright MCP)**

**For frontend-other, ALSO:**
- ✓ web-design-guidelines executed
- ✓ **Browser validation executed (Playwright MCP)**

**preCommit must contain all executed passes.**

---

## Browser Validation Protocol (Playwright MCP)

**⛔ DO NOT SKIP BROWSER VALIDATION FOR FRONTEND STORIES.**

If you implemented UI changes, you MUST launch a browser and verify the output. This validates that your code actually works in a real browser environment.

---

### When Browser Validation is Required

**USE YOUR JUDGMENT. Validate with browser if the story involves:**

| Category | Examples |
|----------|----------|
| UI Components | Buttons, forms, modals, cards, navigation |
| Visual Changes | Styling, layout, themes, colors, spacing, typography |
| UI/UX Improvements | Making the app look better, more attractive, polished |
| User Interactions | Clicks, inputs, form submissions, navigation flows |
| Frontend State | Client-side state changes, dynamic content |
| Accessibility | Screen reader support, keyboard navigation, ARIA |
| Responsive Design | Mobile layouts, breakpoints, fluid sizing |

**Skip browser validation ONLY for:**
- Pure backend changes (API, database, server logic)
- Configuration files with no UI impact
- Documentation changes
- Build/tooling changes with no visual output

**Simple rule: If a user would see or interact with it, validate it in the browser.**

---

### Designing Appropriate Validation Tests

**⚠️ CRITICAL: Design tests that are appropriate for what you are validating.**

Playwright MCP is slow. Do not perform unnecessary actions. Design each validation to be:
- **Targeted**: Test exactly what the story changed
- **Minimal**: Fewest actions needed to verify acceptance criteria
- **Meaningful**: Each action should verify something specific

**Two types of validation, often used together:**

#### 1. Visual Validation (for appearance/design stories)

When the story involves how something LOOKS:

| What to Validate | How to Validate |
|------------------|-----------------|
| Colors are correct | Take screenshot, visually inspect |
| Spacing is proper | Take screenshot, check alignment |
| Typography is right | Take screenshot, verify font rendering |
| Layout is correct | Take screenshot, assess structure |
| Design is polished | Take screenshot, evaluate overall quality |
| Responsive behavior | Resize viewport, take screenshot at each size |

**Key question:** Does this look professional and match the acceptance criteria?

#### 2. Functional Validation (for behavior/interaction stories)

When the story involves how something WORKS:

| What to Validate | How to Validate |
|------------------|-----------------|
| Button triggers action | Click button, verify result |
| Form submits correctly | Fill form, submit, check success state |
| Navigation works | Click link, verify destination |
| State changes correctly | Perform action, verify state update |
| Error handling works | Trigger error condition, verify message |

**Key question:** Does the interaction produce the expected result?

#### 3. Combined Validation (most frontend stories)

Most stories require BOTH visual and functional validation:
- A new button must look correct AND work when clicked
- A form must be styled properly AND submit successfully
- A modal must appear correctly AND close when dismissed

---

### Playwright MCP Tools Reference

Use these `mcp__playwright__*` tools:

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Navigate to a URL |
| `browser_take_screenshot` | Capture visual state (ESSENTIAL for visual validation) |
| `browser_snapshot` | Get accessibility tree with element refs |
| `browser_click` | Click an element (requires ref from snapshot) |
| `browser_type` | Type text into an input |
| `browser_fill_form` | Fill multiple form fields |
| `browser_console_messages` | Check for JavaScript errors |
| `browser_close` | **MUST call to cleanup** |

---

### Execution Protocol

Follow these steps exactly:

#### Step 1: Start Development Server

```bash
npm run dev &
sleep 5  # Wait for server to be ready
```

#### Step 2: Navigate to the Relevant Page

```
mcp__playwright__browser_navigate
  url: "http://localhost:3000/path-to-feature"
```

Navigate directly to where your changes are visible. Do not navigate through the entire app.

#### Step 3: Visual Validation

Take a screenshot to SEE the rendered output:

```
mcp__playwright__browser_take_screenshot
```

Examine the screenshot and assess:
- Does the UI match the acceptance criteria?
- Are visual changes correctly applied?
- Does it look professional and polished?
- Is the layout correct? Spacing appropriate?
- Are colors and typography as expected?

**Document your visual assessment in your output.**

#### Step 4: Functional Validation (if applicable)

Only if the story involves interactions:

```
mcp__playwright__browser_snapshot    # Get element refs first
mcp__playwright__browser_click       # Perform interaction
  element: "Submit button"
  ref: "ref_from_snapshot"
```

Keep actions minimal. One or two key interactions maximum.

#### Step 5: Check Console for Errors

```
mcp__playwright__browser_console_messages
  level: "error"
```

**Any console errors = validation FAILED.** Fix the errors before proceeding.

#### Step 6: Cleanup (CRITICAL)

**⛔ YOU MUST ALWAYS CLOSE THE BROWSER. THIS IS NOT OPTIONAL.**

```
mcp__playwright__browser_close
```

Then stop the dev server:

```bash
pkill -f "next dev" || pkill -f "npm run dev" || pkill -f "vite" || true
```

**Why cleanup is critical:**
- Playwright browser instances consume significant memory
- Unclosed browsers accumulate across iterations
- Dev servers left running cause port conflicts
- Memory leaks degrade system performance over time

**If you forget to cleanup, you are causing system instability.**

---

### Validation Test Examples

**Example 1: UI Styling Story**
```
Story: "Improve button styling on settings page"

Validation:
1. Navigate to /settings
2. Take screenshot
3. Assess: Button has correct colors, padding, hover state looks professional
4. Check console: 0 errors
5. Close browser, stop server
```

**Example 2: Form Functionality Story**
```
Story: "Add email validation to contact form"

Validation:
1. Navigate to /contact
2. Take snapshot, find email input ref
3. Type invalid email, submit form
4. Verify error message appears
5. Check console: 0 errors
6. Close browser, stop server
```

**Example 3: Combined Visual + Functional Story**
```
Story: "Add dark mode toggle"

Validation:
1. Navigate to /settings
2. Take screenshot (light mode baseline)
3. Take snapshot, find toggle ref
4. Click toggle
5. Take screenshot (verify dark mode applied correctly)
6. Assess: Colors inverted, contrast good, readable
7. Check console: 0 errors
8. Close browser, stop server
```

---

### Validation Outcomes

| Outcome | Action |
|---------|--------|
| Visual looks good AND no console errors | Set `passes: true`, proceed to commit |
| Console errors found | Set `passes: false`, fix errors, re-validate |
| Visual does not meet acceptance criteria | Set `passes: false`, fix issues, re-validate |
| Browser or server fails to start | Set `passes: false`, log the issue |

---

### Critical Rules

1. **NEVER skip browser validation for frontend stories.** This is the most common failure mode. If you changed UI, you MUST see it rendered in a real browser.

2. **NEVER set `passes: true` without browser validation.** Looking at code is not validation. You must see the actual rendered output.

3. **ALWAYS take screenshots for visual stories.** You cannot assess visual quality without seeing the UI.

4. **ALWAYS check console for errors.** JavaScript errors indicate broken functionality.

5. **⛔ ALWAYS close the browser after validation.** This prevents memory leaks. Call `browser_close` every single time.

6. **ALWAYS stop the dev server after validation.** This prevents port conflicts.

7. **Design appropriate tests.** Each validation should be targeted, minimal, and meaningful.

---

### Anti-Patterns (DO NOT DO THIS)

```
❌ BAD: "I implemented the styling changes. Moving to commit."
   WHY: No browser launched, no visual verification

❌ BAD: "The code looks correct. Setting passes: true."
   WHY: Code review is not browser validation

❌ BAD: "Browser validation skipped due to time constraints."
   WHY: Validation is mandatory, not optional

❌ BAD: "Launched browser and clicked around. Looks fine."
   WHY: No screenshot, no specific assessment, no console check

❌ BAD: [Forgot to call browser_close]
   WHY: Memory leak, system degradation
```

---

### Proper Validation Output

```
▶ BROWSER VALIDATION
  Story: US-003 - Add dark mode toggle
  Type: Visual + Functional

  [1] Starting dev server... ✓ localhost:3000
  [2] Navigating to /settings... ✓
  [3] Taking screenshot (light mode)... ✓
  [4] Visual assessment:
      - Settings page renders correctly
      - Toggle component is visible and properly styled
      - Layout is clean, spacing is appropriate
  [5] Taking snapshot for interaction... ✓
  [6] Clicking dark mode toggle... ✓
  [7] Taking screenshot (dark mode)... ✓
  [8] Visual assessment:
      - Background changed to dark color
      - Text is readable with proper contrast
      - Toggle reflects active state
      - No visual glitches or broken layouts
  [9] Console errors: 0 ✓
  [10] Closing browser... ✓
  [11] Stopping dev server... ✓

  ✓ VALIDATION PASSED
    - Visual: Meets acceptance criteria
    - Functional: Toggle works correctly
    - Console: No errors
```

---

## Commit Requirements

- Stage only files modified for THIS story (no `git add -A`)
- Use detailed commit format with: PRD context, acceptance criteria, files changed, decisions, validation
- Print confirmation block after successful commit
- Only set `passes: true` if:
  - BOTH quality review passes were run
  - Browser validation was performed (for frontend stories)
  - Commit was successful
  - All acceptance criteria verified

### Console Output (for monitoring)

Print status at each phase:

1. **▶ STARTING** block when selecting story
   - Story ID and title
   - Dependencies status
   - Acceptance criteria

2. **QUALITY CHECKS** results
   - Typecheck: pass/fail
   - Lint: pass/fail
   - Tests: pass/fail

3. **QUALITY REVIEW** results
   - Pass 1 (code-simplifier): refinements applied
   - Pass 2 (code-review): issues found/fixed by severity

4. **▶ BROWSER VALIDATION** results (for frontend stories)
   - Server started: yes/no
   - Screenshots taken: count
   - Visual assessment: specific observations about appearance
   - Functional checks: actions performed and results
   - Console errors: count (must be 0)
   - Cleanup completed: browser closed, server stopped
   - Conclusion: PASSED/FAILED

5. **✓ STORY COMPLETE** block
   - Commit hash
   - Files changed (+new, ~modified, -deleted)
   - Quality review summary
   - Browser validation summary
   - Push status
   - Progress: X/Y stories complete (percentage)
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
