# Playing Zombie Slop

Launch the native `Zombie Slop.app` in the external builds folder, or run `./scripts/run.sh` after installing external assets. Preview and choose Matt, Lis, Sam or Shaun (the default for a new neighborhood) and **New Neighborhood**, or **Continue Saved Game**. The same app path is updated each iteration; earlier builds are archived in the external backups folder. Gamepad menu navigation uses D-pad/left stick and A to activate focused controls.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move / look | WASD / mouse | Left / right stick |
| Sprint | Shift | L3 |
| Jump | Space | RB |
| Aim / fire or melee | Right / left mouse | LT / RT |
| Reload | R | X |
| Select pistol / rifle / shotgun | 1 / 2 / 3 | Cycle owned weapons below |
| Cycle owned weapons | V | D-pad left |
| Inventory / character selection | Tab | Back / Select |
| Enter / exit nearby car | E | A |
| Drive / steer | W / S and A / D | Left stick |
| Brake | Space | RB |
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

Sixteen homes use bungalow, cottage, townhouse and farmhouse layouts, including upstairs rooms reached by stairs. Three shops add a gas station/auto shop, grocery and convenience store. Houses face their streets, with gates aligned to their approach paths. Search drawers, refrigerators and bedroom safes, then choose individual stacks beside their model pictures in the contents menu. Household chests provide additional storage loot; some supplies and recoverable furnishings are visible on counters and floors. Each stack is collected once and remaining contents persist through saves. Walls and intact window glass block searching from outside. Supplies vary by neighborhood seed and address: food/water in fridges, materials and common ammo in drawers, weapons/ammo and occasional medicine in safes. The seed persists, so reopening or loading cannot reroll collected stock. Guaranteed weapon locations:

| Location | Weapon |
|---|---|
| Home kitchen drawers (14 Cedar) | Axe |
| 8 Cedar bedroom safe | Rifle + rifle ammo |
| 12 Cedar bedroom safe | Shotgun + shells |
| 11 Cedar bedroom safe | SMG + pistol ammo |
| 3 Cedar bedroom safe | Revolver + pistol ammo |
| 4 Cedar bedroom safe | Compact shotgun + shells |
| 7 Cedar bedroom safe | Barbed bat |
| 2 Orchard bedroom safe | Knife |

 Find their addresses in each container menu. Collecting a weapon equips it unloaded; reload before firing. Guns retain separate magazines and ammunition reserves when switching. Switching or death cancels a reload before ammunition transfers. Gunfire attracts nearby enemies. Firearms rest beside the survivor when not aiming; long guns use both hands while raised. Walking and running continue during reloads.

When sprint stamina runs out, you settle into walking. Release sprint and recover at least 25 stamina before sprinting again. H / D-pad up uses a medkit, then food or water if necessary. Tab / Back or Pause → Inventory lets you choose a specific supply or weapon; full health cannot waste a healing item. There is no hunger meter.

Guns use a lowered ready pose while walking, raising when aiming or firing. Rifles, shotguns and the SMG use the supporting hand on the foregrip; reloads release it. Melee uses authored Slash/Stab clips, timed contact, reach and a wall-blocking check. Switching cancels an unfinished swing; melee consumes no ammo. Tab also lets you switch between all four survivors during play, keeping progress and equipment. Character switching is unavailable while driving.

Killed zombies are replaced gradually, up to eighteen living enemies. Replacements spawn at least 32m away, behind your view, on reachable ground and outside a 26m home exclusion area. The first check occurs after 25 seconds, then every 15 seconds while the game is active. Loot does not refill when enemies respawn. The basic, chubby, one-armed and ribcage variants have different health and speed; chubby zombies have 220 HP versus the basic zombie’s 100 HP and walk slightly slower. The leg/ribcage variant is fastest, has 70 HP and deals only 4 damage per hit.

## Exploring and driving

The eastern river has wooden crossings north and south. The outskirts rise into wooded slopes with pines, willows, berry bushes, flowers, logs and camps. Backpack and campfire props are recoverable at the west camp and placeable at home; they are decorative, without extra carrying capacity or cooking yet. A single custom asphalt material supplies weathering and cosmetic cracks, with matching road collision. A decorative raft and oars sit by the river. Two rural farmsteads lie along the western road. Sidewalk edges are sloped for crossings, including diagonal approaches.

Six intact, initially unarmored pickup/sports/truck vehicles are drivable; the ITHappy wreck is static scenery. Engine sound starts when driving and changes pitch with acceleration. Nearby living zombies occasionally growl with directional sound, and footsteps vary between grass, road and wooden floors. Find vehicle parts and scrap at Cedar Auto & Fuel north of the neighborhood. On foot beside a car, open Tab and choose **FIT VEHICLE ARMOR** (2 vehicle parts + 10 scrap). This swaps to its matching armored model and persists; armor is cosmetic until vehicle damage is implemented. Approach a car and press E / A to enter, then accelerate, reverse, steer and brake. E / A exits to the first clear adjacent spot; move the car if all exits are obstructed. Vehicles collide with the world and can hit zombies. Parked position/heading persists. Driving is an arcade prototype: the survivor is hidden while driving, without a seated animation, fuel, damage or drivetrain simulation. Save/load restores you on foot, recovering to the home path if the saved position overlaps a vehicle.

## Placement and building

Collectibles move freely within 20m of HOME. Recipes: foundation (6 wood), wall (5 wood), door/frame (5 wood + 2 scrap), barricade (4 wood + 1 scrap), roof (4 wood), chest (8 wood + 2 scrap). Furnishings consume carried objects, never a recipe copy. Materials/items are consumed only on a successful placement. Cancelling a move leaves the source object and contents intact. New pieces require level support, clearance and room for the survivor. A roof requires two wall/frame supports at its edges. Use a foundation, walls at the perimeter, and a roof at wall-top height; height/distance controls help when the camera ray targets another surface. Snap is optional for construction; wheel and keyboard/pad rotation then use 90° steps. Free mode uses 15° steps or Shift-wheel for 5°. Free arrangement is always available.

Recovering a decoration returns that object. Removing a surviving constructed piece gives a **full material refund**. Destroyed pieces return no construction materials. Empty a chest before recovering it; repositioning retains contents. Zombies damage blocking constructions. A destroyed chest returns contents to your inventory to avoid silent loss. Door closure is denied when the doorway is occupied. The open leaf is decorative; its doorway collision clears while open.

Stationary pieces are static collision bodies; only previews update each frame. AI uses a static grid navigation graph with staggered path requests, real collision against new pieces, and attacks on encountered blockers. It does not rebake the map every frame. This simple first iteration does not simulate structural collapse or raids.

## Saving and recovery

Autosave occurs every 60 seconds outside menus/previews. F5 and pause → Save create explicit checkpoints. Save and Quit saves before closing. Death preserves the last valid checkpoint; choose Load Last Save or New Neighborhood. Closing the window normally is an autosave-based exit; use Save and Quit for an immediate checkpoint.

Progress is stored in the game's local application-support folder: `survival.json`, with `.bak` for the previous valid save. Invalid/missing saves produce a readable message; a valid backup is recovered automatically. Collected world identities, inventory, placed identity/transforms, construction HP/door state, storage and starter progress are persisted. Enemy positions are repopulated on load; essential base progress remains. Version-one through version-four saves migrate automatically to version five, preserving weapons, items, collected identities and arrangements. Old neighborhoods receive a stable default loot seed; already collected identities stay collected. New weapon/furnishing counts start empty. Selected character, loot seed, parked vehicle transforms and fitted armor persist. Existing survivor choices are retained; a new neighborhood starts as Shaun. Vehicle parts start at zero for older saves. New permanent home fixtures yield to previously placed objects, protecting an existing base. Settings are saved separately in `settings.cfg`; current preferences take priority over settings embedded in an older progress save. Gameplay defaults to a 60 FPS cap and shadows off; uncapped mode remains available for profiling. Test/benchmark modes use separate save files.

If geometry traps you, pause → **Return Home If Stuck**. On load the game checks obviously invalid or obstructed positions and uses the home path as a recovery point. There is no multiplayer, electricity or complex crafting tree in this prototype.
