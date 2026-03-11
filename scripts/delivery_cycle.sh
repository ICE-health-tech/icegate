#!/bin/bash
# ============================================================
# delivery_cycle.sh
# Orchestrate the full Ice Gate delivery cycle
#
# Usage:
#   ./scripts/delivery_cycle.sh plan "Requirement"      # Phase 1: Planning
#   ./scripts/delivery_cycle.sh deploy [web|testflight] # Phase 3: Deployment
#   ./scripts/delivery_cycle.sh commit "Message"        # Phase 5: Finalize
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_step() { echo -e "${GREEN}▸ $1${NC}"; }
log_info() { echo -e "${CYAN}  $1${NC}"; }

PHASE=$1
shift

case $PHASE in
  plan)
    REQUIREMENT=$1
    log_step "Phase 1: Planning for '$REQUIREMENT'"
    log_info "Please ensure implementation_plan.md and task.md are updated."
    # Here we could potentially auto-generate a template
    ;;
    
  deploy)
    TARGET=${1:-testflight}
    log_step "Phase 3: Deploying to $TARGET"
    if [ "$TARGET" == "testflight" ]; then
      ./scripts/deploy_testflight.sh --bump-build
    elif [ "$TARGET" == "web" ]; then
      log_info "Building web..."
      flutter build web --release
      log_info "Web build complete. Please host as needed."
    else
      echo "Unknown target: $TARGET"
      exit 1
    fi
    ;;
    
  commit)
    MSG=$1
    log_step "Phase 5: Finalizing & Committing"
    ./scripts/auto_commit.sh "$MSG" --push
    ;;
    
  *)
    echo "Usage: ./scripts/delivery_cycle.sh {plan|deploy|commit} [args]"
    exit 1
    ;;
esac

echo -e "\n${GREEN}✅ Phase '$PHASE' complete.${NC}"
