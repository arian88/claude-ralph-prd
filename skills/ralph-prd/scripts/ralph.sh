#!/bin/bash
# Ralph - Autonomous AI agent loop for PRD execution
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/../references/prompt.md"

TOOL="claude"
MAX_ITERATIONS=10
PRD_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool) TOOL="$2"; shift 2 ;;
    --tool=*) TOOL="${1#*=}"; shift ;;
    --max-iterations) MAX_ITERATIONS="$2"; shift 2 ;;
    --max-iterations=*) MAX_ITERATIONS="${1#*=}"; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) [[ -z "$PRD_DIR" ]] && PRD_DIR="$1"; shift ;;
  esac
done

[[ -z "$PRD_DIR" ]] && { echo "Error: PRD directory required" >&2; exit 1; }
PRD_DIR="$(cd "$PRD_DIR" 2>/dev/null && pwd)" || { echo "Error: Directory not found" >&2; exit 1; }
[[ "$TOOL" != "amp" && "$TOOL" != "claude" ]] && { echo "Error: Tool must be 'amp' or 'claude'" >&2; exit 1; }

PRD_FILE="$PRD_DIR/prd.json"
PROGRESS_FILE="$PRD_DIR/progress.md"
ARCHIVE_DIR="$PRD_DIR/archive"
LAST_BRANCH_FILE="$PRD_DIR/.last-branch"

[[ ! -f "$PRD_FILE" ]] && { echo "Error: prd.json not found at $PRD_FILE" >&2; exit 1; }

# Archive previous run if branch changed
if [[ -f "$LAST_BRANCH_FILE" ]]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  if [[ -n "$CURRENT_BRANCH" && -n "$LAST_BRANCH" && "$CURRENT_BRANCH" != "$LAST_BRANCH" ]]; then
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$(date +%Y-%m-%d)-$FOLDER_NAME"
    mkdir -p "$ARCHIVE_FOLDER"
    [[ -f "$PRD_FILE" ]] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [[ -f "$PROGRESS_FILE" ]] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
[[ -n "$CURRENT_BRANCH" ]] && echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"

# Initialize progress file
if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Ralph: $PRD_DIR ($TOOL, max $MAX_ITERATIONS iterations)"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "=== Iteration $i/$MAX_ITERATIONS ==="
  cd "$PRD_DIR"

  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$PROMPT_FILE" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 | tee /dev/stderr) || true
  fi

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Complete at iteration $i"
    exit 0
  fi

  sleep 2
done

echo ""
echo "Reached max iterations ($MAX_ITERATIONS)"
exit 1
