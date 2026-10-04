extends RefCounted
# Dimensions are collision extents in meters. Visuals come from the external asset workspace.
const ITEMS = {
 "backpack":{"name":"Canvas backpack","size":Vector3(.4,.5,.25),"asset":"backpack","cost":{}},
 "campfire":{"name":"Campfire","size":Vector3(.9,.28,.9),"asset":"campfire","cost":{}},
 "plant": {"name":"Potted fern", "size":Vector3(0.55,0.8,0.55), "asset":"plant", "cost":{}},
 "radio": {"name":"Old radio", "size":Vector3(0.5,0.3,0.25), "asset":"radio", "cost":{}},
 "guitar": {"name":"Acoustic guitar", "size":Vector3(0.45,1.0,0.25), "asset":"guitar", "cost":{}},
 "chair": {"name":"Kitchen chair", "size":Vector3(0.6,1.0,0.65), "asset":"chair", "cost":{}},
 "table": {"name":"Workbench table", "size":Vector3(1.8,0.85,1.0), "asset":"table", "cost":{}},
 "shelf": {"name":"Display shelf", "size":Vector3(1.5,1.8,0.5), "asset":"shelf", "cost":{}},
 "storage": {"name":"Supply chest", "size":Vector3(1.1,0.65,0.7), "asset":"storage", "cost":{"wood":8,"scrap":2}},
 "foundation": {"name":"Timber foundation", "size":Vector3(3.0,0.2,3.0), "asset":"foundation", "cost":{"wood":6}},
 "wall": {"name":"Timber wall", "size":Vector3(3.0,2.5,0.18), "asset":"wall", "cost":{"wood":5}},
 "door": {"name":"Door + frame", "size":Vector3(3.0,2.5,0.22), "asset":"door", "cost":{"wood":5,"scrap":2}},
 "barricade": {"name":"Street barricade", "size":Vector3(2.6,1.25,0.5), "asset":"barricade", "cost":{"wood":4,"scrap":1}},
 "roof": {"name":"Flat shelter roof", "size":Vector3(3.2,0.16,3.2), "asset":"roof", "cost":{"wood":4}},
}
const CHARACTERS={"matt":"Matt","lis":"Lis","sam":"Sam","shaun":"Shaun"}
const FURNITURE = ["plant","radio","guitar","chair","table","shelf","backpack","campfire"]
const BUILD = ["foundation","wall","door","barricade","roof","storage"]
const SUPPLIES = ["wood","scrap","ammo","medkit","rifle_ammo","shells","food","water"]
const WEAPONS = {
 "axe":{"name":"Fire axe","model":"Axe","melee":true,"capacity":0,"ammo":"ammo","reload":0.0,"interval":.75,"damage":65,"range":2.15,"pellets":0,"spread":0.0,"recoil":.01},
 "bat":{"name":"Barbed bat","model":"WoodenBat_Barbed","melee":true,"capacity":0,"ammo":"ammo","reload":0.0,"interval":.6,"damage":42,"range":2.25,"pellets":0,"spread":0.0,"recoil":.008},
 "knife":{"name":"Knife","model":"Knife","melee":true,"capacity":0,"ammo":"ammo","reload":0.0,"interval":.4,"damage":30,"range":1.65,"pellets":0,"spread":0.0,"recoil":.006},
 "smg":{"name":"SMG","model":"SMG","capacity":25,"ammo":"ammo","reload":1.8,"interval":.075,"damage":18,"pellets":1,"spread":.025,"range":65.0,"recoil":.009},
 "revolver":{"name":"Revolver","model":"Revolver","capacity":6,"ammo":"ammo","reload":2.0,"interval":.45,"damage":60,"pellets":1,"spread":.003,"range":90.0,"recoil":.025},
 "compact_shotgun":{"name":"Compact shotgun","model":"CompactShotgun","capacity":2,"ammo":"shells","reload":2.0,"interval":.8,"damage":18,"pellets":6,"spread":.085,"range":23.0,"recoil":.04},
 "pistol":{"name":"Pistol","capacity":12,"ammo":"ammo","reload":1.6,"interval":.24,"damage":40,"pellets":1,"spread":0.0,"range":90.0,"recoil":.018},
 "rifle":{"name":"Rifle","capacity":30,"ammo":"rifle_ammo","reload":2.1,"interval":.11,"damage":26,"pellets":1,"spread":.012,"range":110.0,"recoil":.012},
 "shotgun":{"name":"Shotgun","capacity":6,"ammo":"shells","reload":2.6,"interval":.85,"damage":18,"pellets":6,"spread":.065,"range":32.0,"recoil":.045},
}
static func built(kind:String) -> bool:
 return kind in BUILD
