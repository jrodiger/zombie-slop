# Prototype validation

Local target: 13-inch MacBook Air, Apple M3 (8 CPU / 10 GPU cores), 16 GB RAM. Godot 4.7.2, Compatibility OpenGL 4.1 on Metal. No hardware serial identifiers are retained here.

- Source-only parser checks and **71 transaction/save checks pass** without external assets. They cover pickup identity, invalid/cancelled placement, moving/recovery, construction spending/refunds, storage conservation, duplicate IDs, malformed saves, precision, and backup recovery.
- **53 graphical integration checks pass** in the assembled game. Imported clips, movement, aim camera, raycast shots, reload, damage/healing/death/restart, two-world-object collection, floor/table/shelf placement, rotation/cancel/reposition/recovery, construction, door collision, actual AI barricade damage, storage and arranged-base save/load are exercised. A separate graphical process passes six quit/relaunch checks for exact arrangement, identities and chest contents. Start/pause/settings/death screens are captured from the rendered viewport. These are automated graphical tests, not a claim of physical keyboard/controller human playtesting.
- A world fence crossing the home interior was found by the movement test and relocated to yard boundaries. Vegetation and repeated static map boxes are batched with MultiMesh and original meshes use fewer surfaces. Static base objects do not process every frame. No renderer change was made.
- Native universal macOS, Linux x86_64 and Windows x86_64 exports have been produced locally, outside source and asset repositories. macOS is the runtime-tested platform. Linux/Windows are cross-exported and **not runtime-tested**; Steam Deck and Android remain unverified.
- The first ten-minute native exported benchmark (1280×800, uncapped, shadows on, 18 zombies, 50 objects) averaged 185.90 FPS; p50/p95/p99 were 3.108/21.648/24.431ms, 1% low 38.27 FPS, maximum 126.312ms. 10,432 of 111,540 frames exceeded 16.667ms and six exceeded 33.333ms. This **misses sustained 60 FPS**. The final ten-minute low-preset run (same hardware/resolution, uncapped, shadows off, 18 zombies, 50 objects) averaged **251.69 FPS**; p50/p95/p99 were **2.206/18.544/22.011ms**, **1% low 42.80 FPS**, maximum 93.892ms. 8,550 of 151,014 frames (5.66%) exceeded 16.667ms and four exceeded 33.333ms. Low improves the distribution but **still misses sustained 60 FPS**. The remaining measured bottleneck is process/render time in populated street views; sampled physics time there is generally below 1ms. Further reducing visible draw surfaces and skinned-character rendering is the next performance priority. UI toast wrapping and download-tool changes made after this run do not change the map/render settings. The first report incorrectly labeled exported=false because the standalone feature flag is absent in this template; the launched native app was independently verified, and the detector now checks absence of the editor feature.
- Full user interaction through desktop automation is limited: macOS Accessibility trust was false. Screen capture was permitted; actual frames were inspected through in-game viewport capture. Direct targeted keystroke delivery did not establish successful manual desktop-control coverage. No physical gamepad was attached; synthetic gamepad input verifies the Y construction binding, not physical controller feel.
- Original low-poly characters/props temporarily replace unavailable selected Quaternius packs (Drive quota exceeded). ITHappy requires account checkout. Kenney suburban building assets are installed with their CC0 license and required colormap texture. Only two house interiors are accessible.
- Zombie positions repopulate on load; inventories, collected identities, decorations, construction health/open state, chest contents, objective state and settings persist. The first controller uses simple animation transitions rather than layered locomotion/aim blending. Open door-leaf collision is simplified. Material removal refunds are intentionally full; destruction returns no building materials.

All 21 original models and seven audio clips were reproduced from the pushed private sources without changing any source hash. The final exported macOS integration suite rechecks the reproduced assets. Asset-generator overwrite refusal and initialization with unrelated work were also verified.

Local screenshot/report files are under the game's application-support `verification/` folder. They remain outside public Git, releases and CI artifacts. The matching private asset revision and push evidence are in `ASSETS.json`.

PR #1 received an initial CodeRabbit review, and all eight inline findings were evaluated, fixed, replied to and resolved. The updated head is **rate-limited**, so the PR stays open and unmerged; a successful status alone is not affirmative review completion. No paid review capacity or billing change was enabled.

Public PR merge requires an affirmative current-head CodeRabbit review, all required checks, no remaining actionable/human blockers, two fresh clean polls at least 60 seconds apart, and an immediate expected-head merge check. Silence or a skipped/rate-limited review does not satisfy this requirement.

## Final low-preset section results

| Scene (100 seconds each) | Average FPS | p95 ms | p99 ms | 1% low FPS |
|---|---:|---:|---:|---:|
| 50-piece furnished base | 260.87 | 12.990 | 19.064 | 50.87 |
| interior | 379.02 | 4.471 | 6.413 | 91.73 |
| placement preview | 417.22 | 3.915 | 4.839 | 163.65 |
| populated supply view | 90.43 | 20.864 | 22.115 | 42.66 |
| shooting encounter | 212.03 | 19.769 | 20.784 | 45.57 |
| street traversal | 150.57 | 22.977 | 24.074 | 39.46 |

The route script changes locations between sections; section-switch spikes are included rather than discarded. Neither automated run is a claim of a human ten-minute play session. The final native run and final exported integration/relaunch checks completed without runtime errors or shutdown leaks. Earlier test runs exposed an ambient-audio shutdown leak; stopping and clearing playback fixed it.
