#!/bin/bash
# ============================================================
# auto_commit.sh
# Auto commit all changes with a smart commit message
#
# Usage:
#   ./scripts/auto_commit.sh                    # Auto-generate message
#   ./scripts/auto_commit.sh "custom message"   # Use custom message
#   ./scripts/auto_commit.sh --push             # Commit + push
#   ./scripts/auto_commit.sh "message" --push   # Custom message + push
# ============================================================

set -e

# --- Configuration ---
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log_step() { echo -e "${GREEN}▸ $1${NC}"; }
log_info() { echo -e "${CYAN}  $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

# --- Parse Arguments ---
CUSTOM_MSG=""
DO_PUSH=false

for arg in "$@"; do
  case $arg in
    --push) DO_PUSH=true ;;
    --help)
      echo "Usage: ./scripts/auto_commit.sh [message] [--push]"
      echo ""
      echo "Options:"
      echo "  message    Custom commit message (optional)"
      echo "  --push     Push to remote after committing"
      echo "  --help     Show this help"
      exit 0
      ;;
    *) CUSTOM_MSG="$arg" ;;
  esac
done

# --- Check for changes ---
# Stage all changes first to see what we have
UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

TOTAL=$((UNSTAGED + UNTRACKED + STAGED))

if [ "$TOTAL" -eq 0 ]; then
  log_warn "No changes to commit."
  exit 0
fi

# --- Show summary of changes ---
log_step "Changes detected:"

# Count file types changed
DART_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null | grep '\.dart$' | wc -l | tr -d ' ')
ARB_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null | grep '\.arb$' | wc -l | tr -d ' ')
YAML_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null | grep '\.yaml$\|\.yml$' | wc -l | tr -d ' ')
MD_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null | grep '\.md$' | wc -l | tr -d ' ')
SH_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null | grep '\.sh$' | wc -l | tr -d ' ')

# Show changed files (max 15)
git status --short | head -15
TOTAL_FILES=$(git status --short | wc -l | tr -d ' ')
if [ "$TOTAL_FILES" -gt 15 ]; then
  log_info "... and $((TOTAL_FILES - 15)) more files"
fi

echo ""

# --- Generate commit message ---
if [ -n "$CUSTOM_MSG" ]; then
  # Use custom message provided by user
  COMMIT_MSG="$CUSTOM_MSG"
else
  # Auto-generate a smart commit message based on changed files
  # Get the list of all changed/new files
  CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)
  
  # Detect categories of changes
  HAS_L10N=$(echo "$CHANGED_FILES" | grep -c 'l10n\|\.arb' || true)
  HAS_UI=$(echo "$CHANGED_FILES" | grep -c 'ui_layer' || true)
  HAS_HEALTH=$(echo "$CHANGED_FILES" | grep -c 'health' || true)
  HAS_FINANCE=$(echo "$CHANGED_FILES" | grep -c 'finance\|Finance' || true)
  HAS_CONFIG=$(echo "$CHANGED_FILES" | grep -c 'pubspec\|\.yaml\|\.plist' || true)
  HAS_SCRIPTS=$(echo "$CHANGED_FILES" | grep -c 'scripts\|\.sh' || true)
  HAS_SOCIAL=$(echo "$CHANGED_FILES" | grep -c 'social\|Social' || true)
  HAS_NOTIFICATION=$(echo "$CHANGED_FILES" | grep -c 'notification\|Notification' || true)
  HAS_PROJECT=$(echo "$CHANGED_FILES" | grep -c 'project\|Project' || true)
  
  # Build commit message parts
  PARTS=()
  [ "$HAS_L10N" -gt 0 ] && PARTS+=("localization")
  [ "$HAS_UI" -gt 0 ] && PARTS+=("UI")
  [ "$HAS_HEALTH" -gt 0 ] && PARTS+=("health")
  [ "$HAS_FINANCE" -gt 0 ] && PARTS+=("finance")
  [ "$HAS_SOCIAL" -gt 0 ] && PARTS+=("social")
  [ "$HAS_NOTIFICATION" -gt 0 ] && PARTS+=("notifications")
  [ "$HAS_PROJECT" -gt 0 ] && PARTS+=("projects")
  [ "$HAS_CONFIG" -gt 0 ] && PARTS+=("config")
  [ "$HAS_SCRIPTS" -gt 0 ] && PARTS+=("scripts")
  
  # Get current version from pubspec.yaml
  VERSION=$(grep '^version:' pubspec.yaml 2>/dev/null | sed 's/version: //' || echo "unknown")
  
  # Get current branch
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  
  # Build the final message
  if [ ${#PARTS[@]} -eq 0 ]; then
    SCOPE="general"
  elif [ ${#PARTS[@]} -le 3 ]; then
    SCOPE=$(IFS=', '; echo "${PARTS[*]}")
  else
    SCOPE="${PARTS[0]}, ${PARTS[1]} +$((${#PARTS[@]} - 2)) more"
  fi
  
  # Get current timestamp
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  
  COMMIT_MSG="chore(${SCOPE}): update ${TOTAL_FILES} files [v${VERSION}]"
fi

# --- Stage all changes ---
log_step "Staging all changes..."
git add -A

# --- Commit ---
log_step "Committing..."
log_info "Message: ${COMMIT_MSG}"
git commit -m "$COMMIT_MSG"

# --- Push (optional) ---
if [ "$DO_PUSH" = true ]; then
  BRANCH=$(git branch --show-current)
  log_step "Pushing to origin/${BRANCH}..."
  git push origin "$BRANCH"
  log_step "✅ Pushed successfully!"
else
  echo ""
  log_info "To push: git push origin $(git branch --show-current)"
fi

echo ""
echo "=================================================="
echo -e "  ${GREEN}✅ Committed successfully!${NC}"
echo "  📝 ${COMMIT_MSG}"
echo "  📁 ${TOTAL_FILES} files changed"
echo "=================================================="
