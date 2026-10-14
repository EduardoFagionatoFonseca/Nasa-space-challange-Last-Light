extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	game._new_game()
	await process_frame
	_assert(game.model.day == 1 and not game.menu.visible, "mission starts")
	_assert(game.hud.mouse_filter == Control.MOUSE_FILTER_IGNORE, "world input passes through HUD")
	_assert(game.objective_site == "antenna", "first objective points to rescue")
	game.world.astronaut.position = Vector3(1.1, 0.42, 1.1)
	game._update_nearby()
	_assert(game.nearby_site == "habitat", "habitat reached physically")
	game._click_to_walk(Vector2(800, 430))
	_assert(game.move_target != Vector3.INF, "click sets walking destination")
	game.move_target = Vector3.INF
	game.world.astronaut.position = Vector3(1.85, 0.42, 3.58)
	game._update_nearby()
	game._interact()
	_assert(game.repair_action == "", "cannot repair without reaching module")
	_repair(game, "rescue")
	_assert(game.model.rescue == 1 and game.model.actions_left == 1, "repair calibration commits one action")
	_assert(game.objective_site == "oxygen", "route advances after repair")
	_repair(game, "oxygen")
	_end_day(game)
	_assert(game.model.day == 2 and MissionSave.exists(), "day and save advance")
	_repair(game, "solar")
	_repair(game, "rescue")
	_end_day(game)
	_repair(game, "shelter")
	_repair(game, "food")
	_end_day(game)
	_repair(game, "water")
	_repair(game, "rescue")
	_end_day(game)
	_repair(game, "water")
	_repair(game, "food")
	_end_day(game)
	_repair(game, "oxygen")
	_repair(game, "shelter")
	_end_day(game)
	_repair(game, "food")
	_repair(game, "oxygen")
	_end_day(game)
	_assert(game.model.won, "guided seven day route wins")
	var restored: MissionModel = MissionSave.load_game()
	_assert(restored != null and restored.won and restored.score() == game.model.score(), "victory restored")
	MissionSave.clear()
	print("UI TEST PASSED")
	game.queue_free()
	await create_timer(0.35).timeout
	quit(0)

func _repair(game: Node3D, action: String) -> void:
	var site: String = MissionConfig.ACTIONS[action]["site"]
	var center: Vector3 = game.world.site_nodes[site].position
	var offset := Vector3(1.3, 0.25, 0)
	if site == "solar": offset = Vector3(1.5, 0.32, 0)
	if site == "oxygen": offset = Vector3(-1.3, 0.25, 0)
	if site == "greenhouse": offset = Vector3(0, 0.25, -1.5)
	if site == "shelter": offset = Vector3(-1.3, 0.25, 0)
	game.world.astronaut.position = center + offset
	game._update_nearby()
	_assert(game.nearby_site == site, "%s approached" % site)
	game._interact()
	_assert(game.repair_action == action, "%s starts calibration" % action)
	for step in range(2):
		game.gauge_needle.position.x = game.repair_target * maxf(1.0, game.gauge.size.x - 5.0)
		game._check_repair()
	_assert(game.repair_action == "", "%s calibration completes" % action)

func _end_day(game: Node3D) -> void:
	_assert(game.model.actions_left == 0, "two repairs complete")
	game.world.astronaut.position = Vector3(1.1, 0.42, 1.1)
	game._update_nearby()
	_assert(game.nearby_site == "habitat", "return to habitat")
	game._interact()
	game.modal.visible = false

func _assert(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
