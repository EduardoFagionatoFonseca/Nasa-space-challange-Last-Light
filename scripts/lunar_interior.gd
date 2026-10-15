class_name LunarInterior
extends Node3D

func _ready() -> void:
	_build()
	visible = false

func _build() -> void:
	_box(self, Vector3(0, -0.12, 0), Vector3(6.2, 0.25, 5.2), Color("3c4d5d"))
	_box(self, Vector3(0, 1.3, -2.45), Vector3(6.2, 2.5, 0.18), Color("9caeba"))
	_box(self, Vector3(-3.05, 1.3, 0), Vector3(0.18, 2.5, 5.0), Color("768a9a"))
	_box(self, Vector3(3.05, 1.3, 0), Vector3(0.18, 2.5, 5.0), Color("768a9a"))
	for x in [-2.4, -1.2, 0.0, 1.2, 2.4]:
		_box(self, Vector3(x, 2.5, -2.3), Vector3(0.09, 0.1, 0.6), Color("f2b663"), true)
	_box(self, Vector3(-1.55, 0.68, -1.65), Vector3(1.7, 1.25, 0.78), Color("263d50"))
	_box(self, Vector3(-1.55, 1.07, -1.2), Vector3(1.22, 0.58, 0.08), Color("67dad5"), true)
	_box(self, Vector3(1.55, 0.68, -1.65), Vector3(1.7, 1.25, 0.78), Color("263d50"))
	_box(self, Vector3(1.55, 1.07, -1.2), Vector3(1.22, 0.58, 0.08), Color("f2b663"), true)
	_box(self, Vector3(0, 0.55, -2.27), Vector3(0.9, 1.1, 0.12), Color("263d50"))
	_box(self, Vector3(0, 1.1, -2.18), Vector3(0.58, 0.4, 0.05), Color("67dad5"), true)
	for x in [-2.55, 2.55]:
		_box(self, Vector3(x, 0.08, 1.4), Vector3(0.35, 0.12, 1.2), Color("f2b663"), true)
	var astronaut := MeshInstance3D.new()
	astronaut.mesh = load("res://assets/kenney_space_kit/astronautA.obj")
	astronaut.scale = Vector3.ONE * 1.22
	astronaut.position = Vector3(0, 0.08, 0.95)
	add_child(astronaut)
	var light := OmniLight3D.new(); light.position = Vector3(0, 2.1, 0)
	light.light_color = Color("b8cee0"); light.light_energy = 0.9; light.omni_range = 7.5
	add_child(light)

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, glow: bool = false) -> void:
	var mesh := MeshInstance3D.new(); mesh.mesh = BoxMesh.new()
	mesh.position = position; mesh.scale = size
	var material := StandardMaterial3D.new(); material.albedo_color = color
	material.metallic = 0.22; material.roughness = 0.58
	if glow:
		material.emission_enabled = true; material.emission = color
		material.emission_energy_multiplier = 0.65
	mesh.material_override = material
	parent.add_child(mesh)
