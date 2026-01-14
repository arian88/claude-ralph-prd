#!/bin/bash
# Ralph - Autonomous AI agent loop for PRD execution
# Runs Claude in a safe, non-interactive mode on a dedicated branch
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROMPT_FILE="$SCRIPT_DIR/../references/prompt.md"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
readonly BANNER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOOL="claude"
MAX_ITERATIONS=10
PRD_DIR=""
PROJECT_ROOT=""

error() { echo -e "${RED}Error: $1${NC}" >&2; }
info() { echo -e "${YELLOW}$1${NC}"; }

print_banner() {
  local color="${1:-$BLUE}"
  shift
  echo -e "${color}${BANNER}${NC}"
  for line in "$@"; do
    echo -e "${color}  $line${NC}"
  done
  echo -e "${color}${BANNER}${NC}"
}

print_config() {
  echo
  echo -e "${GREEN}Configuration:${NC}"
  echo -e "  PRD Directory:  ${YELLOW}${PRD_DIR}${NC}"
  echo -e "  Project Root:   ${YELLOW}${PROJECT_ROOT}${NC}"
  echo -e "  PRD File:       ${YELLOW}${PRD_FILE}${NC}"
  echo -e "  Progress File:  ${YELLOW}${PROGRESS_FILE}${NC}"
  echo -e "  Branch:         ${YELLOW}${BRANCH_NAME}${NC}"
  echo -e "  Tool:           ${YELLOW}${TOOL}${NC}"
  echo -e "  Max Iterations: ${YELLOW}${MAX_ITERATIONS}${NC}"
  echo
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
    -*) error "Unknown option: $1"; show_help; exit 1 ;;
    *) error "Unexpected argument: $1"; show_help; exit 1 ;;
  esac
done

require_arg() {
  if [[ -z "$2" ]]; then
    error "$1 is required"
    echo
    show_help
    exit 1
  fi
}

resolve_path() {
  cd "$1" 2>/dev/null && pwd || { error "$2 not found: $1"; exit 1; }
}

validate_inputs() {
  require_arg "--prd" "$PRD_DIR"
  require_arg "--root" "$PROJECT_ROOT"

  PRD_DIR="$(resolve_path "$PRD_DIR" "PRD directory")"
  PROJECT_ROOT="$(resolve_path "$PROJECT_ROOT" "Project root")"

  if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
    error "--tool must be 'amp' or 'claude'"
    exit 1
  fi
}

validate_inputs

PRD_FILE="$PRD_DIR/prd.json"
PROGRESS_FILE="$PRD_DIR/progress.md"
ARCHIVE_DIR="$PRD_DIR/archive"
LAST_BRANCH_FILE="$PRD_DIR/.last-branch"

if [[ ! -f "$PRD_FILE" ]]; then
  error "prd.json not found at $PRD_FILE"
  exit 1
fi

BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || true)
BRANCH_NAME="${BRANCH_NAME:-ralph/$(basename "$PRD_DIR")}"

print_banner "$BLUE" "Ralph - Autonomous PRD Agent"

archive_previous_run() {
  [[ ! -f "$LAST_BRANCH_FILE" ]] && return

  local last_branch
  last_branch=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || true)
  [[ -z "$last_branch" || "$BRANCH_NAME" == "$last_branch" ]] && return

  info "Branch changed from $last_branch to $BRANCH_NAME"
  info "Archiving previous progress..."

  local folder_name="${last_branch#ralph/}"
  local archive_folder="$ARCHIVE_DIR/$(date +%Y-%m-%d)-$folder_name"
  mkdir -p "$archive_folder"
  [[ -f "$PRD_FILE" ]] && cp "$PRD_FILE" "$archive_folder/"
  [[ -f "$PROGRESS_FILE" ]] && cp "$PROGRESS_FILE" "$archive_folder/"
}

archive_previous_run
echo "$BRANCH_NAME" > "$LAST_BRANCH_FILE"

if [[ ! -f "$PROGRESS_FILE" || ! -s "$PROGRESS_FILE" ]]; then
  info "Initializing progress.md..."
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

print_config

ensure_branch() {
  cd "$PROJECT_ROOT"
  local current_branch
  current_branch=$(git branch --show-current 2>/dev/null || true)
  [[ "$current_branch" == "$BRANCH_NAME" ]] && return

  info "Switching to branch: $BRANCH_NAME"
  if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    git checkout "$BRANCH_NAME"
  else
    info "Creating new branch: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"
  fi
  echo
}

build_prompt() {
  cat <<EOF
PRD_DIR=$PRD_DIR
PRD_FILE=$PRD_FILE
PROGRESS_FILE=$PROGRESS_FILE
BRANCH_NAME=$BRANCH_NAME

$(cat "$PROMPT_FILE")
EOF
}

run_iteration() {
  local iteration=$1
  echo -e "${BLUE}=== Iteration $iteration/$MAX_ITERATIONS ===${NC}"
  echo

  cd "$PROJECT_ROOT"

  local output cmd
  if [[ "$TOOL" == "amp" ]]; then
    cmd="amp --dangerously-allow-all"
  else
    cmd="claude --dangerously-skip-permissions --print"
  fi
  output=$(build_prompt | $cmd 2>&1 | tee /dev/stderr) || true

  if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
    echo
    print_banner "$GREEN" "Complete at iteration $iteration" "Branch: $BRANCH_NAME"
    exit 0
  fi

  echo
  sleep 2
}

ensure_branch

echo -e "${GREEN}Starting autonomous execution...${NC}"
echo -e "${BLUE}${BANNER}${NC}"
echo

for i in $(seq 1 "$MAX_ITERATIONS"); do
  run_iteration "$i"
done

echo
print_banner "$YELLOW" \
  "Reached max iterations ($MAX_ITERATIONS)" \
  "Branch: $BRANCH_NAME" \
  "Check progress.md for status"
exit 1
