# Local development and asset protection

Pinned engine: **Godot 4.7.2 stable**, GDScript. macOS uses the Mobile renderer with native Metal after measured frame-pacing comparisons; other platforms retain Compatibility. See [validation](VALIDATION.md) for results and limits. Blender **4.5.14 LTS**, Apple Silicon. Original code is MIT; asset licenses are separate.

## Folder layout

All defaults are relative to the current user's home, not a committed machine-specific path:

```
~/Documents/GitHub/zombie-slop/         public source checkout
~/Documents/GitHub/zombie-slop-assets/  private editable .blend sources, LFS, metadata
~/Documents/ZombieSlop/downloads/       pristine packs, source URLs, SHA-256, license texts
~/Documents/ZombieSlop/generated/       reproducible GLB and recorded/original audio exports
~/Documents/ZombieSlop/workspace/       assembled Godot project and .godot import cache
~/Documents/ZombieSlop/builds/          local playable exports; never uploaded publicly
~/Documents/ZombieSlop/tools/           pinned Godot, Blender, CLI utilities
```

Use the sibling asset checkout; verify its remote identity and **private visibility before every first upload**. The matching private commit and the initial LFS sources were pushed and verified during implementation; `git lfs fsck` passed. Pristine downloads still need a separate off-machine backup. Do not change billing or authorize paid LFS overages.

## Bootstrap

1. Install the engine and free official CLI tools:

   ```sh
   python3 scripts/install_tools.py --root "$HOME/Documents/ZombieSlop/tools"
   ```

2. Obtain Kenney City Kit (Suburban) 2.0 from [Kenney](https://kenney.nl/assets/city-kit-suburban). The reproducible downloader preserves its original archive, extracted files, license and checksum:

   ```sh
   python3 scripts/fetch_assets.py --originals "$HOME/Documents/ZombieSlop/downloads" --pack suburban
   ```

3. Install official Apple Silicon Blender 4.5.14 LTS from [Blender's official mirror](https://mirror.blender.org/release/Blender4.5/blender-4.5.14-macos-arm64.dmg). Place Blender.app under the external tools folder. The free ITHappy props have a separate final-product license; no paid assets are required.

4. Initialize or reuse the sibling private asset checkout. If it already has work, preserve it. Use an installed `git-lfs` path:

   ```sh
   python3 scripts/init_asset_repo.py --path ../zombie-slop-assets --lfs /path/to/git-lfs
   ```

   Git LFS tracking is committed before the first `.blend` commit. Do not put private asset LFS pointers in the public checkout.

5. Prefer the matching asset revision recorded in `docs/ASSETS.json`. The generator creates original assets and refuses existing `.blend` files. Export hand-edited sources separately; to deliberately recreate a checkpointed original, pass `--replace-existing`, optionally with `--only zombie` or `--only survivor`. Before substantial changes commit the working asset checkpoint. Preserve existing sources, then export into a separate output directory. To export the existing private checkout without changing any editable source:

   ```sh
   "$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
     --background --python scripts/export_assets.py -- \
     --assets ../zombie-slop-assets --out "$HOME/Documents/ZombieSlop/generated"
   ```

   Download the full free [Quaternius Zombie Apocalypse Kit](https://quaternius.com/packs/zombieapocalypsekit.html) through the author’s Google Drive folder. Preserve the complete ZIP and extract it under `downloads/zombie-apocalypse/extracted`, including `Zombie_Atlas.png`. The matching private checkpoint already includes adapted editable sources; reproduce those outputs after the original-assets export:

   ```sh
   "$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
     --background --python scripts/adapt_quaternius.py -- \
     --pack "$HOME/Documents/ZombieSlop/downloads/zombie-apocalypse/extracted" \
     --assets ../zombie-slop-assets --out "$HOME/Documents/ZombieSlop/generated" \
     --export-only
   ```

   Creating survivors also requires the preserved Survival pack under `downloads/survival/extracted/Blends` for the two added guns. To create the Quaternius working sources in a new private checkout, omit `--export-only`; existing working files are protected from overwrite. If creation/export fails partway through, rerun with `--resume`: it opens and re-exports existing sources without saving over them, and creates only missing ones. `--resume` and `--export-only` are mutually exclusive. After checkpointing existing sources, `--update-characters` deliberately rebuilds all four survivors from pristine inputs with the current weapons/poses and keeps Blender backups. It reuses existing non-survivor sources and creates missing ones; it does not require `--resume`. `--resume --repair-poses` instead rebakes existing survivor working copies without recreating their geometry. Neither can be combined with export-only. The adapter preserves author weapon sockets, packs the atlas into editable Blender files, adds same-rig gestures, joins the zombie atlas mesh, normalizes props, and bakes constraints during export.

   For a deliberately new original source set, use `create_assets.py` with a new external asset folder; replacing checkpointed originals requires `--replace-existing`. The exporter opens the matching private `.blend` files, joins only in memory, checks source hashes and synthesizes the original audio.

   Blender autosave is enabled in the generation process at two minutes and saved backup versions are set to two. For interactive work enable the same settings in Blender Preferences → Save & Load. Preserve the `.blend` files with editable rigs/actions/materials. The generator exports GLB explicitly with Y-up, eight animation actions, no texture dependencies for original models, and joins meshes for fewer draw calls. The swinging door keeps its pivot separate. Original deterministic audio is synthesized with seed 7; editable parameters are in the generator and private `recipe.json`.

The current checkpoint extends private `neighborhood/` working sources and `neighborhood/audio/`. Preserve the complete user-downloaded Nature and Survival archives, their extracted `Blends/` trees and CC0 licenses under `downloads/nature/` and `downloads/survival/`. Preserve the complete ITHappy `Apocalypse_Free.blend` and official license evidence under `downloads/ithappy/`. Its textures are packed; no FBX/GLB download is required. Only props are adapted, never ITHappy characters.

Re-export the matching private checkpoint after the original and Quaternius exports:

```sh
"$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
  --background --python scripts/prepare_neighborhood_assets.py -- \
  --home "$HOME/Documents/ZombieSlop" --assets ../zombie-slop-assets --export-only
"$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
  --background --python scripts/prepare_audio.py -- \
  --home "$HOME/Documents/ZombieSlop" --assets ../zombie-slop-assets --export-only
```

Neighborhood exports are checked against editable-source and GLB hashes. Audio exports are copied from hash-verified private derivatives, so re-export does not change the working checkpoint. Creating new copies uses `prepare_neighborhood_assets.py` without `--export-only`; it refuses existing files unless `--resume` is specified. The neighborhood script’s `--repair-poses` compatibility option affects all four survivors; use the Quaternius adapter’s `--resume --repair-poses` for all four survivors. After creation or pose repair, run `adapt_quaternius.py --export-only` again: it is the sole owner of the survivor export/manifest. Neighborhood export-only never exports or changes characters. `create_interiors.py` creates nine original house/furniture sources, refusing existing sources unless `--replace-existing` is explicit. `prepare_audio.py` creates a new private audio checkpoint from the downloaded CC0 recordings; Ogg decoding uses Blender’s audio library. These are normal Blender transformations, not image-generation inputs.

The private `district/` checkpoint adds six original building sources and sixteen original furnishings/supply models. The public `game/building_plans.json` and private recipe must agree; meshes and gameplay collision consume the same dimensions. Re-export the matching checkpoint and original engine loop before assembly:

```sh
"$HOME/Documents/ZombieSlop/tools/Blender.app/Contents/MacOS/Blender" \
  --background --python scripts/create_district.py -- \
  --assets ../zombie-slop-assets --home "$HOME/Documents/ZombieSlop" --export-only
python3 scripts/create_vehicle_audio.py --assets ../zombie-slop-assets \
  --home "$HOME/Documents/ZombieSlop" --export-only
python3 scripts/prepare_zombie_audio.py --assets ../zombie-slop-assets \
  --home "$HOME/Documents/ZombieSlop" --export-only
```

The zombie audio checkpoint uses artisticdude's CC0 [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack). Preserve `zombies.zip`, all extracted recordings, license and provenance under `downloads/zombie-audio/`; extraction places WAV files in `extracted/zombies/`. Creation without `--export-only` makes three normalized mono derivatives once and refuses an existing checkpoint. Re-export checks hashes and copies derivatives without modifying their source. No sound files belong in the public repository.

Creation refuses existing district sources. `--update-buildings` explicitly rebuilds only the six original buildings from changed plans and keeps Blender backups; props stay preserved. Neighborhood `--resume --update-props NAME...` deliberately rebuilds named adapted props and keeps backups. Export-only modes do not save editable sources. Original engine regeneration requires `--replace-existing`; preserve an external backup before using it. The mossy log retains uniform author proportions. The new raft, paddle and special chest derive from the existing downloaded packs. The engine loop is deterministic original audio, with a private parameter/hash recipe.

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
./scripts/run.sh -- --verify-load
./scripts/run.sh -- --inspection  # actual physics room walks and multi-angle screenshots
./scripts/run.sh -- --manual-test  # direct controls, separate save, preferences not written
```

The first three produce only **local external builds**, including their embedded assets. They must not be added to the public repository, LFS, GitHub releases, or CI artifacts. macOS exports are ad-hoc signed for local use, not notarized. Windows/Linux are cross-exportable; run them on their respective hardware before marking them tested. Steam Deck controls and Android are targets, not verified platforms.

A ten-minute benchmark is included in the exported binary:

```sh
"$HOME/Documents/ZombieSlop/builds/Zombie Slop.app/Contents/MacOS/Zombie Slop" -- --benchmark
```

It runs at 1280×800, uncapped, with shadows, 18 living zombies and 50 placed objects. Add `--benchmark-low` after `--benchmark` to disable sun shadows, `--benchmark-capped` for real 60 FPS pacing, or `--benchmark-short` for a 60-second diagnosis. Run it alone, without another graphical test. The ten-minute run repeats eight 37.5-second sections twice and measures actual graphical frame cadence. The eight views include the forest/river and real vehicle acceleration. Test modes use separate saves, neutralize damage during profiling and replenish ammo during the shooting segment. Stress-mode enemy health stays high to retain eighteen living enemies throughout all sections. They do not establish physical controller or human playtest coverage. JSON metrics and PNGs go under the game's user data `verification/` directory or `ZOMBIE_REPORT_DIR`. Headless runs never count as rendering benchmarks. Run `--verify-load` in a fresh process after `--integration` to compare the exact saved base and contents against the prior process's expected arrangement.

For an OpenGL comparison on macOS, put `--rendering-method gl_compatibility --rendering-driver opengl3` before the separating `--`. Metal's uncapped setting does not guarantee presentation above the display refresh rate; compare measured frame times and report the actual driver, cap and VSync state. Normal gameplay starts capped at 60 FPS, with VSync; the settings menu can disable the cap or sun shadows.

## Backups and matching revisions

- Back up the entire pristine downloads folder (including archives, licenses and SOURCE.json checksums) to a user-selected external drive or existing cloud backup.
- Back up the private repository with its `.git/lfs/objects` **and** working source files. Git pointers alone cannot restore binary sources. Maintain a pushed private remote and a separate backup of the originals.
- `scripts/backup.py --destination PATH --assets PATH` creates a complete timestamped local archive for copying to that backup location. It never selects or configures a paid service.
- For private pushes use normal Git/Git LFS authentication; verify the repository is private, `git lfs fsck`, push the commit and LFS objects, then verify both. `git lfs ls-files --size` gives local source sizes; inspect GitHub's account LFS usage before enabling ongoing uploads. A rejected or unpushed push is not a backup.
- Record `git rev-parse HEAD` from the private asset checkout in the public asset manifest after local Blender/Godot inspection and tests. Never apply public MIT to third-party assets.
- Before every public push run `python3 scripts/check_source.py`, `git diff --cached --stat` and inspect the full staged file list. Never upload credentials or asset archives.

## Selected pack status

All three Quaternius packs are installed from complete user-provided downloads and carry CC0 licenses. Their pristine archives, source checksums and license texts remain external. Zombie Apocalypse supplies all four survivors, four zombie variants, firearm/melee meshes, all six vehicles, street surfaces, chest and household/outdoor props. Survival supplies the revolver, compact shotgun, radio, backpack, campfire and tent as well as small props; Ultimate Nature supplies varied trees, shrubs, grass, flowers, logs and rocks.

ITHappy Apocalypse Free is installed from the user’s Blender download. Packed textures were inspected and preserved. Selected non-character props are adapted: guitar, grill, stove, roadside barrier/sign and wrecked car. Its [free usage policy](https://ithappystudios.com/free-asset-usage-policy/) and [one-time licence agreement](https://ithappystudios.com/one-time-purchase-licence-agreement/) were preserved with the downloads and private working sources. Runtime use is within the final game; no as-is public asset redistribution is performed. The user-owned private checkout is an internal working copy/backup. The complex dirt/blood shader is simplified to the packed color atlas and rough PBR material for glTF portability. No ITHappy characters are used.

Kenney City Kit remains preserved with the original downloads but its closed building shells are no longer assembled. Original editable bungalows with four siding palettes, roof/window/porch details, room partitions and searchable furniture replace them. Recorded CC0 gunshots/reloads from OpenGameArt and Kenney’s Impact Sounds replace the earlier synthetic effects; footsteps vary by surface and sample. Quiet original filtered wind replaces the pitched ambient hum. URLs, authors, checksums, transformations and licenses are recorded in the asset manifest and private audio recipe.
