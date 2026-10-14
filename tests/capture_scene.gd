extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await create_timer(0.5).timeout
	var view: String = "game"
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if not arguments.is_empty(): view = arguments[0]
	if view != "menu":
		game.menu.visible = false
	if view == "repair":
		game.world.astronaut.position = game.world.site_nodes["antenna"].position + Vector3(1.3, 0.25, 0)
		game.world.astronaut.position.y = 0.17
		game._update_nearby()
		game._interact()
	if view == "science": game._show_science()
	if view == "credits": game._show_credits()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png("res://test_capture_%s.png" % view)
	print("CAPTURE ", image.get_size())
	game.queue_free()
	await create_timer(0.35).timeout
	quit(0)
