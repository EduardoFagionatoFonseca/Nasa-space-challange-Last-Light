extends SceneTree

func _initialize() -> void:
	for name in ["astronautA", "craterLarge", "hangar_roundGlass", "machine_generator", "rock_largeA", "rover", "satelliteDish_detailed"]:
		var path: String = "res://assets/kenney_space_kit/%s.obj" % name
		var mesh: Resource = load(path)
		if not mesh is Mesh:
			push_error("Could not import " + name)
			quit(1)
			return
		print(name, " ", (mesh as Mesh).get_aabb())
	print("ASSET IMPORT PASSED")
	quit(0)
