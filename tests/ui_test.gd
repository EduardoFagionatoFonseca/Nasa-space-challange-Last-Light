extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._new_game()
	await process_frame
	_check(game.objective_site == "antenna" and game.clock_label.text == "01:00", "broad objective and countdown")
	var point: Vector2 = game.camera.unproject_position(game.world.site_nodes["antenna"].global_position + Vector3(0, 1.0, 0))
	game._click_to_walk(point)
	for i in range(180): game._move_player(1.0 / 60.0)
	game._update_nearby()
	_check(game.nearby_site == "antenna", "click walks to module")
	game.world.astronaut.position = Vector3(1.1, 0.17, 1.1)
	game._update_nearby(); game._interact()
	_check(game.model.inside_base and game.interior.visible and not game.world.visible, "habitat has visible interior")
	game.model.suit_oxygen = 55.0
	var reserve: int = game.model.resources["oxygen"]
	game._refill_suit()
	_check(game.model.suit_oxygen == 100.0 and int(game.model.resources["oxygen"]) < reserve, "refill uses base reserve")
	game._exit_habitat()
	_check(not game.model.inside_base and game.world.visible, "can leave habitat")
	_repair(game, "rescue"); _repair(game, "oxygen")
	game.world.astronaut.position = Vector3(1.1, 0.17, 1.1)
	game._update_nearby(); game._interact()
	game._process(60.0)
	_check(game.model.day == 2, "clock advances day automatically")
	game._exit_habitat()
	_repair(game, "solar"); _repair(game, "rescue"); _next(game)
	_check(game.model.day == 3 and game.world.site_nodes["crater"].visible, "new crater appears")
	var crater: Vector3 = game.world.site_nodes["crater"].position
	game.world.astronaut.position = crater + Vector3(0.8, 0.09, 0)
	game._update_nearby(); game._interact()
	_check(game.model.science == 1, "crater investigation records data")
	_repair(game, "shelter"); _next(game)
	_repair(game, "water"); _repair(game, "rescue"); _next(game)
	_repair(game, "water"); _repair(game, "food"); _next(game)
	_repair(game, "oxygen"); _repair(game, "food"); _next(game)
	_repair(game, "landing"); _repair(game, "oxygen"); _next(game)
	_check(game.model.won and game.model.landing_prepared, "guided campaign wins with landing zone")
	var restored: MissionModel = MissionSave.load_game()
	_check(restored != null and restored.won and restored.landing_prepared, "new mission state saved")
	game._new_game()
	game.model.suit_oxygen = 29.0; game._refresh()
	_check(game.objective_site == "habitat", "low suit oxygen guides return")
	game.model.suit_oxygen = 100.0; game._refresh()
	_goto(game, "oxygen")
	game._interact()
	var first_readings: Array[String] = game.puzzle_options.duplicate()
	game._cancel_repair(); game._interact()
	_check(game.puzzle_options != first_readings, "diagnostic fault changes position")
	game._cancel_repair()
	_goto(game, "antenna")
	game._interact()
	for i in range(5):
		game.gauge_needle.position.x = 0.0
		game._check_repair()
	_check(game.repair_action == "" and not game.model.can_do("rescue") and game.model.resources["energy"] == 62, "five misses penalize and lock repair")
	game.model.day = 4; game.model.shelter = 76; game.model.day_seconds_left = 29.0
	game._update_storm(8.1)
	_check(game.model.ended and game.model.outcome.contains("radiação"), "radiation outside shelter is fatal")
	game._new_game()
	game.model.suit_oxygen = 0.5
	game._process(0.5)
	_check(game.model.ended and game.model.outcome.contains("traje"), "suit oxygen is a real danger")
	MissionSave.clear()
	game.queue_free()
	await create_timer(0.3).timeout
	if failures.is_empty():
		print("UI TEST PASSED")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _goto(game: Node3D, site: String) -> void:
	var center: Vector3 = game.world.site_nodes[site].position
	var offset := Vector3(1.3, 0, 0)
	if site == "solar": offset = Vector3(1.5, 0, 0)
	if site == "oxygen": offset = Vector3(-1.3, 0, 0)
	if site == "greenhouse": offset = Vector3(0, 0, -1.5)
	if site == "shelter": offset = Vector3(-1.3, 0, 0)
	if site == "landing": offset = Vector3(0, 0, 1.35)
	game.world.astronaut.position = center + offset
	game.world.astronaut.position.y = 0.17
	game._update_nearby()
	_check(game.nearby_site == site, "%s reached" % site)

func _repair(game: Node3D, action: String) -> void:
	_goto(game, str(MissionConfig.ACTIONS[action]["site"]))
	game._interact()
	_check(game.repair_action == action, "%s starts" % action)
	if game.repair_action != action: return
	match game.puzzle_kind:
		"timing":
			for i in range(2):
				game.gauge_needle.position.x = game.repair_target * maxf(1.0, game.gauge.size.x - 5.0)
				game._check_repair()
		"diagnostic":
			for i in range(3):
				if game.puzzle_options[i].ends_with("43"):
					game._on_choice(i)
					break
		"sequence":
			var order: Array = {"solar": ["O₂", "HAB", "COM"], "water": ["Bomba", "Filtro", "Teste"],
				"food": ["Água", "Nutrientes", "Luz"], "landing": ["Varrer", "Baliza", "Confirmar"]}[action]
			for label in order:
				game._on_choice(game.puzzle_options.find(label))
	_check(game.repair_action == "", "%s completes" % action)

func _next(game: Node3D) -> void:
	game.model.tick(60.0)
	game._end_day()

func _check(value: bool, label: String) -> void:
	if not value: failures.append(label)
