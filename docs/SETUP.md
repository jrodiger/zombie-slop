# Local development and asset protection

Pinned engine: **Godot 4.7.2 stable**, GDScript, Compatibility renderer. Blender **4.5.14 LTS**, Apple Silicon. Original code is MIT; asset licenses are separate.

## Folder layout

All defaults are relative to the current user's home, not a committed machine-specific path:

```
~/Documents/GitHub/zombie-slop/         public source checkout
~/Documents/GitHub/zombie-slop-assets/  private editable .blend sources, LFS, metadata
~/Documents/ZombieSlop/downloads/       pristine packs, source URLs, SHA-256, license texts
~/Documents/ZombieSlop/generated/       reproducible GLB and original audio exports
~/Documents/ZombieSlop/workspace/       assembled Godot project and .godot import cache
~/Documents/ZombieSlop/builds/          local playable exports; never uploaded publicly
~/Documents/ZombieSlop/tools/           pinned Godot, Blender, CLI utilities
```

Use the sibling asset checkout; verify its remote identity and **private visibility before every first upload**. At initial implementation GitHub CLI was unauthenticated: local commits are protected by LFS, but are **not an off-machine backup**. Do not change billing or authorize paid LFS overages.

## Bootstrap

1. Install the engine and free official CLI tools:

   ```sh
   python3 scripts/install_tools.py --root "$HOME/Documents/ZombieSlop/tools"
   ```

2. Obtain Kenney City Kit (Suburban) 2.0 from [Kenney](https://kenney.nl/assets/city-kit-suburban). The reproducible downloader preserves its original archive, extracted files, license and checksum:

   ```sh
   python3 scripts/fetch_assets.py --originals "$HOME/Documents/ZombieSlop/downloads" --pack suburban
   ```

3. Install official Apple Silicon Blender 4.5.14 LTS from [Blender's official mirror](https://mirror.blender.org/release/Blender4.5/blender-4.5.14-macos-arm64.dmg). Place Blender.app under the external tools folder. No proprietary or paid assets are required for this local iteration.

4. Initialize or reuse the sibling private asset checkout. If it already has work, preserve it. Use an installed `git-lfs` path:

   ```sh
   python3 scripts/init_asset_repo.py --path ../zombie-slop-assets --lfs /path/to/git-lfs
   ```

   Git LFS tracking is committed before the first `.blend` commit. Do not put private asset LFS pointers in the public checkout.

5. Prefer the matching asset revision recorded in `docs/ASSETS.json`. The generator is for creating/re-exporting original assets, **not for overwriting hand-edited sources**. Before substantial changes commit the working asset checkpoint. Preserve existing sources, then export into a separate output directory. To recreate this first original asset set from code:

   ```sh
   "$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
     --background --python scripts/create_assets.py -- \
     --assets ../zombie-slop-assets --out "$HOME/Documents/ZombieSlop/generated"
   ```

   Blender autosave is enabled in the generation process at two minutes and saved backup versions are set to two. For interactive work enable the same settings in Blender Preferences → Save & Load. Preserve the `.blend` files with editable rigs/actions/materials. The generator exports GLB explicitly with Y-up, eight animation actions, no texture dependencies for original models, and joins meshes for fewer draw calls. The swinging door keeps its pivot separate. Original deterministic audio is synthesized with seed 7; editable parameters are in the generator and private `recipe.json`.

6. Assemble and launch:

   ```sh
   ./scripts/run.sh
   ```

   Assembly validates all required files, copies source and selected external assets into the runtime workspace, preserves texture-relative resource paths and import UIDs, and records the paired commits. Source changes belong in the public checkout. Always resync before testing. `ZOMBIE_HOME` and `GODOT` override the personal defaults. `assemble.py --assets PATH --home PATH` supports other checkouts/folders. It rejects outputs inside either checkout. No engine imports occur in source.

## Export and verification

```sh
./scripts/build.sh macOS
./scripts/build.sh Linux
./scripts/build.sh Windows
python3 scripts/test_source.py --godot "$HOME/Documents/ZombieSlop/tools/Godot.app/Contents/MacOS/Godot"
./scripts/run.sh -- --integration
```

The first three produce only **local external builds**, including their embedded assets. They must not be added to the public repository, LFS, GitHub releases, or CI artifacts. macOS exports are ad-hoc signed for local use, not notarized. Windows/Linux are cross-exportable; run them on their respective hardware before marking them tested. Steam Deck controls and Android are targets, not verified platforms.

A ten-minute benchmark is included in the exported binary:

```sh
"$HOME/Documents/ZombieSlop/builds/Zombie Slop.app/Contents/MacOS/Zombie Slop" -- --benchmark
```

It runs at 1280×800, uncapped, with shadows, 18 initial zombies and 50 placed objects. It repeats six 50-second sections twice and measures actual graphical frame cadence. Test modes use separate saves, neutralize damage during profiling and replenish ammo during the shooting segment. They do not establish physical controller or human playtest coverage. JSON metrics and PNGs go under the game's user data `verification/` directory or `ZOMBIE_REPORT_DIR`. Headless runs never count as rendering benchmarks.

## Backups and matching revisions

- Back up the entire pristine downloads folder (including archives, licenses and SOURCE.json checksums) to a user-selected external drive or existing cloud backup.
- Back up the private repository with its `.git/lfs/objects` **and** working source files. Git pointers alone cannot restore binary sources. Maintain a pushed private remote and a separate backup of the originals.
- `scripts/backup.py --destination PATH` creates a complete timestamped local archive for copying to that backup location. It never selects or configures a paid service.
- For private pushes use normal Git/Git LFS authentication; verify the repository is private, `git lfs fsck`, push the commit and LFS objects, then verify both. `git lfs ls-files --size` gives local source sizes; inspect GitHub's account LFS usage before enabling ongoing uploads. A rejected or unpushed push is not a backup.
- Record `git rev-parse HEAD` from the private asset checkout in the public asset manifest after local Blender/Godot inspection and tests. Never apply public MIT to third-party assets.
- Before every public push run `python3 scripts/check_source.py`, `git diff --cached --stat` and inspect the full staged file list. Never upload credentials or asset archives.

## Selected pack status

The requested Quaternius Zombie Apocalypse Kit, Survival Pack and Ultimate Nature Pack are CC0 on their author pages. Formats and folder contents were inspected. Their Google Drive files returned **quota exceeded** during setup; no successful downloads of those packs are claimed. `fetch_assets.py --pack zombie|survival|nature` reports missing downloads instead of storing HTML as an asset. Once available, adopt Quaternius characters and suitable props after verifying skeleton names, clip orientation and weapon sockets; rigs must not be assumed interchangeable.

ITHappy Apocalypse Free 1.1 offers Blender/FBX/OBJ/GLB and requires an account checkout. Its [free usage policy](https://ithappystudios.com/type-of-licenses/) prohibits as-is redistribution and derivatives outside a final product. It is not downloaded or privately uploaded here. No ITHappy characters are used. Account checkout/license verification is needed before incorporation. Original stand-ins keep the first prototype playable, but the requested selected-pack art direction remains incomplete.
