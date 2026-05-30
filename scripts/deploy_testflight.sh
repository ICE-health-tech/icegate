#!/bin/bash
# ============================================================
# deploy_testflight.sh
# Build Ice Gate for TestFlight / App Store Connect
#
# Usage:
#   ./scripts/deploy_testflight.sh [--bump-build] [--skip-clean] [--upload] [--organizer]
#
# Default: build .xcarchive + export .ipa to build/ios/ipa/ for Transporter.
# Use --organizer to open the archive in Xcode instead of exporting .ipa.
#
# Prerequisites:
#   - Xcode + Apple Distribution cert (Xcode → Settings → Accounts)
#   - Flutter SDK in PATH
#   - For --upload: a .ipa already exported from Organizer
# ============================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
IPA_OUTPUT="$PROJECT_DIR/build/ios/ipa"
ORGANIZER_DAY="$(date +%Y-%m-%d)"
ORGANIZER_ROOT="$HOME/Library/Developer/Xcode/Archives/$ORGANIZER_DAY"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step() { echo -e "\n${GREEN}▸ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

BUMP_BUILD=true
SKIP_CLEAN=false
DO_UPLOAD=false
OPEN_ORGANIZER=false
ASC_LAST_BUILD=""
FRESH_TRAIN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --bump-build) BUMP_BUILD=true ;;
    --no-bump) BUMP_BUILD=false ;;
    --skip-clean) SKIP_CLEAN=true ;;
    --upload) DO_UPLOAD=true ;;
    --organizer) OPEN_ORGANIZER=true ;;
    --fresh-train) FRESH_TRAIN=true ;;
    --asc-last)
      ASC_LAST_BUILD="${2:-}"
      shift 2
      continue
      ;;
    --help)
      echo "Usage: ./scripts/deploy_testflight.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --bump-build      Increment build in pubspec (default ON)"
      echo "  --no-bump         Skip build bump"
      echo "  --asc-last N      Set build to N+1 (use highest build from TestFlight)"
      echo "  --fresh-train     Use 4.0.1+101 (new version line — use if 4.0.0 stuck)"
      echo "  --skip-clean      Skip flutter clean"
      echo "  --upload          Upload .ipa from build/ios/ipa/ (altool)"
      echo "  --organizer       Open .xcarchive in Xcode instead of exporting .ipa"
      echo ""
      echo "If upload always fails:"
      echo "  1. TestFlight → note GLOBAL highest build (any version), not only 4.0.0"
      echo "  2. ./scripts/deploy_testflight.sh --asc-last 16 --skip-clean"
      echo "  3. Or: ./scripts/deploy_testflight.sh --fresh-train --skip-clean"
      exit 0
      ;;
    *)
      log_error "Unknown option: $1 (try --help)"
      exit 1
      ;;
  esac
  shift
done

if [ "$DO_UPLOAD" = true ]; then
  IPA_FILE=""
  if [ -d "$IPA_OUTPUT" ]; then
    IPA_FILE=$(find "$IPA_OUTPUT" -name "*.ipa" -type f -print -quit 2>/dev/null || true)
  fi
  if [ -z "$IPA_FILE" ]; then
    log_error "No .ipa in $IPA_OUTPUT — export from Xcode Organizer first."
    exit 1
  fi
  log_step "Uploading $IPA_FILE to App Store Connect..."
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_FILE" \
    --username "duylongmind432001@gmail.com" \
    --password "@keychain:AC_PASSWORD"
  log_step "Upload submitted. Check App Store Connect in 5–30 min."
  exit 0
fi

# --- Version / build (pubspec only) ---
cd "$PROJECT_DIR"
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

if [ "$FRESH_TRAIN" = true ]; then
  log_step "Fresh App Store train: 4.0.1+101"
  sed -i '' 's/^version: .*/version: 4.0.1+101/' pubspec.yaml
elif [ -n "$ASC_LAST_BUILD" ]; then
  NEW_BUILD=$((ASC_LAST_BUILD + 1))
  log_step "Setting build from TestFlight: $ASC_LAST_BUILD → $NEW_BUILD"
  sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD}/" pubspec.yaml
elif [ "$BUMP_BUILD" = true ]; then
  log_step "Bumping build in pubspec.yaml..."
  NEW_BUILD=$((BUILD_NUMBER + 1))
  sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD}/" pubspec.yaml
  echo "  $CURRENT_VERSION → ${VERSION_NAME}+${NEW_BUILD}"
fi

CURRENT_VERSION=$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //')
PUBSPEC_MARKETING=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
PUBSPEC_BUILD=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
echo "  Target: $PUBSPEC_MARKETING ($PUBSPEC_BUILD) from pubspec.yaml"

echo ""
echo "  IMPORTANT: Apple compares build numbers across ALL versions (3.2.4, 4.0.0, …)."
echo "  TestFlight → highest build anywhere must be LESS than your new build."

log_step "Checking code signing..."
if ! security find-identity -v -p codesigning 2>/dev/null | grep -qE "Apple Distribution|iOS Distribution"; then
  log_warn "No Apple Distribution certificate in Keychain."
  echo "  Add: Xcode → Settings → Accounts → Manage Certificates → Apple Distribution"
fi

if [ "$SKIP_CLEAN" = false ]; then
  log_step "Cleaning..."
  cd "$PROJECT_DIR"
  flutter clean
  flutter pub get
else
  cd "$PROJECT_DIR"
  flutter pub get
fi

log_step "Building iOS release..."
set +e
flutter build ios --release --no-tree-shake-icons
FLUTTER_BUILD_EXIT=$?
set -e
if [ "$FLUTTER_BUILD_EXIT" -ne 0 ]; then
  log_error "flutter build ios failed (exit $FLUTTER_BUILD_EXIT)."
  exit 1
fi

log_step "Archiving with xcodebuild..."
rm -rf "$ARCHIVE_PATH"
set +e
(
  cd "$PROJECT_DIR/ios"
  xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM=JJ5CR7B87P \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    archive
)
XCODE_EXIT=$?
set -e

if [ ! -d "$ARCHIVE_PATH" ]; then
  log_error "No archive at $ARCHIVE_PATH (xcodebuild exit $XCODE_EXIT)."
  exit 1
fi

APP_PATH="$ARCHIVE_PATH/Products/Applications/Runner.app"
MARKETING=$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Info.plist")
BUILD=$(plutil -extract CFBundleVersion raw "$APP_PATH/Info.plist")
SIGNING="unknown"
if codesign -dvvv "$APP_PATH" >/dev/null 2>&1; then
  SIGNING=$(codesign -dvvv "$APP_PATH" 2>&1 | sed -n 's/^Authority=//p' | head -1 || true)
fi

# Archive must match pubspec or Apple will see the wrong build.
if [ "$MARKETING" != "$PUBSPEC_MARKETING" ] || [ "$BUILD" != "$PUBSPEC_BUILD" ]; then
  log_error "Archive ($MARKETING / $BUILD) != pubspec ($PUBSPEC_MARKETING+$PUBSPEC_BUILD)."
  echo "  Fix: flutter pub get && ./scripts/deploy_testflight.sh --skip-clean"
  echo "  Never change Version/Build only in Xcode — only pubspec.yaml."
  exit 1
fi

echo ""
echo "=================================================="
echo "  ✓ Archive ready for TestFlight"
echo "=================================================="
echo "  Path:    $ARCHIVE_PATH"
echo "  Version: $MARKETING ($BUILD)"
echo "  Signed:  $SIGNING"
if echo "$SIGNING" | grep -q "Apple Development"; then
  echo ""
  echo "  Note: Archive uses Development cert — normal for CLI builds."
  echo "  Organizer → Distribute will re-sign with Apple Distribution."
fi

if [ "$OPEN_ORGANIZER" = true ]; then
  log_step "Opening archive in Xcode Organizer..."
  open "$ARCHIVE_PATH"
  exit 0
fi

log_step "Exporting App Store .ipa..."
rm -rf "$IPA_OUTPUT"
set +e
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$IPA_OUTPUT" \
  -exportOptionsPlist "$PROJECT_DIR/ios/ExportOptions.plist" \
  -allowProvisioningUpdates
EXPORT_EXIT=$?
set -e

IPA_FILE=""
if [ -d "$IPA_OUTPUT" ]; then
  IPA_FILE=$(find "$IPA_OUTPUT" -name "*.ipa" -type f -print -quit 2>/dev/null || true)
fi

if [ "$EXPORT_EXIT" -ne 0 ] || [ -z "$IPA_FILE" ]; then
  log_error "IPA export failed (exit $EXPORT_EXIT)."
  echo "  Try: ./scripts/deploy_testflight.sh --organizer"
  exit 1
fi

echo ""
echo "=================================================="
echo "  ✓ IPA ready for Transporter"
echo "=================================================="
echo "  File:    $IPA_FILE"
echo "  Version: $MARKETING ($BUILD)"
echo ""
echo "  Upload with Transporter (Mac App Store):"
echo "    1. Open Transporter"
echo "    2. Drag and drop the .ipa above (or click +)"
echo "    3. Deliver"
echo ""
echo "  Or CLI: ./scripts/deploy_testflight.sh --upload"
echo ""
echo "  If Apple rejects the build number, check TestFlight for the"
echo "  global highest build, then:"
echo "    ./scripts/deploy_testflight.sh --asc-last <max> --skip-clean"
echo ""

open -R "$IPA_FILE"
exit 0
