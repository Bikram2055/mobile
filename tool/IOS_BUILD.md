# iOS (iPhone) build notes

This repo can’t build iOS from Ubuntu/Linux (Flutter’s iOS build requires macOS + Xcode).

## What’s already set up

- iOS app display name: `Expense Tracker` (`ios/Runner/Info.plist` → `CFBundleDisplayName`)
- iOS app icon: generated from `assets/icons/app_icon.png` via `flutter_launcher_icons`

## Build & install on a real iPhone (macOS required)

1. Install prerequisites:
   - Xcode (from the Mac App Store) and open it once to finish setup
   - CocoaPods (`sudo gem install cocoapods`), then `pod repo update`
2. From the project root:
   - `flutter pub get`
   - `cd ios && pod install && cd ..`
3. Open Xcode workspace:
   - Open `ios/Runner.xcworkspace`
   - Select **Runner** → **Signing & Capabilities**
   - Set **Team** and make sure **Automatically manage signing** is enabled
   - Set a real **Bundle Identifier** (not `com.example...`) that matches your Apple Team
4. Firebase (required for this app’s auth/database):
   - Download `GoogleService-Info.plist` for iOS from Firebase Console
   - Put it at `ios/Runner/GoogleService-Info.plist`
   - In Xcode, add it to the **Runner** target (make sure “Copy items if needed” is checked)
5. Install to your phone:
   - Plug in the iPhone, tap “Trust” if prompted
   - Run `flutter run -d <your-iphone-device-id>`

## Build an .ipa (for TestFlight / sharing)

- In terminal (macOS): `flutter build ipa`
- Or in Xcode: **Product → Archive**, then distribute (TestFlight/App Store or Ad Hoc).

