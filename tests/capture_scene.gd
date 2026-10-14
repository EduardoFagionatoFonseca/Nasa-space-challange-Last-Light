extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await create_timer(0.5).timeout
	game.menu.visible = false
	print("EARTH SCREEN ", game.camera.unproject_position(Vector3(-6.5, 4.2, -9.0)))
	print("PAD SCREEN ", game.camera.unproject_position(Vector3(3.15, 0.05, -3.6)))
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://test_capture.png")
	print("CAPTURE ", image.get_size())
	quit(0)
