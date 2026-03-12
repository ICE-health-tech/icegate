# Changes: TestFlight Deployment (Version 2.6.0+10)

Successfully deployed **Ice Gate** version `2.6.0+10` to Apple TestFlight on **2026-03-12**.

## Summary of Actions
- **Build Number Increment:** Automatically bumped from `9` to `10` in `pubspec.yaml`.
- **Project Cleaning:** Performed `flutter clean` and `flutter pub get` to ensure a fresh build state.
- **IPA Generation:** Built the App Store IPA using `flutter build ipa --release`.
- **TestFlight Upload:** Successfully uploaded the generated IPA (`ice_gate.ipa`) to App Store Connect using `xcrun altool`.

## Deployment Details
- **Version:** `2.6.0`
- **Build Number:** `10`
- **Bundle ID:** `duylong.art.icegate`
- **Upload Status:** Succeeded (No errors)
- **Delivery UUID:** `b8ece3f7-39cc-4577-9179-3553face0eda`

## Next Steps
- Verify the build in **App Store Connect**.
- Wait for Apple's processing (typically 5-30 minutes).
- Once processed, notify beta testers via TestFlight.
