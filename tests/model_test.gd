extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var m := MissionModel.new()
	_check(m.day == 1 and m.day_seconds_left == 60.0, "timed initial state")
	_check(not m.do_action("invalid"), "invalid action rejected")
	_check(m.do_action("rescue") and m.rescue == 1, "rescue step")
	var oxygen_before: int = m.resources["oxygen"]
	m.tick(30.0)
	_check(m.day_seconds_left == 30.0 and int(m.resources["oxygen"]) < oxygen_before, "resources drain during day")
	m.tick(30.0); m.end_day()
	_check(m.day == 2 and not m.panels_ok and m.day_seconds_left == 60.0, "solar failure and next window")
	_check(m.do_action("solar") and m.panels_ok, "solar repair")
	m.record_repair_failure("water")
	_check(not m.can_do("water") and m.resources["energy"] < 100, "five mistakes lock repair and cost resources")
	m.tick(60.0); m.end_day()
	_check(m.day == 3 and m.can_do("water"), "repair unlocks next day")
	_check(not m.can_do("landing"), "landing requires impact assessment")
	_check(m.inspect_anomaly() and m.science == 1 and m.can_do("landing"), "crater unlocks landing")
	m.inside_base = true; m.suit_oxygen = 49.0
	var base_oxygen: int = m.resources["oxygen"]
	_check(m.refill_suit() and m.suit_oxygen == 100.0 and int(m.resources["oxygen"]) < base_oxygen, "suit refill draws base oxygen")
	var restored := MissionModel.from_data(m.to_data())
	_check(restored.day == m.day and restored.suit_oxygen == 100.0 and restored.science == 1, "new state persists")
	if failures.is_empty():
		print("MODEL TESTS PASSED")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
