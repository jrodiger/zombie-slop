extends RefCounted
# Dimensions are collision extents in meters. Visuals come from the external asset workspace.
const ITEMS = {
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
const FURNITURE = ["plant","radio","guitar","chair","table","shelf"]
const BUILD = ["foundation","wall","door","barricade","roof","storage"]
const SUPPLIES = ["wood","scrap","ammo","medkit"]
static func built(kind:String) -> bool:
 return kind in BUILD
