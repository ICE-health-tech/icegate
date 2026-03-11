---
description: Deploy the Flutter app to Apple TestFlight for beta testing
---

# Deploy to Apple TestFlight

## Prerequisites

1. **Apple Developer Account** with App Store Connect access
2. **Xcode** installed with valid iOS distribution certificate
3. **App-Specific Password** stored in Keychain (for `xcrun altool`)

### One-Time Setup: Store App-Specific Password

Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords, then store it:

```bash
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
  -u "YOUR_APPLE_ID@email.com" \
  -p "xxxx-xxxx-xxxx-xxxx"
```

Or use **App Store Connect API Key** (recommended for CI):
1. Go to [App Store Connect → Users & Access → Integrations → Keys](https://appstoreconnect.apple.com/access/integrations/api)
2. Generate a new key, download the `.p8` file
3. Note the **Key ID** and **Issuer ID**

---

## Quick Deploy (One Command)

```bash
# From project root
// turbo
./scripts/deploy_testflight.sh --bump-build
```

---

## Step-by-Step Manual Deploy

### 1. Bump version (optional)

Edit `pubspec.yaml` version or use:
```bash
# Auto-increment build number: 2.5.0+6 → 2.5.0+7
./scripts/deploy_testflight.sh --bump-build --skip-clean
```

### 2. Clean and get dependencies
// turbo
```bash
flutter clean && flutter pub get
```

### 3. Build IPA for App Store / TestFlight
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### 4. Upload to TestFlight

**Option A: Using Apple ID**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --username "YOUR_APPLE_ID@email.com" \
  --password "@keychain:AC_PASSWORD"
```

**Option B: Using API Key (recommended for CI)**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --apiKey "YOUR_API_KEY_ID" \
  --apiIssuer "YOUR_ISSUER_ID"
```

### 5. Check status

Go to [App Store Connect](https://appstoreconnect.apple.com) → My Apps → Ice Gate → TestFlight

Processing takes 5–30 minutes. Testers are auto-notified once approved.

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `No signing certificate` | Open Xcode → Runner → Signing & Capabilities → check team |
| `Provisioning profile error` | Delete `~/Library/MobileDevice/Provisioning Profiles/*` and rebuild |
| `Upload failed: auth` | Regenerate app-specific password and re-store in Keychain |
| `Invalid binary` | Check minimum iOS version matches (currently 15.0) |
