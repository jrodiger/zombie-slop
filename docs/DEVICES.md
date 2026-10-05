# Play the demo on Pixel and Steam Deck

Steam publishing and Google Play publishing are unnecessary for a personal demo. Google Drive can transfer the finished builds to your own devices. Transfer the packages below, rather than the Mac `.app`, source checkout or raw asset packs. Keep these asset-containing builds in your personal storage; they are not public GitHub artifacts.

## Google Pixel / Android

Use `builds/android/Zombie Slop.apk` from the external ZombieSlop folder. It is a signed ARM64 Android app containing the game and its assets. No Godot editor or asset download is needed on the phone.

1. Upload the APK to a private folder in your own Google Drive. Alternatively copy it to the phone over USB.
2. On the Pixel, download it from Drive's file menu. Open the downloaded APK in Files / Downloads.
3. If prompted, allow **Install unknown apps** for the app opening this APK (usually Files or Chrome), then choose **Install**. Android keeps this permission separate for each source app. Leave Play Protect enabled.
4. Launch **Zombie Slop**. Hold the phone in landscape. Use the touch controls, or pair a Bluetooth gamepad / connect a USB gamepad.
5. For updates, install the newer APK over the existing app. The same package and local signing key preserve compatibility. **Do not uninstall first**: uninstalling removes the phone's local save. The signing checkpoint stays external under `tools/android-keys/`; preserve it, including its companion credentials. Losing it prevents in-place updates signed with that key.

Touch: drag the left circle to move; drag open space on the right to look. Tap **Aim** and **Sprint** to toggle them; hold **Fire** to shoot. **Use**, **Reload**, **Jump**, **Heal**, **Weapon**, **Pack**, **Build** and **Menu** cover the other actions. **Move item** and **Take item** manage placed objects. Building replaces combat buttons with rotate, raise/lower, near/far, snap, place and cancel. In a vehicle, the left stick accelerates/reverses and steers; **Brake** stops it and **Exit** leaves it. Opening a menu or leaving the app releases virtual controls. Android Back closes a menu/cancels placement or pauses the game. Android backgrounding saves progress and pauses.

Using a gamepad hides the touch overlay. Touch the screen to use it again. Menus support taps, scrolling, controller focus and the controller's accept/back buttons. The phone has its own local progress; Google Drive transfers builds, not automatic cloud saves.

If Android refuses the install, keep the exact message and phone model/Android version. Don't disable Play Protect or uninstall a saved game as a first troubleshooting step. This is a personally signed demo, not a Play Store release.

## Steam Deck

Use `builds/transfers/Zombie Slop - Steam Deck.zip`. It contains the native Linux executable, its matching `.pck`, a launcher and these instructions. No Steamworks registration, purchase or Proton layer is required.

1. Upload the ZIP to your own private Drive folder.
2. On Deck, choose **Steam → Power → Switch to Desktop**. Download the ZIP in a browser and extract the whole folder to somewhere permanent, such as `Home/Games/Zombie Slop`. Keep the executable and `.pck` together.
3. In Dolphin, right-click `Launch Zombie Slop.sh` → **Properties → Permissions** and enable **Is executable** if needed. Do the same for `Zombie Slop.x86_64`. Double-click the launcher to try it in Desktop Mode.
4. In the desktop Steam client, choose **Games → Add a Non-Steam Game to My Library → Browse**. Choose `Launch Zombie Slop.sh` (show all file types if needed). Name the shortcut **Zombie Slop**. Keep its start directory set to the extracted folder.
5. Return to Gaming Mode and launch it from **Non-Steam**. Under the shortcut's controller settings, use **Gamepad with Joystick Trackpad** / a standard gamepad layout. Disable forced Proton compatibility for this native Linux build.

If an archive tool removes executable permissions, this equivalent command in Konsole restores them from inside the extracted folder:

```sh
chmod +x "Launch Zombie Slop.sh" "Zombie Slop.x86_64"
```

To update, fully quit the game and replace the extracted build files with the new matching package. Saves remain in the user's game-data directory, separate from those files. Do not mix an executable from one download with a `.pck` from another.

## Controller mapping

| Action | Gamepad / Deck |
|---|---|
| Move / look | Left / right stick |
| Aim / fire | LT / RT |
| Sprint / jump or vehicle brake | L3 / RB |
| Use, loot, enter/exit car | A |
| Reload / build / pause | X / Y / Menu (Start) |
| Inventory | View (Back) |
| Heal / cycle weapon | D-pad up / left |
| Move / recover placed item | LB / D-pad down |
| Place / cancel | A / B |
| Rotate placed object | LB / RB |
| Placement height / distance | D-pad up/down / right/left |
| Placement snap | X |

## Build it again

Godot is pinned to 4.7.2. The Android helper uses the prebuilt non-Gradle export template, so NDK/CMake and Android Studio are unnecessary for this project. Install Java 17 and Android SDK command-line tools from their official sources, then install `platform-tools`, `build-tools;35.0.1` and `platforms;android-35` with `sdkmanager`. Accept their free SDK license during setup. Godot's matching Android export templates must also be installed.

Set `JAVA_HOME` to the JDK's Home directory and `ANDROID_HOME` to the SDK root. The helper also accepts the external `tools/android-toolchain.json` produced by local setup. It configures Godot's Android editor paths, creates a local demo signing key once, assembles external assets, exports and verifies the signed offline APK. It refuses an incomplete signing checkpoint rather than replacing a saved key. No credentials or binaries belong in public Git.

```sh
./scripts/build.sh Android
./scripts/build.sh Linux
python3 scripts/package_devices.py
```

`ZOMBIE_HOME`, `ZOMBIE_ASSETS` and `GODOT` select the external workspace, matching private asset checkout and engine. The package script requires matching signature evidence and asset-content fingerprints, then copies complete tested/exported build outputs into external transfer packages and adds SHA-256 sidecars. It does not upload anything to Drive or publish anywhere.

For native graphical input regression, use `-- --touch-test` at the end of the exported game's command line. It uses isolated progress and preferences, dispatches real touch/joypad events, tests multi-finger actions, menus, placement, driving, releases and input handoff, and writes `devices.json` plus screenshots outside public Git. This is automated input coverage, not physical controller or phone performance coverage.

Official instructions: [Pixel app downloads and installation](https://support.google.com/pixelphone/answer/9457058), [Android unknown-source installation](https://developer.android.com/distribute/marketing-tools/alternative-distribution), [Steam non-Steam shortcuts](https://help.steampowered.com/en/faqs/view/4B8B-9697-2338-40EC), [Godot Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Physical Pixel, Bluetooth/USB gamepad and Steam Deck performance remain unverified until tested on those devices. The initial phone preset retains the 60 FPS cap, disables sun shadows by default and scales 3D rendering to 75% while keeping UI crisp. This does not imply a measured 60 FPS result on a phone or Deck.
