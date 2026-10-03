# Prototype validation

Local target: 13-inch MacBook Air, Apple M3 (8 CPU / 10 GPU cores), 16 GB RAM. Godot 4.7.2, Compatibility OpenGL 4.1 on Metal. No hardware serial identifiers are retained here.

- Source-only parser checks and **82 transaction/save checks pass** without external assets. They cover pickup identity, invalid/cancelled placement, moving/recovery, construction spending/refunds, storage conservation, duplicate IDs, malformed saves, precision, and backup recovery.
- **69 graphical integration checks pass** in the assembled game. Imported clips, movement, aim camera, raycast shots, reload, damage/healing/death/restart, two-world-object collection, floor/table/shelf placement, rotation/cancel/reposition/recovery, construction, door collision, actual AI barricade damage, storage and arranged-base save/load are exercised. The prior separate graphical process passed six quit/relaunch checks for exact arrangement, identities and chest contents. Start/pause/settings/death screens are captured from the rendered viewport. These are automated graphical tests, not a claim of physical keyboard/controller human playtesting.
- A world fence crossing the home interior was found by the movement test and relocated to yard boundaries. Vegetation and repeated static map boxes are batched with MultiMesh and original meshes use fewer surfaces. Static base objects do not process every frame. No renderer change was made.
- Native universal macOS, Linux x86_64 and Windows x86_64 exports have been produced locally, outside source and asset repositories. macOS is the runtime-tested platform. Linux/Windows are cross-exported and **not runtime-tested**; Steam Deck and Android remain unverified.
- The first ten-minute native exported benchmark (1280×800, uncapped, shadows on, 18 zombies, 50 objects) averaged 185.90 FPS; p50/p95/p99 were 3.108/21.648/24.431ms, 1% low 38.27 FPS, maximum 126.312ms. 10,432 of 111,540 frames exceeded 16.667ms and six exceeded 33.333ms. This **misses sustained 60 FPS**. The final ten-minute low-preset run (same hardware/resolution, uncapped, shadows off, 18 zombies, 50 objects) averaged **251.69 FPS**; p50/p95/p99 were **2.206/18.544/22.011ms**, **1% low 42.80 FPS**, maximum 93.892ms. 8,550 of 151,014 frames (5.66%) exceeded 16.667ms and four exceeded 33.333ms. Low improves the distribution but **still misses sustained 60 FPS**. The remaining measured bottleneck is process/render time in populated street views; sampled physics time there is generally below 1ms. Further reducing visible draw surfaces and skinned-character rendering is the next performance priority. UI toast wrapping and download-tool changes made after this run do not change the map/render settings. The first report incorrectly labeled exported=false because the standalone feature flag is absent in this template; the launched native app was independently verified, and the detector now checks absence of the editor feature.
- Full user interaction through desktop automation is limited: macOS Accessibility trust was false. Screen capture was permitted; actual frames were inspected through in-game viewport capture. Direct targeted keystroke delivery did not establish successful manual desktop-control coverage. No physical gamepad was attached; synthetic gamepad input verifies the Y construction binding, not physical controller feel.
- Quaternius Zombie Apocalypse Kit characters, three weapons, a pickup truck and a chest are now installed. Original construction/furniture/vegetation remain while Survival/Nature manual downloads are pending. ITHappy requires account checkout. Kenney suburban building assets are installed with their CC0 license and required colormap texture. Only two house interiors are accessible.
- Zombie positions repopulate on load; inventories, collected identities, decorations, construction health/open state, chest contents, objective state and settings persist. The first controller uses simple animation transitions rather than layered locomotion/aim blending. Open door-leaf collision is simplified. Material removal refunds are intentionally full; destruction returns no building materials.

Before the pack integration, all 21 original models and seven audio clips were reproduced from the pushed private sources without changing any source hash. The iteration-two suite checks the new pack assets; its seven editable working copies were also re-exported without changing either pristine or editable source hashes. Asset-generator overwrite refusal and initialization with unrelated work were also verified.

Local screenshot/report files are under the game's application-support `verification/` folder. They remain outside public Git, releases and CI artifacts. The matching private asset revision and push evidence are in `ASSETS.json`.

PR #1 received an initial CodeRabbit review; its eight findings were fixed, replied to and resolved. The final head was rate-limited. The user explicitly approved merging that PR, which was squash-merged on 2026-10-03 as `479bb7651e25dddde9ce2d1793a9b99e289ff9fb`. That explicit override applies to PR #1. No paid review capacity or billing change was enabled.

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

## Iteration two

The survivor is Quaternius Matt and enemies are Zombie Basic. The original pack's firearm bone attachments are preserved; the game switches pistol, rifle and shotgun meshes at their author sockets and uses fitted muzzle/grip points. Gun locomotion clips are reused, with same-rig Aim/Shoot/Reload gestures and baked constraints. Zombie eyelids and body share one atlas skin. Player and zombie capsules safely step up obstructions up to 30cm; full-height walls and low ceilings remain blocking. Camera follow uses interpolated body positions and an independent render-frame camera.

Weapon pickups, separate reserve ammo, independent magazines, switching, interrupted reloads, muzzle flashes and version-one save migration are covered by source/native tests. The existing user's saves are preserved; automated runs use isolated files. Loading a progress save retains the current graphics preferences. The cap defaults to 60 FPS with VSync; uncapped mode is explicit profiling.

Profiling found wasted searches for unreachable interiors: outward cell rounding closed physical doorways on the navigation grid. Grid footprints now classify actual cell centers and static connected components reject impossible routes before A*. Tests require the path to reach the home interior rather than merely return a partial path. Off-screen zombie animation updates are culled while collision and AI remain active; animation updates run at physics cadence.

Renderer comparison on the same optimized exported scene (60 seconds each, 1280×800, uncapped, shadows off, 18 initial zombies, 50 pieces): Compatibility averaged 738.94 FPS, p95/p99 2.918/5.577ms, 1% low 135.35 FPS, maximum 109.703ms with four frames above 33.33ms. Native Metal Mobile averaged 119.93 FPS, p95/p99 11.934/12.779ms, 1% low 73.48 FPS, maximum 33.115ms. These are short diagnostic runs, not sustained or Deck claims. Compatibility remains the default based on this comparison. Initial long frames still occur in some scene/action transitions; short capped averages near 60 FPS do not prove perfect pacing.

Final ten-minute capped results are recorded after the sustained run completes.
