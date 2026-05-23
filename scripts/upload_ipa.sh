#!/bin/bash
# ============================================================
# upload_ipa.sh
# Upload an existing .ipa file to Apple TestFlight / App Store Connect
#
# Usage:
#   ./scripts/upload_ipa.sh [path/to/your/app.ipa]
#
# If no file is provided, it automatically finds the latest .ipa in build/ios/ipa/
# ============================================================

set -e  # Exit immediately if a command fails

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IPA_DIR="$PROJECT_DIR/build/ios/ipa"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_step() { echo -e "\n${GREEN}▸ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# --- Step 1: Find or Validate IPA file ---
IPA_FILE=""

if [ -n "$1" ]; then
  # Use provided argument
  if [ -f "$1" ]; then
    IPA_FILE="$1"
  else
    log_error "File not found: $1"
    exit 1
  fi
else
  # Auto-detect latest .ipa in build/ios/ipa/
  log_step "Searching for IPA file in $IPA_DIR..."
  if [ -d "$IPA_DIR" ]; then
    # Find latest .ipa file sorted by modification time (newest first)
    LATEST_IPA=$(find "$IPA_DIR" -name "*.ipa" -type f -print0 | xargs -0 stat -f "%m %N" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    if [ -n "$LATEST_IPA" ] && [ -f "$LATEST_IPA" ]; then
      IPA_FILE="$LATEST_IPA"
      log_step "Auto-detected latest IPA: $(basename "$IPA_FILE")"
    fi
  fi
fi

if [ -z "$IPA_FILE" ]; then
  log_error "No .ipa file found."
  echo "Usage: ./scripts/upload_ipa.sh [path/to/your/app.ipa]"
  echo "Or make sure you built one first using 'flutter build ipa'"
  exit 1
fi

# --- Step 2: Inform credentials setup if needed ---
echo ""
echo "--------------------------------------------------"
echo "Using Apple ID: duylongmind432001@gmail.com"
echo "Using Keychain Password: AC_PASSWORD"
echo ""
echo "If you haven't set up the keychain item yet, run:"
echo "  xcrun altool --store-password-in-keychain-item \"AC_PASSWORD\" \\"
echo "    -u \"duylongmind432001@gmail.com\" \\"
echo "    -p \"<your-app-specific-password>\""
echo "--------------------------------------------------"

# --- Step 3: Validate App with Apple ---
log_step "Validating app with App Store Connect..."
if xcrun altool --validate-app \
  --type ios \
  --file "$IPA_FILE" \
  --username "duylongmind432001@gmail.com" \
  --password "@keychain:AC_PASSWORD"; then
  
  log_step "✓ Validation successful!"
else
  log_error "Validation failed. Please verify the build and credentials."
  exit 1
fi

# --- Step 4: Upload to TestFlight ---
log_step "Uploading to TestFlight..."
if xcrun altool --upload-app \
  --type ios \
  --file "$IPA_FILE" \
  --username "duylongmind432001@gmail.com" \
  --password "@keychain:AC_PASSWORD"; then

  log_step "✅ Upload complete! Check App Store Connect for processing status."
  echo ""
  echo "  📱 App Store Connect: https://appstoreconnect.apple.com"
  echo "  ⏳ Processing usually takes 5-30 minutes"
  echo ""
else
  log_error "Upload failed."
  exit 1
fi
