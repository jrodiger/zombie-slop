# Playing Zombie Slop

Launch the native `Zombie Slop.app` in the external builds folder, or run `./scripts/run.sh` after installing external assets. Choose **New Neighborhood** or **Continue Saved Game**. Gamepad menu navigation uses D-pad/left stick and A to activate focused controls.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move / look | WASD / mouse | Left / right stick |
| Sprint | Shift | L3 |
| Jump | Space | RB |
| Aim / fire | Right / left mouse | LT / RT |
| Reload | R | X |
| Select pistol / rifle / shotgun | 1 / 2 / 3 | Cycle owned guns below |
| Cycle owned guns | V | D-pad left |
| Collect / use door / storage | E | A |
| Build / decorate menu | B | Y |
| Heal | H | D-pad up |
| Move a nearby placed item | G | LB |
| Recover/remove nearby item | X | D-pad down |
| Rotate preview | Q / R | LB / RB |
| Preview distance | Wheel or + / − | D-pad right / left |
| Preview height | Up / down arrows, 10cm steps | D-pad up / down |
| Optional construction snap | T | X |
| Confirm placement | Left mouse or Enter | A |
| Cancel placement | Esc | B |
| Pause | Esc | Start |
| Save | F5 or pause menu | Pause → Save |
| Performance display | F3 | Keyboard currently required |

While placing, placement actions take precedence over combat/healing. Gamepad movement is not dependent on mouse dragging. Actual physical-controller feel remains unverified unless recorded in validation.

## First objective

Home is the green-roofed house labelled **HOME**. Collect wood and scrap immediately to the right of the front path, then explore toward the main street. The **potted fern** is near the street at the first approach; other designated collectibles have diamond markers. Return to within 12m of home. Open **B / Y**, choose the fern, point at ground, floor, table or shelf and rotate it. A green preview and “Ready to place” mean it can be confirmed. Finally build a barricade or supply chest. Completion leaves the neighborhood open for sandbox play.

The supply house beyond the intersection contains extra materials, ammunition, medkits, a guitar and a display shelf, with more zombies nearby. A shotgun and shells sit on the western porch near the intersection; the rifle and rifle rounds are inside the supply house. Pick up a gun with E / A to equip it, then reload. Each gun retains its own magazine when switching; pistol rounds, rifle rounds and shells are separate reserves. Switching or death cancels a reload before ammunition is transferred. Gunfire attracts enemies. Route around abandoned vehicles and use yard shortcuts. Six outer Kenney houses are closed shells; only the original home and supply house interiors are accessible.

## Placement and building

Collectibles move freely within 20m of HOME. Recipes: foundation (6 wood), wall (5 wood), door/frame (5 wood + 2 scrap), barricade (4 wood + 1 scrap), roof (4 wood), chest (8 wood + 2 scrap). Furnishings consume carried objects, never a recipe copy. Materials/items are consumed only on a successful placement. Cancelling a move leaves the source object and contents intact. New pieces require level support, clearance and room for the survivor. A roof requires two wall/frame supports at its edges. Use a foundation, walls at the perimeter, and a roof at wall-top height; height/distance controls help when the camera ray targets another surface. Snap is optional for construction; free arrangement is always available.

Recovering a decoration returns that object. Removing a surviving constructed piece gives a **full material refund**. Destroyed pieces return no construction materials. Empty a chest before recovering it; repositioning retains contents. Zombies damage blocking constructions. A destroyed chest returns contents to your inventory to avoid silent loss. Door closure is denied when the doorway is occupied. The open leaf is decorative; its doorway collision clears while open.

Stationary pieces are static collision bodies; only previews update each frame. AI uses a static grid navigation graph with staggered path requests, real collision against new pieces, and attacks on encountered blockers. It does not rebake the map every frame. This simple first iteration does not simulate structural collapse or raids.

## Saving and recovery

Autosave occurs every 60 seconds outside menus/previews. F5 and pause → Save create explicit checkpoints. Save and Quit saves before closing. Death preserves the last valid checkpoint; choose Load Last Save or New Neighborhood. Closing the window normally is an autosave-based exit; use Save and Quit for an immediate checkpoint.

Progress is stored in the game's local application-support folder: `survival.json`, with `.bak` for the previous valid save. Invalid/missing saves produce a readable message; a valid backup is recovered automatically. Collected world identities, inventory, placed identity/transforms, construction HP/door state, storage and starter progress are persisted. Enemy positions are repopulated on load; essential base progress remains. Version-one progress migrates automatically to the multi-weapon save format, preserving existing items and arrangements. Settings are saved separately in `settings.cfg`; current preferences take priority over settings embedded in an older progress save. Gameplay defaults to a 60 FPS cap and shadows off; uncapped mode remains available for profiling. Test/benchmark modes use separate save files.

If geometry traps you, pause → **Return Home If Stuck**. On load the game checks obviously invalid or obstructed positions and uses the home path as a recovery point. There is no hunger, multiplayer, drivable vehicle, electricity or complex crafting tree in this prototype.
