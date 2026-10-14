extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var basic := _play(false, true)
	var research := _play(true, true)
	var missed_rescue := _play(false, false)
	_check(basic.ended and basic.won, "viable winning route")
	_check(research.ended and research.won and research.science == 1, "optional science route")
	_check(research.score() > basic.score(), "research changes final score")
	_check(missed_rescue.ended and not missed_rescue.won and missed_rescue.rescue == 2, "missing rescue loses")
	var no_shelter := MissionModel.new()
	for i in range(4): no_shelter.end_day()
	_check(no_shelter.ended and not no_shelter.won and no_shelter.outcome.contains("abrigo"), "storm requires preparation")
	var suffocation := MissionModel.new()
	suffocation.resources["oxygen"] = 1
	suffocation.end_day()
	_check(suffocation.ended and suffocation.outcome.contains("oxigênio"), "critical resource loss")
	if failures.is_empty():
		print("BALANCE TESTS PASSED; base score %d, science score %d" % [basic.score(), research.score()])
		quit(0)
	else:
		for item in failures: push_error(item)
		quit(1)

func _play(anomaly: bool, final_rescue: bool) -> MissionModel:
	var mission := MissionModel.new()
	mission.do_action("rescue"); mission.end_day()
	mission.do_action("solar"); mission.end_day()
	mission.do_action("shelter")
	if anomaly: mission.inspect_anomaly()
	mission.end_day()
	mission.do_action("food"); mission.end_day()
	mission.do_action("water"); mission.do_action("food"); mission.end_day()
	mission.do_action("oxygen"); mission.do_action("rescue"); mission.end_day()
	if final_rescue: mission.do_action("rescue")
	mission.end_day()
	return mission

func _check(value: bool, name: String) -> void:
	if not value: failures.append(name)
