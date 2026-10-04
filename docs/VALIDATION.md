# Current validation — iteration three

Local target: Apple M3 MacBook Air, 16 GB, Godot 4.7.2 Mobile / Metal at 1280×800. Default settings retain the 60 FPS cap, VSync and shadows off. Steam Deck and physical controller feel remain unverified.

**87 source checks and 141 native exported graphical checks pass.** New coverage includes right-handed pistol use, right firing-hand position and support-hand/foregrip proximity on ten rifle/shotgun locomotion/aim/fire poses plus separate reload poses, held-sprint exhaustion/recovery, wheel and Shift-wheel rotation, snapped 90-degree wheel/keyboard rotation, reachability of all six collectible furnishings, fourteen accessible homes and 42 searchable containers, real contents-menu pickup callbacks, idempotent stock collection, wall/glass line of sight, food consumption without waste, partial/full container persistence, gradual zombie replacement and the eighteen-live-enemy cap. Version-one and version-two progress migrate without losing weapons or base arrangements. Actual combat, step-up traversal, floor/table/shelf building, spending/refunds and storage continue to pass. The exported app exited without runtime errors.

The supporting hand is sampled through an independent world-space target before baking; a same-armature target dependency and an incomplete selected-bones bake were caught and repaired by graphical pose tests. Matching editable sources retain the author clips, right-handed rig transform, gun sockets and twelve new long-gun actions. The colored house material values are converted from the intended sRGB palette into linear PBR values; source/collision axis alignment and porch support were verified through actual movement/placement.

The larger 248m neighborhood contains fourteen furnished bungalows with pitched roofs, window openings/glass, room partitions, porches and paths. Roofs hide while the player is indoors. New home fixtures yield to saved player placements. Supplies are in drawers/fridges/safes, and selected furnishings remain recoverable interior objects. Floating world labels and roadside supply crates are removed; mounted number plates identify houses. Nature/Survival and selected non-character ITHappy props are integrated. Recorded CC0 shots/reloads and varied surface footsteps replace synthetic effects. No purchased capacity, public assets or CI binary artifacts are used.

The existing user saves were copied to the external pre-iteration-three backup folder. Integration and performance modes use separate save files. Earlier playable apps and original/pristine asset downloads remain preserved. Private editable assets and license evidence are checkpointed separately; see ASSETS.json for the matching revision and upload evidence.

PR #2 was explicitly approved for merge by the user and squash-merged as `ef4b378f59b3c18976d9a8054a74748c83e54eba`. That override does not automatically apply to the next PR. The new PR remains subject to the current-head review/check gate described below.

The earlier measurements below are historical results on smaller maps, not performance claims for this iteration.

## Iteration-three sustained performance

The exported native Metal build completed **600.001 seconds** at **1280×800**, with the **60 FPS cap and VSync on, shadows off**, **18 living zombies throughout every section**, and **50 placed objects**. No other graphical game/test was run concurrently.

- Average: **59.97 FPS**; p50/p95/p99: **16.682 / 18.099 / 18.996 ms**.
- **1% low: 50.27 FPS**; maximum **29.282 ms**.
- **95 / 35,984 frames exceeded 20 ms; zero exceeded 33.333 ms**.
- 18,362 frames exceeded the literal 16.667 ms threshold. A capped refresh-paced run has timing jitter around that boundary; the result demonstrates near-60 pacing with brief dips, **not perfectly sustained 60 FPS**.

| Scene (100 seconds total, repeated in two laps) | Average FPS | p99 ms | 1% low FPS |
|---|---:|---:|---:|
| Street traversal | 59.98 | 18.370 | 53.01 |
| Populated supply view | 59.97 | 19.219 | 50.93 |
| Interior | 59.97 | 18.390 | 53.15 |
| Shooting encounter | 59.97 | 19.191 | 50.62 |
| 50-piece furnished base | 59.97 | 20.075 | 45.88 |
| Placement preview | 59.97 | 18.452 | 52.73 |

The furnished base has the weakest frame-time tail. Its sampled physics median was 4.43 ms, with an 11.03 ms maximum; median draws were 81. Populated-view physics median was 4.64 ms. Process-monitor values include refresh/presentation pacing and cannot be treated as isolated CPU cost. Instanced terrain/vegetation, static settled items, staggered AI and offscreen animation culling keep the expanded scene within the current prototype budget. The next performance priority is the furnished-base/AI physics tail. The run does not establish Steam Deck performance. Subsequent review fixes moved one chair out of a counter collider, repaired snapped preview rotation and strengthened asset-tool diagnostics. The long run predates that chair relocation; the final app is covered by the integration/relaunch checks.

A final 60-second exported check after the review fixes measured **59.98 FPS**, p95/p99 **18.094 / 18.920 ms**, **1% low 50.41 FPS**, maximum **23.535 ms**, and **zero frames above 33.333 ms**. Its separate report is under `verification/iteration3-final-check/`; the ten-minute report is preserved.

The final scene also passed **141 exported graphical integration checks**, followed by **six fresh-process quit/relaunch checks**, without runtime errors. Reports/screenshots remain outside both repositories under external `verification/iteration3/`. Desktop tools additionally verified the native New Neighborhood click and Escape pause input; this is direct automated desktop interaction, not physical controller coverage. A direct-test autosave was restored from the pre-test backup and byte-verified. The new `--manual-test` flag isolates future manual saves and prevents preference writes.

# Prior iteration validation

Local target: 13-inch MacBook Air, Apple M3 (8 CPU / 10 GPU cores), 16 GB RAM. Godot 4.7.2. Iteration one used Compatibility OpenGL 4.1; iteration two uses Mobile / native Metal on macOS after the comparisons below. Other platforms retain Compatibility. No hardware serial identifiers are retained here.

- Source-only parser checks and **82 transaction/save checks pass** without external assets. They cover pickup identity, invalid/cancelled placement, moving/recovery, construction spending/refunds, storage conservation, duplicate IDs, malformed saves, precision, and backup recovery.
- **76 graphical integration checks pass** in the native exported Metal-default game. Imported clips, movement, aim camera, pistol/rifle/shotgun raycast damage, reload, switching/model visibility, damage/healing/death/restart, world collection, floor/table/shelf placement, rotation/cancel/reposition/recovery, construction, door collision, actual AI barricade damage, storage and arranged-base save/load are exercised. A separate graphical process passes six quit/relaunch checks for exact arrangement, identities and chest contents. Start/pause/settings/death screens are captured from the rendered viewport. These are automated graphical tests, not a claim of physical keyboard/controller human playtesting.
- A world fence crossing the home interior was found by the movement test and relocated to yard boundaries. Vegetation and repeated static map boxes are batched with MultiMesh and original meshes use fewer surfaces. Static base objects do not process every frame.
- Native universal macOS, Linux x86_64 and Windows x86_64 exports have been produced locally, outside source and asset repositories. macOS is the runtime-tested platform. Linux/Windows are cross-exported and **not runtime-tested**; Steam Deck and Android remain unverified.
- The first ten-minute native exported benchmark (1280×800, uncapped, shadows on, 18 zombies, 50 objects) averaged 185.90 FPS; p50/p95/p99 were 3.108/21.648/24.431ms, 1% low 38.27 FPS, maximum 126.312ms. 10,432 of 111,540 frames exceeded 16.667ms and six exceeded 33.333ms. This **misses sustained 60 FPS**. The final ten-minute low-preset run (same hardware/resolution, uncapped, shadows off, 18 zombies, 50 objects) averaged **251.69 FPS**; p50/p95/p99 were **2.206/18.544/22.011ms**, **1% low 42.80 FPS**, maximum 93.892ms. 8,550 of 151,014 frames (5.66%) exceeded 16.667ms and four exceeded 33.333ms. Low improves the distribution but **still misses sustained 60 FPS**. The remaining measured bottleneck is process/render time in populated street views; sampled physics time there is generally below 1ms. Further reducing visible draw surfaces and skinned-character rendering is the next performance priority. UI toast wrapping and download-tool changes made after this run do not change the map/render settings. The first report incorrectly labeled exported=false because the standalone feature flag is absent in this template; the launched native app was independently verified, and the detector now checks absence of the editor feature.
- Full user interaction through desktop automation is limited: macOS Accessibility trust was false. Screen capture was permitted; actual frames were inspected through in-game viewport capture. Direct targeted keystroke delivery did not establish successful manual desktop-control coverage. No physical gamepad was attached; synthetic gamepad input verifies the Y construction binding, not physical controller feel.
- Quaternius Zombie Apocalypse Kit characters, three weapons, a pickup truck and a chest are now installed. Original construction/furniture/vegetation remain while Survival/Nature manual downloads are pending. ITHappy requires account checkout. Kenney suburban building assets are installed with their CC0 license and required colormap texture. Only two house interiors are accessible.
- Zombie positions repopulate on load; inventories, collected identities, decorations, construction health/open state, chest contents, objective state and settings persist. The first controller uses simple animation transitions rather than layered locomotion/aim blending. Open door-leaf collision is simplified. Material removal refunds are intentionally full; destruction returns no building materials.

Before the pack integration, all 21 original models and seven audio clips were reproduced from the pushed private sources without changing any source hash. The iteration-two suite checks the new pack assets; its seven editable working copies were also re-exported without changing either pristine or editable source hashes. Asset-generator overwrite refusal and initialization with unrelated work were also verified. The Quaternius adapter’s resume mode was tested in a disposable partial checkout: an existing survivor stayed byte-identical, six missing sources were created, and all seven exports completed. Default creation still refused existing sources, and conflicting resume/export-only flags were rejected.

Local screenshot/report files are under the game's application-support `verification/` folder. They remain outside public Git, releases and CI artifacts. The matching private asset revision and push evidence are in `ASSETS.json`.

PR #1 received an initial CodeRabbit review; its eight findings were fixed, replied to and resolved. The final head was rate-limited. The user explicitly approved merging that PR, which was squash-merged on 2026-10-03 as `479bb7651e25dddde9ce2d1793a9b99e289ff9fb`. That explicit override applies to PR #1. No paid review capacity or billing change was enabled.

Public PR merge requires an affirmative current-head CodeRabbit review, all required checks, no remaining actionable/human blockers, two fresh clean polls at least 60 seconds apart, and an immediate expected-head merge check. Silence or a skipped/rate-limited review does not satisfy this requirement.

## Iteration-one low-preset section results

| Scene (100 seconds each) | Average FPS | p95 ms | p99 ms | 1% low FPS |
|---|---:|---:|---:|---:|
| 50-piece furnished base | 260.87 | 12.990 | 19.064 | 50.87 |
| interior | 379.02 | 4.471 | 6.413 | 91.73 |
| placement preview | 417.22 | 3.915 | 4.839 | 163.65 |
| populated supply view | 90.43 | 20.864 | 22.115 | 42.66 |
| shooting encounter | 212.03 | 19.769 | 20.784 | 45.57 |
| street traversal | 150.57 | 22.977 | 24.074 | 39.46 |

The route script changes locations between sections; section-switch spikes are included rather than discarded. Neither automated run is a claim of a human ten-minute play session. The final exported integration/relaunch checks completed without runtime errors or shutdown leaks. Earlier test runs exposed an ambient-audio shutdown leak; stopping and clearing playback fixed it.

## Iteration two

The survivor is Quaternius Matt and enemies are Zombie Basic. The original pack's firearm bone attachments are preserved; the game switches pistol, rifle and shotgun meshes at their author sockets and uses fitted muzzle/grip points. Gun locomotion clips are reused, with same-rig Aim/Shoot/Reload gestures and baked constraints. Zombie eyelids and body share one atlas skin. Player and zombie capsules safely step up obstructions up to 30cm; full-height walls and low ceilings remain blocking. Camera follow uses interpolated body positions and an independent render-frame camera.

Weapon pickups, separate reserve ammo, independent magazines, switching, interrupted reloads, muzzle flashes and version-one save migration are covered by source/native tests. Selecting the current gun or cycling the sole owned gun preserves a reload; a model without an AnimationPlayer configures safely. The existing user's saves are preserved; automated runs use isolated files. Loading a progress save retains the current graphics preferences. The cap defaults to 60 FPS with VSync; uncapped mode is explicit profiling.

Profiling found wasted searches for unreachable interiors: outward cell rounding closed physical doorways on the navigation grid. Grid footprints now classify actual cell centers and static connected components reject impossible routes before A*. Tests require the path to reach the home interior rather than merely return a partial path. Off-screen zombie animation updates are culled while collision and AI remain active; animation updates run at physics cadence.

Short uncapped renderer diagnoses initially favored OpenGL throughput (738.94 versus Metal's 119.93 average FPS), but OpenGL still stalled up to 109.703ms. These 60-second camera arcs do not cover the full views. A native sample also showed OpenGL waiting in Apple's skinned-mesh transform-feedback path. The full ten-minute comparisons drove the macOS renderer choice:

| Ten-minute run | Average FPS | p95 / p99 ms | 1% low FPS | Maximum ms | Frames >20ms | Frames >33.33ms |
|---|---:|---:|---:|---:|---:|---:|
| Compatibility, cap 60 / VSync on | 59.97 | 18.624 / 20.208 | 44.11 | 138.175 | 413 / 35,980 (1.15%) | 5 |
| Mobile / Metal, cap disabled / VSync off | 59.97 | 17.989 / 19.232 | 49.05 | 25.723 | 177 / 35,984 (0.49%) | 0 |

Both runs used 1280×800, shadows off, 50 static pieces, and 18 enemies throughout six repeated sections. Despite `Engine.max_fps=0` and VSync disabled, this Metal run presented near 60 FPS; its cause was not isolated, so it is evidence about observed pacing, **not uncapped capacity**. The different pacing settings also limit the comparison. Metal had fewer long frames in the representative views and is selected only for macOS; Linux/Windows keep the broader Compatibility default. Initial cold shader/action stalls occurred in short diagnostics, and the later Metal run reused a warmed shader cache. These results do **not establish perfect sustained 60 FPS or Steam Deck performance**.

The full route reports remain external in the local builds folder as `iteration2-performance-capped.json` and `iteration2-performance-metal-uncapped.json`. Their scene/assets match public source `a2f82f9` with asset `b19c671`; subsequent changes align the truck collider, stabilize gun cycling, improve HUD text/tests and select the measured Mac renderer, without changing render geometry. Final native tests validate the actual project-selected Metal driver and default 60 FPS cap. A final 60-second **capped Metal** check measured 60.00 average FPS, p95/p99 18.845/19.769ms, 1% low 47.42 FPS, maximum 45.687ms, and one frame above 33.33ms. It confirms the cap, but still contains a stutter. Its report is `iteration2-performance-metal-capped-short.json`. The final verbose integration/relaunch/short benchmark runs had no shutdown leaks; two imported RGB textures are converted to supported RGBA by Metal.
