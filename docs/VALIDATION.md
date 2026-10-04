# Current validation — iteration five

Target: Apple M3 MacBook Air, 16 GB; Godot 4.7.2 Mobile / Metal, 1280×800. Normal play retains a 60 FPS cap, VSync and shadows off. Steam Deck and physical controller feel remain unverified.

## Gameplay and actual model inspection

**106 source/save checks and 741 exported graphical checks pass**, followed by **six fresh-process save/relaunch checks**. Coverage includes the prior scavenging/free placement/storage/combat loop, all four survivors and nine weapons, six intact drivable cars, armor transactions/model persistence, looping engine pitch/pause/exit behavior, live survivor previews, road/feet support, every solid furnishing's exported bounds, fixture overlap checks, independently persistent shop stock and clear house gates. A saved position beyond the old map limit reloads on the expanded rural road. Supported upstairs and road walking use the actual player capsule and collision bodies.

The exported room inspection reached **48 actual physics targets with zero failures** across a cottage, townhouse, two neighborhood/rural farmhouses and all three shops. Captures cover entrances, kitchen/bedroom/bathroom views, upstairs landings and stair descent, roof undersides and opened cabinet fronts. Six guns have lowered/aim/fire/reload captures from both sides, with additional reload samples. All four survivor rigs received the inspected calibration. These are screenshots and scripted movement in a rendered exported native game, not human playtesting of every room or camera angle.

Inspection exposed and corrected collectible furniture blocking a bedroom door/landing, a tree intersecting the camp tent, raw raft/oar units far larger than game units, a radio/bottle overlap and incoherent independent finger-root rotation. The raft/oars now use uniform sizing, the mossy log retains author proportions, and vegetation has explicit yard/path/camp/riverbank clearances. Gun poses keep palm/thumb/index roots coherent, fit oversized weapons once and bring the support target within arm reach. Reload gestures lower the weapon and move the support hand from belt to receiver and back, timed to gameplay reload duration. They remain stylized baked poses, without individual-finger runtime IK or detachable magazines.

The user's real version-four save passed read-only migration, preserving survivor choice, inventory counts, collected identities and weapon magazines. Current saves/settings were copied to external `backups/pre-iteration5-saves/` and remain byte-identical. All tests use separate save names. Desktop automation was unavailable because macOS was locked and automatic unlocking failed; an unlock request remained pending. Actual native viewport rendering and engine-scripted interaction were available and verified. No direct desktop/audio-listening or physical-controller coverage is claimed for this round.

## Sustained performance

The exported Mobile / Metal candidate completed **600.009 seconds** at **1280×800**, with a **60 FPS cap and VSync on, shadows off**, **18 living zombies in every section** and **50 placed objects**. Eight equally timed views repeat twice, with actual traversal, shots, camera pans, placement preview and vehicle acceleration. No other graphical game or Blender session ran concurrently; lightweight source/documentation checks continued. macOS remained locked, so this is evidence about the exported viewport workload and cadence rather than direct foreground desktop interaction.

- Average **59.97 FPS**; p50/p95/p99 **16.681 / 17.932 / 18.509 ms**.
- **1% low 52.98 FPS**; maximum **23.037 ms**.
- **12 of 35,984 frames exceeded 20 ms; none exceeded 33.333 ms**.
- 18,476 frames exceeded the literal 16.667 ms boundary, including capped presentation jitter. This supports near-60 pacing with brief dips, not perfect 60 FPS or Steam Deck capacity.

| View (two laps) | Average FPS | p99 ms | 1% low FPS |
|---|---:|---:|---:|
| 50-piece furnished base | 59.97 | 18.420 | 53.54 |
| driving | 59.97 | 18.557 | 52.75 |
| forest and river | 59.97 | 18.129 | 53.87 |
| interior | 59.97 | 18.419 | 53.03 |
| placement preview | 59.97 | 18.241 | 53.72 |
| populated supply view | 59.97 | 18.681 | 52.68 |
| shooting encounter | 59.97 | 18.674 | 52.42 |
| street traversal | 59.97 | 18.509 | 52.84 |

Sampled physics medians range from 1.88 to 4.86 ms, with a 8.69 ms largest sampled frame. Process monitors include presentation waiting and do not isolate render CPU cost. The report and native viewport capture remain external under `verification/iteration5/performance/`. Later changes improve menu weapon-icon framing, initialize the zombie idle pose before play and replace two roadside poster meshes with small mounted street signs. A final screenshot prompted clearing the forecourt of vegetation. House paths now stop at the near road edge and the fuel forecourt joins the same asphalt mesh; its street-to-forecourt driving check passes. Building interiors, vegetation density, audio and graphics settings are unchanged. A final 60.016-second pacing run with the same settings/workload averaged 60.00 FPS, with p95/p99 18.195/19.061 ms and 1% low 49.34 FPS. Five of 3,601 frames exceeded 20 ms, including one 38.569 ms frame. This brief final run shows occasional dips; the ten-minute result above describes the preceding candidate. Final exported gameplay checks cover the corrections.


## Review and delivery

PR #4 was explicitly authorized for merge at the user's discretion after existing comments were addressed and CI passed. It was squash-merged as `a74d17dbd2e8d7370df88cbaeea50ae69602ccc8` on 2026-10-04. The final adapter finding had affirmative review, while a full rereview was rate-limited; no full current-head completion is implied. That override applies to PR #4. This iteration is a separate PR and uses the original current-head review/check/two-poll gate.

The single stable app remains `builds/Zombie Slop.app`. Cross exports are organized under `builds/cross-platform/`; earlier working apps and source/download backups remain preserved outside public Git. The paired private asset revision and upload evidence are in ASSETS.json. No assets, media, builds or LFS pointers are uploaded to the public repository or CI artifacts.

## Prototype limits

The 328m map has sixteen homes and three shops across four home types, plus rural plots, woods and river scenery; it is still a small stylized prototype. Armor changes the model and is cosmetic until vehicle damage is implemented. Vehicles have arcade controls, no fuel/damage/drivetrain or seated animation. Raft/backpack/campfire mechanics remain decorative. Zombie navigation is a ground-plane grid, without deliberate multi-floor routing. Same-rig gun actions blend at runtime without a layered upper-body system. Linux/Windows are cross-exported rather than runtime-tested; Steam Deck, Android and physical controllers remain unverified.

# Prior iteration-four validation

Target: Apple M3 MacBook Air, 16 GB; Godot 4.7.2 Mobile / Metal, 1280×800. Normal play retains the 60 FPS cap, VSync and shadows off. Steam Deck and physical controller feel remain unverified.

## Gameplay and model verification

**99 source/save checks and 403 native exported graphical checks pass**, followed by **six fresh-process save/relaunch checks**. This round exercises all four survivor choices through the real inventory callback, all nine discoverable weapons through actual household contents menus, all four zombie variants, and all seven drivable vehicles. Additional coverage verifies right-handed firearm poses for every survivor, lowered versus raised barrel orientation, support-hand contact for all four long guns, real SMG/revolver/compact-shotgun damage and ammo spending, timed melee contact/no ammo/wall occlusion, interrupted actions on vehicle entry, acceleration/steering/braking/safe exit, exact parked transforms, seeded loot variation, and legacy migration. All 28 safe/fridge fronts meet their exported hinges and all fourteen roof eaves overlap their wall tops. Actual physics movement crosses sidewalks diagonally, climbs the outer slopes, crosses the eastern river bridge without jumping and remains contained at the high map corner. Supported river-bed saves reload there; older flat-map positions beneath new hills recover to the home path.

An exported inspection process walked the player through **32 actual room targets** across four houses, without failed targets. Screenshots cover front/eaves, backyard, kitchen, opened fridge, bedroom, opened safe and a reverse bedroom view, plus wooded slopes and both bridge approaches. Fixed inspection cameras hide only the player visual so it cannot obscure the geometry; the capsule still performs the actual room walks. This is engine-scripted input in a rendered exported game, rather than a claim of a human walking every room. Geometry tests cover all houses; screenshot inspection covers four, not every possible camera angle.

Screenshots exposed and led to corrections of doubled cabinet parent offsets, incorrect fixture facing, roof/wall separation, overlapping furniture, a shelf obscuring a refrigerator, overly steep lowered weapon poses and vegetation obscuring the bridge view. Further movement testing found a hard height boundary at the eastern bridge approach; it now blends gradually into the hillside. Tree navigation and respawn clearance use the actual local terrain height.

Desktop automation additionally clicked New Neighborhood, opened Tab inventory, selected Lis, closed inventory with Tab, opened Escape pause and saved/quit an isolated session. This caught GUI focus consuming Tab after survivor selection; the close event now runs before GUI focus handling and is tested for all four survivors with real input dispatch. Blender's graphical interface opened and framed the editable safe for inspection without saving the model. These observations supplement the repeatable rendered suite; no physical gamepad was attached.

The user's actual version-three save also passed a read-only version-four migration check, preserving inventory, collected identities, placed count and weapon magazines. The user's current saves/settings were copied to external `backups/pre-iteration4-saves/`. Automated and direct desktop modes use separate save files, and manual-test mode skips preference writes. The stable playable app is `builds/Zombie Slop.app`; earlier root build outputs are preserved in `backups/build-history-before-stable-app/`, with Linux/Windows exports organized beneath `builds/cross-platform/`. Assets, builds, images and reports remain outside public Git and CI artifacts. Private asset sources/LFS objects were checkpointed and uploaded as recorded in ASSETS.json; pristine downloads and prior sources remain retained.

CodeRabbit's character-update workflow finding was corrected: standalone `--update-characters` rebuilds the four survivors while reusing existing non-survivor sources and creating missing ones. A disposable filesystem harness passed 15 assertions across six CLI scenarios, retaining the real argument validation, source iteration, overwrite guards, hash checks and complete 22-entry manifest writing, with Blender geometry calls stubbed. It also checks default overwrite refusal, resume, export-only and incompatible flags. This is control-flow coverage, not an additional Blender geometry test.

## Sustained performance

The exported Metal build completed **600.009 seconds** at **1280×800**, with the **60 FPS cap / VSync on, shadows off**, **18 living zombies in every measured section**, and **50 placed objects**. No other graphical game or Blender session ran concurrently. The eight views repeat twice (75 seconds per view in total), with actual movement, shots, placement preview and vehicle acceleration. Benchmark-only health/ammo replenishment preserves the stress workload; section transitions remain included.

- Average **59.97 FPS**; p50/p95/p99 **16.678 / 17.986 / 18.632 ms**.
- **1% low 52.41 FPS**; maximum **24.010 ms**.
- **23 / 35,984 frames exceeded 20 ms; zero exceeded 33.333 ms**.
- 18,322 frames exceeded the literal 16.667 ms threshold, including capped presentation jitter. This demonstrates near-60 pacing with brief dips, **not perfectly sustained 60 FPS** or Steam Deck capacity.

| View (two laps) | Average FPS | p99 ms | 1% low FPS |
|---|---:|---:|---:|
| 50-piece furnished base | 59.97 | 18.721 | 52.38 |
| Driving | 59.97 | 18.403 | 52.94 |
| Forest and river | 59.97 | 18.107 | 53.40 |
| Interior | 59.97 | 18.709 | 51.54 |
| Placement preview | 59.97 | 18.701 | 52.18 |
| Populated supply view | 59.97 | 18.717 | 52.73 |
| Shooting encounter | 59.97 | 18.715 | 51.70 |
| Street traversal | 59.97 | 18.518 | 53.25 |

Sampled physics medians ranged from 1.90 ms (forest/river) to 4.58 ms (driving); the largest sampled physics frame was 9.14 ms during shooting. Median draws ranged from 54.5 (shooting) to 134.5 (furnished base). Process monitors include presentation waiting and do not isolate render CPU cost. This run has a shorter frame-time tail than iteration three, despite more content, but the routes differ and it is not a controlled feature-by-feature comparison. There is no evidence here of a large sustained bottleneck needing reduced map density. Remaining pacing jitter and platform-specific rendering need further investigation before promising perfect 60 FPS.

The primary report and viewport image are external under `verification/iteration4/performance/`. Subsequent changes calibrate car/truck/wreck collision bounds, extend invisible map boundaries above the hilltops, move decorative grills inside the rear fence, reset menu input state and align saved-position recovery with local terrain height; rendered geometry, asset sources, density and graphics settings are unchanged. The final exported integration and short pacing check cover those corrections. The final 60-second exported check measured 59.97 FPS, p95/p99 17.988 / 18.650 ms, 1% low 50.71 FPS, maximum 29.547 ms and no frames over 33.333 ms. Its separate report is under `verification/iteration4/final-check/`.

## Review status

PR #3 was explicitly authorized for merge at the user's discretion after its existing findings were addressed and required CI passed. It was squash-merged on 2026-10-04 as `d8b63256815f781bba9404f20574319f915a11ec`, without implying a fresh current-head CodeRabbit review. That override applies to PR #3. Iteration four uses a separate feature branch/PR and the original current-head review gate below; its review is requested only after this full feature round and validation are committed.

## Prototype limits

The map remains a 248m low-poly prototype with fourteen houses, rather than a large finished open world. Interior furniture positions vary but house floor plans are reused. Vehicles have arcade controls and a hidden survivor instead of seated animation; no fuel, vehicle destruction or detailed drivetrain. Backpack/campfire are placeable props, without expanded inventory capacity or cooking. Street cross/turn sources are prepared but only straight/cracked pack tiles render in the present layout. The ribcage zombie uses its own sparse rig and HitReact alias rather than sharing an incompatible attack rig. There is no layered upper-body aim system; complete same-rig weapon clips blend at runtime. Save/load restores the player on foot and uses normal obstruction recovery if saved inside a car. Linux/Windows are cross-exported and not runtime-tested; Steam Deck and Android remain unverified.

# Prior iteration-three validation

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
