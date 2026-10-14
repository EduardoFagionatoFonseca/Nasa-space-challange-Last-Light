class_name LunarDiorama
extends Node3D

signal site_selected(site: String)

const NAVY := Color("121b2a")
const STONE := Color("657083")
const WARM := Color("f2b663")
const CYAN := Color("67dad5")
const RED := Color("ea695d")

var site_nodes: Dictionary = {}
var rings: Dictionary = {}
var markers: Dictionary = {}
var alerts: Dictionary = {}
var animated: Array[Node3D] = []
var panel_pivots: Array[Node3D] = []
var beacon: OmniLight3D
var astronaut: Node3D
var active_site: String = "habitat"
var model: MissionModel
var clock: float = 0.0

func _ready() -> void:
	_build()

func _process(delta: float) -> void:
	clock += delta
	for pivot in panel_pivots:
		pivot.rotation.y = sin(clock * 0.16) * 0.12
	if beacon:
		beacon.light_energy = 1.5 + sin(clock * 3.0) * 0.55
	for item in animated:
		item.rotation.y += delta * 0.11
	for site in markers:
		if markers[site].visible:
			markers[site].position.y = 2.15 + sin(clock * 3.0) * 0.14
			markers[site].rotation.y += delta * 1.7
	for site in alerts:
		if alerts[site].visible:
			alerts[site].light_energy = 1.5 + sin(clock * 6.0) * 1.0

func set_model(value: MissionModel) -> void:
	model = value
	if not is_node_ready(): return
	var damaged: bool = not model.panels_ok
	for pivot in panel_pivots:
		pivot.rotation.z = -0.22 if damaged else 0.0
	if beacon:
		beacon.light_color = CYAN if model.rescue >= 3 else (RED if not model.comms_ok else WARM)
	if site_nodes.has("greenhouse"):
		var lamp: OmniLight3D = site_nodes["greenhouse"].get_node("Glow")
		lamp.light_energy = 2.0 if int(model.resources["water"]) > 18 else 0.6
	alerts["solar"].visible = not model.panels_ok
	alerts["water"].visible = not model.recycler_ok
	alerts["oxygen"].visible = model.leak
	alerts["antenna"].visible = not model.comms_ok
	alerts["shelter"].visible = model.day == 4 and model.shelter < 60

func select_site(site: String) -> void:
	active_site = site
	for key in rings:
		rings[key].visible = key == site
		markers[key].visible = key == site
	site_selected.emit(site)

func pick_from_screen(camera: Camera3D, point: Vector2) -> void:
	var origin: Vector3 = camera.project_ray_origin(point)
	var end: Vector3 = origin + camera.project_ray_normal(point) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result["collider"].has_meta("site"):
		select_site(str(result["collider"].get_meta("site")))

func pulse(site: String) -> void:
	if not rings.has(site): return
	select_site(site)
	var ring: Node3D = rings[site]
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3.ONE * 1.35, 0.18)
	tween.tween_property(ring, "scale", Vector3.ONE, 0.26)

func _build() -> void:
	# Original procedural geometry: compact, readable lunar base without external assets.
	_add_mesh(self, CylinderMesh.new(), Vector3(0, -0.48, 0), Vector3(11.2, 0.65, 11.2), _mat(Color("414b5c")))
	var top := CylinderMesh.new()
	top.top_radius = 5.7; top.bottom_radius = 5.45; top.height = 0.28; top.radial_segments = 48
	_add_mesh(self, top, Vector3(0, -0.1, 0), Vector3.ONE, _mat(Color("7a8291")))
	for i in range(18):
		var angle: float = TAU * float(i) / 18.0
		var radius: float = 4.2 + sin(i * 3.1) * 0.6
		var rock := SphereMesh.new(); rock.radial_segments = 8; rock.rings = 4
		_add_mesh(self, rock, Vector3(cos(angle) * radius, 0.09, sin(angle) * radius), Vector3(0.22 + float(i % 3) * 0.08, 0.18, 0.3), _mat(Color("5a6475") if i % 2 else Color("9098a4")))
	for place in [Vector3(-4.0, 0.01, -0.7), Vector3(4.15, 0.01, 0.45), Vector3(-2.55, 0.01, 3.35)]:
		_import_mesh(self, "rock_largeA", place, Vector3.ONE * 0.48)
	for crater_pos in [Vector3(-3.8, 0.04, 1.75), Vector3(3.35, 0.04, -2.7), Vector3(0.8, 0.04, -4.35)]:
		var disk := CylinderMesh.new(); disk.top_radius = 0.55; disk.bottom_radius = 0.55; disk.height = 0.025; disk.radial_segments = 16
		_add_mesh(self, disk, crater_pos, Vector3.ONE, _mat(Color("555f70")))
		for j in range(10):
			var a: float = TAU * float(j) / 10.0
			var rim := SphereMesh.new(); rim.radial_segments = 6; rim.rings = 3
			_add_mesh(self, rim, crater_pos + Vector3(cos(a) * 0.55, 0.08, sin(a) * 0.55), Vector3(0.16, 0.08, 0.14), _mat(Color("929aa7")))
	# Roads and warm-lit pressure corridors.
	_corridor(Vector3(-2.35, 0.14, 0.1), Vector3(0, 0.14, 0))
	_corridor(Vector3(0, 0.14, 0), Vector3(2.25, 0.14, -0.2))
	_corridor(Vector3(0, 0.14, 0), Vector3(-0.1, 0.14, 2.45))
	_corridor(Vector3(0, 0.14, 0), Vector3(0.45, 0.14, -2.55))
	_habitat("habitat", Vector3(0, 0.17, 0), 1.1, WARM)
	_habitat("oxygen", Vector3(-2.4, 0.17, 0), 0.82, CYAN)
	_habitat("water", Vector3(2.55, 0.17, -0.25), 0.82, CYAN)
	_habitat("shelter", Vector3(0.1, 0.17, 2.7), 0.9, Color("b4a8d8"))
	_greenhouse(Vector3(0.45, 0.17, -2.8))
	_solar_array(Vector3(-3.2, 0.1, -2.55))
	_antenna(Vector3(3.3, 0.12, 2.25))
	_landing_pad(Vector3(3.15, 0.05, -3.6))
	_astronaut()
	_import_mesh(self, "rover", Vector3(-2.0, 0.09, 3.5), Vector3.ONE * 1.65)
	_import_mesh(self, "machine_generator", Vector3(-3.15, 0.17, 0.4), Vector3.ONE * 1.1)
	select_site("")

func _habitat(site: String, pos: Vector3, radius: float, glow: Color) -> void:
	var root := Node3D.new(); root.name = site.capitalize(); root.position = pos; add_child(root)
	var base := CylinderMesh.new(); base.top_radius = radius; base.bottom_radius = radius * 1.1; base.height = 0.3; base.radial_segments = 12
	_add_mesh(root, base, Vector3(0, 0.07, 0), Vector3.ONE, _mat(Color("253344")))
	var shell := SphereMesh.new(); shell.radial_segments = 16; shell.rings = 8
	_add_mesh(root, shell, Vector3(0, 0.52, 0), Vector3(radius, 0.55, radius), _mat(Color("b5bfca")))
	var roof := CylinderMesh.new(); roof.top_radius = radius * 0.78; roof.bottom_radius = radius * 0.92; roof.height = 0.12; roof.radial_segments = 12
	_add_mesh(root, roof, Vector3(0, 0.92, 0), Vector3.ONE, _mat(Color("39475a")))
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		var win := BoxMesh.new()
		_add_mesh(root, win, Vector3(cos(a) * radius * 0.88, 0.52, sin(a) * radius * 0.88), Vector3(0.18, 0.15, 0.1), _mat(glow, true))
	_add_light(root, Vector3(0, 0.85, 0), glow, 1.25, 2.0)
	_register(site, root, radius)

func _greenhouse(pos: Vector3) -> void:
	var root := Node3D.new(); root.name = "Greenhouse"; root.position = pos; add_child(root)
	var base := CylinderMesh.new(); base.top_radius = 1.05; base.bottom_radius = 1.08; base.height = 0.22; base.radial_segments = 12
	_add_mesh(root, base, Vector3(0, 0.08, 0), Vector3.ONE, _mat(Color("364b55")))
	var dome := SphereMesh.new(); dome.radial_segments = 20; dome.rings = 10
	var glass := _mat(Color(0.18, 0.5, 0.48, 0.55), true)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_add_mesh(root, dome, Vector3(0, 0.58, 0), Vector3(1.0, 0.61, 1.0), glass)
	_import_mesh(root, "hangar_roundGlass", Vector3(0, 0.12, 0), Vector3.ONE * 0.54)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var stem := CylinderMesh.new(); stem.top_radius = 0.025; stem.bottom_radius = 0.04; stem.height = 0.34
		_add_mesh(root, stem, Vector3(cos(a) * 0.55, 0.34, sin(a) * 0.55), Vector3.ONE, _mat(Color("6fb177")))
		var leaf := SphereMesh.new(); leaf.radial_segments = 6; leaf.rings = 4
		_add_mesh(root, leaf, Vector3(cos(a) * 0.55, 0.57, sin(a) * 0.55), Vector3(0.2, 0.09, 0.13), _mat(Color("a8d38c")))
	var lamp := _add_light(root, Vector3(0, 0.72, 0), Color("78eac5"), 2.0, 2.5)
	lamp.name = "Glow"
	_register("greenhouse", root, 1.12)

func _solar_array(pos: Vector3) -> void:
	var root := Node3D.new(); root.name = "Solar"; root.position = pos; add_child(root)
	for row in range(2):
		for col in range(3):
			var pivot := Node3D.new(); pivot.position = Vector3((col - 1) * 0.72, 0.43, (row - 0.5) * 0.85); root.add_child(pivot)
			var panel := BoxMesh.new()
			_add_mesh(pivot, panel, Vector3.ZERO, Vector3(0.62, 0.06, 0.7), _mat(Color("1a415f")))
			for stripe in range(3):
				_add_mesh(pivot, BoxMesh.new(), Vector3((stripe - 1) * 0.17, 0.038, 0), Vector3(0.025, 0.004, 0.64), _mat(CYAN))
			_add_mesh(root, CylinderMesh.new(), Vector3((col - 1) * 0.72, 0.24, (row - 0.5) * 0.85), Vector3(0.07, 0.45, 0.07), _mat(Color("8b9ba8")))
			panel_pivots.append(pivot)
	_register("solar", root, 1.8)

func _antenna(pos: Vector3) -> void:
	var root := Node3D.new(); root.name = "Antenna"; root.position = pos; add_child(root)
	_add_mesh(root, CylinderMesh.new(), Vector3(0, 0.7, 0), Vector3(0.12, 1.4, 0.12), _mat(Color("aab8c5")))
	var dish := CylinderMesh.new(); dish.top_radius = 0.68; dish.bottom_radius = 0.2; dish.height = 0.19; dish.radial_segments = 16
	_add_mesh(root, dish, Vector3(0, 1.43, 0), Vector3.ONE, _mat(Color("d4dce3")))
	_add_mesh(root, SphereMesh.new(), Vector3(0, 1.62, 0), Vector3(0.11, 0.11, 0.11), _mat(WARM, true))
	_import_mesh(root, "satelliteDish_detailed", Vector3(0, 1.45, 0), Vector3.ONE * 0.78)
	beacon = _add_light(root, Vector3(0, 1.66, 0), WARM, 1.5, 3.5)
	_register("antenna", root, 0.8)

func _landing_pad(pos: Vector3) -> void:
	var root := Node3D.new(); root.name = "LandingPad"; root.position = pos; add_child(root)
	var pad := CylinderMesh.new(); pad.top_radius = 1.2; pad.bottom_radius = 1.2; pad.height = 0.07; pad.radial_segments = 24
	_add_mesh(root, pad, Vector3.ZERO, Vector3.ONE, _mat(Color("293646")))
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		_add_mesh(root, BoxMesh.new(), Vector3(cos(a) * 1.0, 0.04, sin(a) * 1.0), Vector3(0.16, 0.018, 0.06), _mat(WARM, true))
	_add_mesh(root, BoxMesh.new(), Vector3(0, 0.05, 0), Vector3(0.6, 0.015, 0.07), _mat(Color("e9eef1")))
	_add_mesh(root, BoxMesh.new(), Vector3(0, 0.05, 0), Vector3(0.07, 0.015, 0.6), _mat(Color("e9eef1")))
	_register("landing", root, 1.2)

func _astronaut() -> void:
	astronaut = Node3D.new(); astronaut.name = "Astronaut"; add_child(astronaut)
	astronaut.position = Vector3(1.85, 0.17, 3.58)
	_import_mesh(astronaut, "astronautA", Vector3.ZERO, Vector3.ONE * 1.22)
	_add_light(astronaut, Vector3(0, 0.72, 0), CYAN, 0.58, 2.35)

func _corridor(start: Vector3, end: Vector3) -> void:
	var midpoint: Vector3 = (start + end) / 2.0
	var length: float = start.distance_to(end)
	var root := Node3D.new(); root.position = midpoint; root.rotation.y = atan2(end.x - start.x, end.z - start.z); add_child(root)
	_add_mesh(root, BoxMesh.new(), Vector3.ZERO, Vector3(0.43, 0.19, length), _mat(Color("273849")))
	_add_mesh(root, BoxMesh.new(), Vector3(0, 0.13, 0), Vector3(0.18, 0.04, length), _mat(WARM, true))

func _register(site: String, root: Node3D, radius: float) -> void:
	site_nodes[site] = root
	var body := StaticBody3D.new(); body.set_meta("site", site); root.add_child(body)
	var shape := CollisionShape3D.new(); var sphere := SphereShape3D.new(); sphere.radius = radius
	shape.shape = sphere; shape.position.y = 0.55; body.add_child(shape)
	var ring := Node3D.new(); ring.position.y = 0.04; root.add_child(ring)
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		var mesh := BoxMesh.new()
		var segment := _add_mesh(ring, mesh, Vector3(cos(a) * (radius + 0.14), 0, sin(a) * (radius + 0.14)), Vector3(0.11, 0.025, 0.035), _mat(CYAN, true))
		segment.rotation.y = -a
	ring.visible = false
	rings[site] = ring
	var marker := Node3D.new(); root.add_child(marker)
	var diamond := SphereMesh.new(); diamond.radial_segments = 4; diamond.rings = 2
	_add_mesh(marker, diamond, Vector3.ZERO, Vector3(0.22, 0.36, 0.22), _mat(WARM, true))
	var stem := CylinderMesh.new(); stem.top_radius = 0.018; stem.bottom_radius = 0.018; stem.height = 0.55
	_add_mesh(marker, stem, Vector3(0, -0.46, 0), Vector3.ONE, _mat(WARM, true))
	marker.visible = false
	markers[site] = marker
	var alert := _add_light(root, Vector3(0, 1.5, 0), RED, 1.5, radius + 2.1)
	alert.visible = false
	alerts[site] = alert

func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.mesh = mesh; node.position = pos; node.scale = size
	node.material_override = material; parent.add_child(node)
	return node

func _import_mesh(parent: Node3D, asset_name: String, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh: Mesh = load("res://assets/kenney_space_kit/%s.obj" % asset_name)
	var node := MeshInstance3D.new(); node.mesh = mesh; node.position = pos; node.scale = size
	parent.add_child(node)
	return node

func _mat(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = color
	mat.metallic = 0.18; mat.roughness = 0.55
	if emission:
		mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = 1.8
	return mat

func _add_light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new(); light.position = pos; light.light_color = color
	light.light_energy = energy; light.omni_range = radius; light.shadow_enabled = false
	parent.add_child(light)
	return light
