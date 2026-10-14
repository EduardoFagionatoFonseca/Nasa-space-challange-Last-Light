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
	game._on_action("rescue")
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
