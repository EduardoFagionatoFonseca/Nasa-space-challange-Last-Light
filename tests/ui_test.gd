extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	game._new_game()
	game.modal.visible = false
	_assert(game.model.day == 1 and not game.menu.visible, "start button")
	_assert(game.hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "scene clicks pass through HUD")
	game.world.select_site("habitat")
	_assert(not game.site_action_button.visible, "habitat has no action")
	await physics_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.camera.unproject_position(game.world.site_nodes["antenna"].global_position + Vector3(0, 0.65, 0))
	game._unhandled_input(click)
	_assert(game.selected_site == "antenna", "scene ray selects antenna")
	_assert(game.site_action_button.visible and not game.site_action_button.disabled, "context action available")
	game.site_action_button.pressed.emit()
	_assert(game.model.rescue == 1, "context action executes rescue preparation")
	game._end_day()
	_assert(game.model.day == 2 and MissionSave.exists(), "day advancement and autosave")
	game.modal.visible = false
	game._on_action("solar")
	game._end_day()
	game.modal.visible = false
	game._on_action("shelter")
	game._end_day()
	game.modal.visible = false
	game._on_action("food")
	game._end_day()
	game.modal.visible = false
	game._on_action("water")
	game._on_action("food")
	game._end_day()
	game.modal.visible = false
	game._on_action("oxygen")
	game._on_action("rescue")
	game._end_day()
	game.modal.visible = false
	game._on_action("rescue")
	game._end_day()
	_assert(game.model.won, "victory through UI flow")
	var restored: MissionModel = MissionSave.load_game()
	_assert(restored != null and restored.won and restored.score() == game.model.score(), "restored result")
	MissionSave.clear()
	print("UI TEST PASSED")
	game.queue_free()
	await create_timer(0.35).timeout
	quit(0)

func _assert(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
