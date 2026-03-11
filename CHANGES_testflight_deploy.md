# TestFlight Auto Deploy Setup

## What was created

### 1. `scripts/deploy_testflight.sh`
- **Purpose**: One-command script to build and upload to TestFlight
- **Features**:
  - `--bump-build` — Auto-increment build number in `pubspec.yaml`
  - `--skip-clean` — Skip `flutter clean` for faster rebuilds
  - Runs `flutter build ipa` with correct export options
  - Uploads IPA via `xcrun altool`

### 2. `ios/ExportOptions.plist`
- **Purpose**: Tells Xcode how to export the IPA for App Store distribution
- **Config**: Team ID `JJ5CR7B87P`, automatic signing, App Store method

### 3. `.agent/workflows/deploy-testflight.md`
- **Purpose**: Reusable workflow (use `/deploy-testflight` slash command)
- **Contains**: Full step-by-step guide + troubleshooting

## Before First Use

You need to do **one** of these authentication setups:

### Option A: App-Specific Password (simpler)
```bash
# 1. Go to https://appleid.apple.com → App-Specific Passwords → Generate
# 2. Store in Keychain:
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
  -u "YOUR_APPLE_ID@email.com" \
  -p "xxxx-xxxx-xxxx-xxxx"
```

### Option B: API Key (better for CI/automation)
```bash
# 1. Go to App Store Connect → Users → Keys → Generate API Key
# 2. Download the .p8 file
# 3. Update deploy_testflight.sh with your Key ID and Issuer ID
```

## Quick Deploy
```bash
./scripts/deploy_testflight.sh --bump-build
```

This will: bump build `2.5.0+6` → `2.5.0+7` → clean → build IPA → upload to TestFlight ✈️
