#!/bin/bash
# Ralph - Autonomous AI agent loop for PRD execution
# Runs Claude in a safe, non-interactive mode on a dedicated branch
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/../references/prompt.md"

# Default values
TOOL="claude"
MAX_ITERATIONS=10
PRD_DIR=""
PROJECT_ROOT=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  Ralph - Autonomous PRD Agent${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_config() {
  echo ""
  echo -e "${GREEN}Configuration:${NC}"
  echo -e "  PRD Directory:  ${YELLOW}$PRD_DIR${NC}"
  echo -e "  Project Root:   ${YELLOW}$PROJECT_ROOT${NC}"
  echo -e "  PRD File:       ${YELLOW}$PRD_FILE${NC}"
  echo -e "  Progress File:  ${YELLOW}$PROGRESS_FILE${NC}"
  echo -e "  Branch:         ${YELLOW}$BRANCH_NAME${NC}"
  echo -e "  Tool:           ${YELLOW}$TOOL${NC}"
  echo -e "  Max Iterations: ${YELLOW}$MAX_ITERATIONS${NC}"
  echo ""
}

show_help() {
  echo "Usage: ralph.sh --prd <dir> --root <dir> [options]"
  echo ""
  echo "Required:"
  echo "  --prd <dir>       PRD directory containing prd.json"
  echo "  --root <dir>      Project root directory (where code lives)"
  echo ""
  echo "Options:"
  echo "  --tool <name>     AI tool: claude or amp (default: claude)"
  echo "  --max <n>         Maximum iterations (default: 10)"
  echo "  -h, --help        Show this help"
  echo ""
  echo "Examples:"
  echo "  ralph.sh --prd ./docs/prd/feature --root ."
  echo "  ralph.sh --prd ./docs/prd/feature --root . --max 15"
  echo "  ralph.sh --prd ./docs/prd/feature --root . --tool amp"
  echo "  ralph.sh --prd ./docs/prd/feature --root /path/to/project --max 20 --tool claude"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --prd) PRD_DIR="$2"; shift 2 ;;
    --prd=*) PRD_DIR="${1#*=}"; shift ;;
    --root) PROJECT_ROOT="$2"; shift 2 ;;
    --root=*) PROJECT_ROOT="${1#*=}"; shift ;;
    --tool) TOOL="$2"; shift 2 ;;
    --tool=*) TOOL="${1#*=}"; shift ;;
    --max) MAX_ITERATIONS="$2"; shift 2 ;;
    --max=*) MAX_ITERATIONS="${1#*=}"; shift ;;
    -h|--help) show_help; exit 0 ;;
    -*) echo -e "${RED}Error: Unknown option: $1${NC}" >&2; show_help; exit 1 ;;
    *) echo -e "${RED}Error: Unexpected argument: $1${NC}" >&2; show_help; exit 1 ;;
  esac
done

# Validate required arguments
if [[ -z "$PRD_DIR" ]]; then
  echo -e "${RED}Error: --prd is required${NC}"
  echo ""
  show_help
  exit 1
fi

if [[ -z "$PROJECT_ROOT" ]]; then
  echo -e "${RED}Error: --root is required${NC}"
  echo ""
  show_help
  exit 1
fi

# Resolve to absolute paths
PRD_DIR="$(cd "$PRD_DIR" 2>/dev/null && pwd)" || { echo -e "${RED}Error: PRD directory not found: $PRD_DIR${NC}"; exit 1; }
PROJECT_ROOT="$(cd "$PROJECT_ROOT" 2>/dev/null && pwd)" || { echo -e "${RED}Error: Project root not found: $PROJECT_ROOT${NC}"; exit 1; }

# Validate tool
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo -e "${RED}Error: --tool must be 'amp' or 'claude'${NC}"
  exit 1
fi

# Define file paths
PRD_FILE="$PRD_DIR/prd.json"
PROGRESS_FILE="$PRD_DIR/progress.md"
ARCHIVE_DIR="$PRD_DIR/archive"
LAST_BRANCH_FILE="$PRD_DIR/.last-branch"

# Validate PRD file exists
if [[ ! -f "$PRD_FILE" ]]; then
  echo -e "${RED}Error: prd.json not found at $PRD_FILE${NC}"
  exit 1
fi

# Get branch name from PRD
BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
if [[ -z "$BRANCH_NAME" ]]; then
  # Generate branch name from PRD directory name
  FEATURE_NAME=$(basename "$PRD_DIR")
  BRANCH_NAME="ralph/$FEATURE_NAME"
fi

# Print header and config
print_header

# Archive previous run if branch changed
if [[ -f "$LAST_BRANCH_FILE" ]]; then
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  if [[ -n "$LAST_BRANCH" && "$BRANCH_NAME" != "$LAST_BRANCH" ]]; then
    echo -e "${YELLOW}Branch changed from $LAST_BRANCH to $BRANCH_NAME${NC}"
    echo -e "${YELLOW}Archiving previous progress...${NC}"
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$(date +%Y-%m-%d)-$FOLDER_NAME"
    mkdir -p "$ARCHIVE_FOLDER"
    [[ -f "$PRD_FILE" ]] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [[ -f "$PROGRESS_FILE" ]] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
  fi
fi

# Track current branch
echo "$BRANCH_NAME" > "$LAST_BRANCH_FILE"

# Initialize or update progress file
if [[ ! -f "$PROGRESS_FILE" ]] || [[ ! -s "$PROGRESS_FILE" ]]; then
  echo -e "${YELLOW}Initializing progress.md...${NC}"
  cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log

**PRD:** $(basename "$PRD_DIR")
**Branch:** $BRANCH_NAME
**Started:** $(date)

## Codebase Patterns

(Patterns discovered during implementation will be added here)

---

## Iteration Log

EOF
fi

# Print configuration
print_config

# Ensure we're on the correct branch
cd "$PROJECT_ROOT"
CURRENT_GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [[ "$CURRENT_GIT_BRANCH" != "$BRANCH_NAME" ]]; then
  echo -e "${YELLOW}Switching to branch: $BRANCH_NAME${NC}"

  # Check if branch exists
  if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    git checkout "$BRANCH_NAME"
  else
    echo -e "${YELLOW}Creating new branch: $BRANCH_NAME${NC}"
    git checkout -b "$BRANCH_NAME"
  fi
  echo ""
fi

echo -e "${GREEN}Starting autonomous execution...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Main loop
for i in $(seq 1 $MAX_ITERATIONS); do
  echo -e "${BLUE}=== Iteration $i/$MAX_ITERATIONS ===${NC}"
  echo ""

  # Ensure we're in project root
  cd "$PROJECT_ROOT"

  # Build prompt with paths injected
  FULL_PROMPT="PRD_DIR=$PRD_DIR
PRD_FILE=$PRD_FILE
PROGRESS_FILE=$PROGRESS_FILE
BRANCH_NAME=$BRANCH_NAME

$(cat "$PROMPT_FILE")"

  # Execute AI tool
  # --dangerously-skip-permissions: auto-accept all tool calls
  # --print: non-interactive mode, output to stdout
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(echo "$FULL_PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(echo "$FULL_PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ Complete at iteration $i${NC}"
    echo -e "${GREEN}  Branch: $BRANCH_NAME${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
  fi

  echo ""
  sleep 2
done

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Reached max iterations ($MAX_ITERATIONS)${NC}"
echo -e "${YELLOW}  Branch: $BRANCH_NAME${NC}"
echo -e "${YELLOW}  Check progress.md for status${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
exit 1
