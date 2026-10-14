extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var m := MissionModel.new()
	_check(m.day == 1 and m.actions_left == 2, "initial state")
	_check(not m.do_action("invalid"), "invalid action rejected")
	_check(m.do_action("rescue"), "rescue step one")
	_check(m.rescue == 1 and m.actions_left == 1, "rescue costs action")
	m.end_day()
	_check(m.day == 2 and not m.panels_ok, "day two event")
	_check(m.do_action("solar") and m.panels_ok, "solar repair")
	m.end_day()
	_check(m.day == 3, "day three")
	_check(m.do_action("shelter") and m.shelter >= 60, "storm preparation")
	m.end_day()
	_check(m.day == 4, "storm day")
	_check(m.do_action("food"), "storm day provisions")
	m.end_day()
	_check(not m.ended and m.shelter >= 20, "shield survives")
	_check(m.day == 5 and not m.recycler_ok, "water crisis")
	_check(m.do_action("water") and m.recycler_ok, "water filter repair")
	_check(m.do_action("food"), "water crisis provisions")
	m.end_day()
	_check(m.day == 6 and m.leak and not m.comms_ok, "day six failures")
	_check(m.do_action("oxygen") and not m.leak, "leak repair")
	_check(m.do_action("rescue") and m.comms_ok, "antenna repair")
	m.end_day()
	_check(m.day == 7, "last light")
	_check(m.do_action("rescue"), "rescue step three")
	m.end_day()
	_check(m.ended and m.won, "complete winning path")
	var roundtrip := MissionModel.from_data(m.to_data())
	_check(roundtrip.day == m.day and roundtrip.rescue == m.rescue, "save roundtrip")
	var lose := MissionModel.new()
	for i in range(3): lose.end_day()
	lose.end_day()
	_check(lose.ended and not lose.won, "storm failure")
	if failures.is_empty():
		print("MODEL TESTS PASSED")
		quit(0)
	else:
		for item in failures: push_error(item)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
