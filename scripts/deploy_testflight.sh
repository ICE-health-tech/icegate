#!/bin/bash
# ============================================================
# deploy_testflight.sh
# Auto deploy Ice Gate Flutter app to Apple TestFlight
# 
# Usage:
#   ./scripts/deploy_testflight.sh [--bump-build] [--skip-clean]
#
# Prerequisites:
#   - Xcode installed with valid signing certificates
#   - App Store Connect API key configured (or Apple ID auth)
#   - Flutter SDK in PATH
# ============================================================

set -e  # Exit immediately if a command fails

# --- Configuration ---
# Change these values to match your project
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$PROJECT_DIR/ios"
SCHEME="Runner"
WORKSPACE="Runner.xcworkspace"
ARCHIVE_PATH="$PROJECT_DIR/build/ios/Runner.xcarchive"
IPA_OUTPUT="$PROJECT_DIR/build/ios/ipa"
EXPORT_OPTIONS="$IOS_DIR/ExportOptions.plist"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Helper Functions ---
log_step() { echo -e "\n${GREEN}▸ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# --- Parse Arguments ---
BUMP_BUILD=false
SKIP_CLEAN=false

for arg in "$@"; do
  case $arg in
    --bump-build) BUMP_BUILD=true ;;
    --skip-clean) SKIP_CLEAN=true ;;
    --help)
      echo "Usage: ./scripts/deploy_testflight.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --bump-build   Auto-increment the build number before deploying"
      echo "  --skip-clean   Skip flutter clean step (faster rebuild)"
      echo "  --help         Show this help message"
      exit 0
      ;;
  esac
done

# --- Step 1: Bump build number (optional) ---
if [ "$BUMP_BUILD" = true ]; then
  log_step "Bumping build number..."
  cd "$PROJECT_DIR"
  # Read current version from pubspec.yaml
  CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
  VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
  BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
  NEW_BUILD=$((BUILD_NUMBER + 1))
  NEW_VERSION="${VERSION_NAME}+${NEW_BUILD}"
  
  # Update pubspec.yaml with new build number
  sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml
  echo "  Version: $CURRENT_VERSION → $NEW_VERSION"
fi

# --- Step 2: Clean (optional) ---
if [ "$SKIP_CLEAN" = false ]; then
  log_step "Cleaning previous build..."
  cd "$PROJECT_DIR"
  flutter clean
  flutter pub get
fi

# --- Step 3: Build iOS release ---
log_step "Building Flutter iOS release..."
cd "$PROJECT_DIR"
flutter build ipa --release --export-options-plist="$EXPORT_OPTIONS"

echo ""
echo "=================================================="
echo "  IPA built successfully!"
echo "  Output: $IPA_OUTPUT"
echo "=================================================="

# --- Step 4: Upload to TestFlight ---
log_step "Uploading to TestFlight..."

# Find the .ipa file in the output directory
IPA_FILE=$(find "$IPA_OUTPUT" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  log_error "No .ipa file found in $IPA_OUTPUT"
  exit 1
fi

echo "  Uploading: $IPA_FILE"

# Upload using xcrun notarytool / altool
# Option A: Using App Store Connect API Key (recommended)
#   Requires: AuthKey_XXXXXXXX.p8 file
#   xcrun altool --upload-app \
#     --type ios \
#     --file "$IPA_FILE" \
#     --apiKey "YOUR_API_KEY_ID" \
#     --apiIssuer "YOUR_ISSUER_ID"

# Option B: Using Apple ID (interactive, may need app-specific password)
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_FILE" \
  --username "duylongmind432001@gmail.com" \
  --password "@keychain:AC_PASSWORD"

log_step "✅ Upload complete! Check App Store Connect for processing status."
echo ""
echo "  📱 App Store Connect: https://appstoreconnect.apple.com"
echo "  ⏳ Processing usually takes 5-30 minutes"
echo ""
