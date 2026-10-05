# Zombie Slop

An original offline, third-person zombie survival prototype in an overgrown suburban neighborhood. Scavenge supplies and furnishings, bring them home, freely arrange a base, and build defenses.

**Godot 4.7.2 · GDScript · Metal on macOS, Compatibility elsewhere · MIT original code.** Assets, Blender sources, downloads, imports, screenshots and builds are kept entirely outside this public repository.

[Local setup and asset protection](docs/SETUP.md) · [Controls and gameplay](docs/PLAY.md) · [Asset manifest](docs/ASSETS.json) · [Validation and limitations](docs/VALIDATION.md)

```sh
./scripts/run.sh             # assemble from separately installed assets, then launch
./scripts/build.sh macOS     # export a local native macOS build
```

A fresh source clone requires the external asset setup. The script reports missing files and sources clearly. Layered locomotion keeps walking and running active while reloading or firing; firearms use relaxed right-handed carry and fitted two-hand aiming poses. Recorded positional zombie growls, varied footsteps and louder speed-responsive engines add nearby sound cues. Four selectable Quaternius survivors, four zombie variants, nine weapons, Survival props, Nature vegetation and selected ITHappy Apocalypse Free props are installed from the user’s full downloads. Four furnished home types provide sixteen accessible houses, including two floors with usable stairs, across a 328m neighborhood with hills, a river, bridges, camps and rural farmsteads. Search drawers, refrigerators, safes and chests for varied supplies and guaranteed weapon caches, with model pictures beside loot names. A gas station/auto shop, grocery and convenience store add destinations. Drive six initially unarmored cars with speed-responsive engine sound, then fit collected armor parts; wrecks remain scenery. The exact asset sources, licenses and matching private checkpoint are documented.

The starter objective asks you to collect supplies and a fern, return home, place your find, and build a barricade or chest. Then keep playing the sandbox. Tab opens an inventory with equipment, supplies and character selection. Eight collectible furniture/decor types and six construction recipes use transactional placement, recovery/refunds, storage and local persistence.

Public workflow uses feature branches and PRs, with current-head CodeRabbit review required before merging. Local development and playtesting do not imply a GitHub review or merge occurred.

For personal Android/Pixel and Steam Deck installation, touch/gamepad controls and transfer packages, see [device instructions](docs/DEVICES.md). Store publishing is unnecessary.
