#!/bin/bash
# Ralph - Autonomous AI agent loop for PRD execution
# Runs Claude in a safe, non-interactive mode on a dedicated branch
set -e

# ==============================================================================
# Constants
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROMPT_FILE="$SCRIPT_DIR/../references/prompt.md"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
readonly BANNER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ==============================================================================
# Default Configuration
# ==============================================================================

TOOL="claude"
MAX_ITERATIONS=10
PRD_DIR=""
PROJECT_ROOT=""

# ==============================================================================
# Output Functions
# ==============================================================================

error() {
  echo -e "${RED}Error: $1${NC}" >&2
}

info() {
  echo -e "${YELLOW}$1${NC}"
}

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

# ==============================================================================
# Story Progress Functions
# ==============================================================================

get_story_counts() {
  local total completed remaining
  total=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo "0")
  completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
  remaining=$((total - completed))
  echo "$completed $total $remaining"
}

print_progress() {
  local counts completed total remaining
  counts=$(get_story_counts)
  read -r completed total remaining <<< "$counts"

  [[ "$total" -eq 0 ]] && return

  local percentage=$((completed * 100 / total))
  local bar_filled=$((completed * 20 / total))
  local bar_empty=$((20 - bar_filled))
  local bar=""
  bar=$(printf '█%.0s' $(seq 1 $bar_filled 2>/dev/null) || true)
  bar+=$(printf '░%.0s' $(seq 1 $bar_empty 2>/dev/null) || true)

  echo -e "${BLUE}${BANNER}${NC}"
  echo -e "${GREEN}  Progress: [${bar}] ${completed}/${total} stories (${percentage}%)${NC}"
  echo -e "${YELLOW}  Remaining: ${remaining} stories${NC}"
  echo -e "${BLUE}${BANNER}${NC}"
}

print_completion_summary() {
  local counts completed total
  counts=$(get_story_counts)
  read -r completed total _ <<< "$counts"

  local commit_count
  commit_count=$(git -C "$PROJECT_ROOT" rev-list --count main..HEAD 2>/dev/null || echo "?")

  local push_status="✓ All pushed"
  local unpushed
  unpushed=$(git -C "$PROJECT_ROOT" log origin/"$BRANCH_NAME"..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$unpushed" -gt 0 ]]; then
    push_status="⚠ ${unpushed} unpushed"
  fi

  echo -e "${GREEN}${BANNER}${NC}"
  echo -e "${GREEN}  ✓ COMPLETE${NC}"
  echo -e "${GREEN}${BANNER}${NC}"
  echo
  echo -e "${GREEN}  Stories:     ${completed}/${total} complete${NC}"
  echo -e "${GREEN}  Commits:     ${commit_count} on branch${NC}"
  echo -e "${GREEN}  Push Status: ${push_status}${NC}"
  echo -e "${GREEN}  Branch:      ${BRANCH_NAME}${NC}"
  echo
  echo -e "${YELLOW}  Next steps:${NC}"
  echo -e "${YELLOW}    1. Review changes: git log main..${BRANCH_NAME}${NC}"
  echo -e "${YELLOW}    2. Create PR: gh pr create${NC}"
  echo -e "${YELLOW}    3. Or merge: git checkout main && git merge ${BRANCH_NAME}${NC}"
  echo
  echo -e "${GREEN}${BANNER}${NC}"
}

# ==============================================================================
# Git Functions
# ==============================================================================

check_unpushed_commits() {
  local unpushed
  unpushed=$(git -C "$PROJECT_ROOT" log origin/"$BRANCH_NAME"..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$unpushed" -gt 0 ]]; then
    echo -e "${YELLOW}Note: ${unpushed} unpushed commit(s) from previous iteration${NC}"
  fi
}

check_git_remote() {
  if ! git -C "$PROJECT_ROOT" remote get-url origin &>/dev/null; then
    echo -e "${YELLOW}Warning: No git remote 'origin' configured${NC}"
    echo -e "${YELLOW}  Commits will be saved locally but not pushed${NC}"
    echo
  fi
}

ensure_branch() {
  local current_branch
  current_branch=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || true)
  [[ "$current_branch" == "$BRANCH_NAME" ]] && return

  info "Switching to branch: $BRANCH_NAME"
  if git -C "$PROJECT_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    git -C "$PROJECT_ROOT" checkout "$BRANCH_NAME"
  else
    info "Creating new branch: $BRANCH_NAME"
    git -C "$PROJECT_ROOT" checkout -b "$BRANCH_NAME"
  fi
  echo
}

# ==============================================================================
# CLI Functions
# ==============================================================================

show_help() {
  cat <<EOF
Usage: ralph.sh --prd <dir> --root <dir> [options]

Required:
  --prd <dir>       PRD directory containing prd.json
  --root <dir>      Project root directory (where code lives)

Options:
  --tool <name>     AI tool: claude or amp (default: claude)
  --max <n>         Maximum iterations (default: 10)
  -h, --help        Show this help

Examples:
  ralph.sh --prd ./docs/prd/feature --root .
  ralph.sh --prd ./docs/prd/feature --root . --max 15
  ralph.sh --prd ./docs/prd/feature --root . --tool amp
  ralph.sh --prd ./docs/prd/feature --root /path/to/project --max 20 --tool claude
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --prd)     PRD_DIR="$2"; shift 2 ;;
      --prd=*)   PRD_DIR="${1#*=}"; shift ;;
      --root)    PROJECT_ROOT="$2"; shift 2 ;;
      --root=*)  PROJECT_ROOT="${1#*=}"; shift ;;
      --tool)    TOOL="$2"; shift 2 ;;
      --tool=*)  TOOL="${1#*=}"; shift ;;
      --max)     MAX_ITERATIONS="$2"; shift 2 ;;
      --max=*)   MAX_ITERATIONS="${1#*=}"; shift ;;
      -h|--help) show_help; exit 0 ;;
      -*)        error "Unknown option: $1"; show_help; exit 1 ;;
      *)         error "Unexpected argument: $1"; show_help; exit 1 ;;
    esac
  done
}

resolve_path() {
  local path="$1"
  local label="$2"
  if cd "$path" 2>/dev/null; then
    pwd
  else
    error "$label not found: $path"
    exit 1
  fi
}

validate_inputs() {
  if [[ -z "$PRD_DIR" ]]; then
    error "--prd is required"
    echo
    show_help
    exit 1
  fi

  if [[ -z "$PROJECT_ROOT" ]]; then
    error "--root is required"
    echo
    show_help
    exit 1
  fi

  PRD_DIR="$(resolve_path "$PRD_DIR" "PRD directory")"
  PROJECT_ROOT="$(resolve_path "$PROJECT_ROOT" "Project root")"

  if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
    error "--tool must be 'amp' or 'claude'"
    exit 1
  fi
}

# ==============================================================================
# Progress File Functions
# ==============================================================================

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

init_progress_file() {
  [[ -f "$PROGRESS_FILE" && -s "$PROGRESS_FILE" ]] && return

  info "Initializing progress.md..."

  local story_count remote_url
  story_count=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo "?")
  remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || echo "not configured")

  cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log

## Session Info

| Field | Value |
|-------|-------|
| **PRD** | $(basename "$PRD_DIR") |
| **Branch** | \`$BRANCH_NAME\` |
| **Started** | $(date) |
| **Stories** | $story_count total |
| **Remote** | $remote_url |

---

## Codebase Patterns

*(Patterns discovered during implementation will be added here by the agent)*

---

## Iteration Log

EOF
}

# ==============================================================================
# Iteration Functions
# ==============================================================================

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
  local counts completed total

  counts=$(get_story_counts)
  read -r completed total _ <<< "$counts"

  echo -e "${BLUE}${BANNER}${NC}"
  echo -e "${BLUE}  ITERATION $iteration/$MAX_ITERATIONS${NC}"
  echo -e "${BLUE}  Stories: ${completed}/${total} complete${NC}"
  echo -e "${BLUE}${BANNER}${NC}"
  echo

  check_unpushed_commits

  local output cmd
  if [[ "$TOOL" == "amp" ]]; then
    cmd="amp --dangerously-allow-all"
  else
    cmd="claude --dangerously-skip-permissions --print"
  fi
  output=$(cd "$PROJECT_ROOT" && build_prompt | $cmd 2>&1 | tee /dev/stderr) || true

  if echo "$output" | grep -q "<promise>COMPLETE</promise>"; then
    echo
    print_completion_summary
    exit 0
  fi

  echo
  print_progress
  echo
  sleep 2
}

# ==============================================================================
# Main
# ==============================================================================

main() {
  parse_args "$@"
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

  archive_previous_run
  echo "$BRANCH_NAME" > "$LAST_BRANCH_FILE"

  init_progress_file
  print_config

  ensure_branch
  check_git_remote
  print_progress

  echo -e "${GREEN}Starting autonomous execution...${NC}"
  echo

  for i in $(seq 1 "$MAX_ITERATIONS"); do
    run_iteration "$i"
  done

  echo
  print_progress
  echo

  local final_counts final_completed final_total final_remaining
  final_counts=$(get_story_counts)
  read -r final_completed final_total final_remaining <<< "$final_counts"

  print_banner "$YELLOW" \
    "Reached max iterations ($MAX_ITERATIONS)" \
    "" \
    "Stories: ${final_completed}/${final_total} complete" \
    "Remaining: ${final_remaining} stories" \
    "Branch: $BRANCH_NAME" \
    "" \
    "To continue: re-run with --max N" \
    "To review: cat $PROGRESS_FILE"
  exit 1
}

main "$@"
