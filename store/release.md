# Publishing: web, TestFlight, Google Play

The web version is live at https://monkey-bananas.vercel.app and ships with
`MB_VERCEL_PROJECT=monkey-bananas tools/deploy_web.sh` after `tools/build_web.sh` (git pushes do
not deploy). `https://monkey-bananas-v2.vercel.app` is the test copy (the script's default).

The stores need Bar's accounts and money, so they wait for him. The agent never types Bar's
Apple ID, Google account, passwords or payment details, never accepts store agreements, and
never uploads or submits without Bar saying so in the chat.

## iOS (TestFlight, then the App Store)

**Bar, once:**
1. Enroll at developer.apple.com/programs as an Individual ($99/yr) and accept the agreements
   in App Store Connect (the Free Apps agreement is enough for a free app).
2. Sign in to Xcode with that Apple ID: Xcode > Settings > Accounts > +.
3. Save the 10-character Team ID (developer.apple.com > Account > Membership) where the release
   script reads it (not a secret, but it stays off git):
   ```bash
   mkdir -p ~/.config/monkey-bananas && echo YOURTEAMID > ~/.config/monkey-bananas/team_id
   ```
4. Create the app record in App Store Connect with the values in `store/app-store.md`.

**The agent, each step after Bar says go:**
1. `tools/release_ios.sh --check` proves the project compiles unsigned. (`--sim` is already
   verified: it installs and runs on an iPhone 17 Pro simulator, iOS 26.3.)
2. `tools/release_ios.sh --upload` archives, signs through Xcode's account, and uploads to
   TestFlight.
3. Bar installs it from TestFlight and plays; then the listing, screenshots, App Privacy
   ("Data Not Collected") and the age rating go in, and Bar submits for review.

## Android (Google Play)

**Today:** `tools/build_android.sh` builds a sideload APK (`build/monkey-bananas-<ver>.apk`,
about 27 MB) signed with a throwaway debug key. Install it on an Android phone with USB
debugging on: `adb install -r build/monkey-bananas-2.0.0.apk`, or send the file and open it.

**For the Play Store, Bar, once:**
1. Create a Google Play developer account ($25, one time) and verify identity.
2. Create an upload keystore on his machine (never committed; `*.keystore` is git-ignored),
   and keep its password in his password manager.
3. Create the app in Play Console with the listing in `store/app-store.md`.

**Then the agent:** switch the Android preset to AAB (`gradle_build/export_format=1`, which
needs the Godot Android build template installed into `game/android/`) and export a release
AAB signed with Bar's upload key through the `GODOT_ANDROID_KEYSTORE_RELEASE_*` environment
variables, for Bar to upload to an internal testing track.

## Every later version
Bump `config/version` in `game/project.godot` and the preset version fields (the iOS build
number and the Android version code must go up every upload), run `tools/test.sh` and
`tools/balance.sh`, then the steps above.
