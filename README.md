# Zombie Slop

An original offline, third-person zombie survival prototype in an overgrown suburban neighborhood. Scavenge supplies and furnishings, bring them home, freely arrange a base, and build defenses.

**Godot 4.7.2 · GDScript · Metal on macOS, Compatibility elsewhere · MIT original code.** Assets, Blender sources, downloads, imports, screenshots and builds are kept entirely outside this public repository.

[Local setup and asset protection](docs/SETUP.md) · [Controls and gameplay](docs/PLAY.md) · [Asset manifest](docs/ASSETS.json) · [Validation and limitations](docs/VALIDATION.md)

```sh
./scripts/run.sh             # assemble from separately installed assets, then launch
./scripts/build.sh macOS     # export a local native macOS build
```

A fresh source clone requires the external asset setup. The script reports missing files and sources clearly. Quaternius Zombie Apocalypse characters, three firearms, pickup trucks and chests are installed from a complete manual download. Kenney provides suburban building shells; original construction, furniture and vegetation remain. Survival/Nature are pending manual downloads and ITHappy is pending license/account setup. The exact asset sources and matching private checkpoint are documented.

The starter objective asks you to collect supplies and a fern, return home, place your find, and build a barricade or chest. Then keep playing the sandbox. Six collectible furniture/decor types and six construction recipes use transactional placement, recovery/refunds, storage and local persistence.

Public workflow uses feature branches and PRs, with current-head CodeRabbit review required before merging. Local development and playtesting do not imply a GitHub review or merge occurred.
