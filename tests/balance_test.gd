extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var complete := _play(true, true)
	var no_landing := _play(true, false)
	var no_rescue := _play(false, true)
	_check(complete.ended and complete.won, "guided route survives seven timed windows")
	_check(no_landing.ended and not no_landing.won and no_landing.outcome.contains("pouso"), "landing preparation required")
	_check(no_rescue.ended and not no_rescue.won and no_rescue.rescue == 2, "three rescue steps required")
	var no_shelter := MissionModel.new()
	for i in range(4):
		no_shelter.tick(60.0); no_shelter.end_day()
	_check(no_shelter.ended and no_shelter.outcome.contains("abrigo"), "solar event needs shelter")
	var no_oxygen := MissionModel.new()
	no_oxygen.resources["oxygen"] = 1
	no_oxygen.tick(10.0)
	_check(no_oxygen.ended and no_oxygen.outcome.contains("oxigênio"), "oxygen depletes in real time")
	if failures.is_empty():
		print("BALANCE TESTS PASSED; guided score %d" % complete.score())
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _play(final_rescue: bool, landing: bool) -> MissionModel:
	var m := MissionModel.new()
	m.do_action("rescue"); m.do_action("oxygen"); _next(m)
	m.do_action("solar"); m.do_action("rescue"); _next(m)
	m.inspect_anomaly(); m.do_action("shelter"); _next(m)
	m.do_action("water")
	if final_rescue: m.do_action("rescue")
	_next(m)
	m.do_action("water"); m.do_action("food"); _next(m)
	m.do_action("oxygen"); m.do_action("food"); _next(m)
	if landing: m.do_action("landing")
	m.do_action("oxygen"); _next(m)
	return m

func _next(m: MissionModel) -> void:
	m.tick(60.0)
	if not m.ended: m.end_day()

func _check(value: bool, name: String) -> void:
	if not value: failures.append(name)
