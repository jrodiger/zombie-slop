# Playing Zombie Slop

Launch the native `Zombie Slop Iteration 3.app` in the external builds folder, or run `./scripts/run.sh` after installing external assets. Choose **New Neighborhood** or **Continue Saved Game**. Gamepad menu navigation uses D-pad/left stick and A to activate focused controls.

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
| Collect / search / use door / storage | E | A |
| Build / decorate menu | B | Y |
| Heal | H | D-pad up |
| Move a nearby placed item | G | LB |
| Recover/remove nearby item | X | D-pad down |
| Rotate preview | Wheel or Q / R; Shift + wheel for 5° steps | LB / RB |
| Preview distance | + / − | D-pad right / left |
| Preview height | Up / down arrows, 10cm steps | D-pad up / down |
| Optional construction snap | T | X |
| Confirm placement | Left mouse or Enter | A |
| Cancel placement | Esc | B |
| Pause | Esc | Start |
| Save | F5 or pause menu | Pause → Save |
| Performance display | F3 | Keyboard currently required |

While placing, placement actions take precedence over combat/healing. Gamepad movement is not dependent on mouse dragging. Actual physical-controller feel remains unverified unless recorded in validation.

## First objective

Home is the green bungalow at 14 Cedar Lane, where you start. The HUD shows its distance and compass direction. Search the kitchen drawers on the right for wood and scrap. The potted fern sits by the street at the first approach. Other collectible furnishings are real objects inside neighboring homes; look closely and use E / A when the prompt appears. Return to within 12m of home, open B / Y, choose an object, and aim at ground, floor, a table or shelf. A green preview and “Ready to place” mean you can confirm. Finally build a barricade or supply chest. Completion leaves the neighborhood open for sandbox play.

All fourteen houses have accessible interiors, window openings, kitchens and bedroom spaces. Search drawers, refrigerators and bedroom safes, then choose individual stacks in the contents menu. Each stack is collected once and remaining contents persist through saves. Walls and intact window glass block searching from outside. The safe at 8 Cedar Lane contains a rifle and rifle rounds; 12 Cedar Lane has a shotgun and shells. Find their addresses in each container menu. Collecting a weapon equips it unloaded; reload before firing. Guns retain separate magazines and ammunition reserves when switching. Switching or death cancels a reload before ammunition transfers. Gunfire attracts nearby enemies.

When sprint stamina runs out, you settle into walking. Release sprint and recover at least 25 stamina before sprinting again. H / D-pad up uses a medkit, then food or water if necessary. Pause → Backpack lets you choose a specific supply or weapon; full health cannot waste a healing item. There is no hunger meter.

Killed zombies are replaced gradually, up to eighteen living enemies. Replacements spawn at least 32m away, behind your view, on reachable ground and outside a 26m home exclusion area. The first check occurs after 25 seconds, then every 15 seconds while the game is active. Loot does not refill when enemies respawn.

## Placement and building

Collectibles move freely within 20m of HOME. Recipes: foundation (6 wood), wall (5 wood), door/frame (5 wood + 2 scrap), barricade (4 wood + 1 scrap), roof (4 wood), chest (8 wood + 2 scrap). Furnishings consume carried objects, never a recipe copy. Materials/items are consumed only on a successful placement. Cancelling a move leaves the source object and contents intact. New pieces require level support, clearance and room for the survivor. A roof requires two wall/frame supports at its edges. Use a foundation, walls at the perimeter, and a roof at wall-top height; height/distance controls help when the camera ray targets another surface. Snap is optional for construction; free arrangement is always available.

Recovering a decoration returns that object. Removing a surviving constructed piece gives a **full material refund**. Destroyed pieces return no construction materials. Empty a chest before recovering it; repositioning retains contents. Zombies damage blocking constructions. A destroyed chest returns contents to your inventory to avoid silent loss. Door closure is denied when the doorway is occupied. The open leaf is decorative; its doorway collision clears while open.

Stationary pieces are static collision bodies; only previews update each frame. AI uses a static grid navigation graph with staggered path requests, real collision against new pieces, and attacks on encountered blockers. It does not rebake the map every frame. This simple first iteration does not simulate structural collapse or raids.

## Saving and recovery

Autosave occurs every 60 seconds outside menus/previews. F5 and pause → Save create explicit checkpoints. Save and Quit saves before closing. Death preserves the last valid checkpoint; choose Load Last Save or New Neighborhood. Closing the window normally is an autosave-based exit; use Save and Quit for an immediate checkpoint.

Progress is stored in the game's local application-support folder: `survival.json`, with `.bak` for the previous valid save. Invalid/missing saves produce a readable message; a valid backup is recovered automatically. Collected world identities, inventory, placed identity/transforms, construction HP/door state, storage and starter progress are persisted. Enemy positions are repopulated on load; essential base progress remains. Version-one and version-two saves migrate automatically to version three, preserving weapons, items, collected identities and arrangements. New food and water stacks start empty. New permanent home fixtures yield to previously placed objects, protecting an existing base. Settings are saved separately in `settings.cfg`; current preferences take priority over settings embedded in an older progress save. Gameplay defaults to a 60 FPS cap and shadows off; uncapped mode remains available for profiling. Test/benchmark modes use separate save files.

If geometry traps you, pause → **Return Home If Stuck**. On load the game checks obviously invalid or obstructed positions and uses the home path as a recovery point. There is no multiplayer, drivable vehicle, electricity or complex crafting tree in this prototype.
