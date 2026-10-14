class_name MissionModel
extends RefCounted

signal changed
signal finished

var day: int = 1
var actions_left: int = 2
var resources: Dictionary = MissionConfig.START.duplicate(true)
var shelter: int = 48
var rescue: int = 0
var panels_ok: bool = true
var recycler_ok: bool = true
var leak: bool = false
var comms_ok: bool = true
var science: int = 0
var ended: bool = false
var won: bool = false
var outcome: String = ""
var log: Array[String] = []
var history: Array[String] = []

func _init() -> void:
	log.append("DIA 1 • Sistemas em modo de contingência. O resgate chega no sétimo dia.")

func can_do(action: String) -> bool:
	if ended or actions_left <= 0 or not MissionConfig.ACTIONS.has(action):
		return false
	var costs: Dictionary = MissionConfig.ACTIONS[action]["cost"]
	for key in costs:
		if int(resources[key]) < int(costs[key]):
			return false
	if action == "rescue" and rescue >= 3:
		return false
	if action == "solar" and panels_ok and int(resources["energy"]) >= 90:
		return false
	return true

func do_action(action: String) -> bool:
	if not can_do(action):
		return false
	var entry: Dictionary = MissionConfig.ACTIONS[action]
	for key in entry["cost"]:
		resources[key] = int(resources[key]) - int(entry["cost"][key])
	for key in entry["gain"]:
		resources[key] = mini(MissionConfig.MAX_RESOURCE, int(resources[key]) + int(entry["gain"][key]))
	match action:
		"solar": panels_ok = true
		"oxygen":
			if leak:
				leak = false
				log.append("Vazamento selado durante a manutenção do circuito de oxigênio.")
		"water":
			if not recycler_ok:
				recycler_ok = true
				log.append("Filtro de recuperação substituído.")
		"shelter": shelter = mini(100, shelter + 28)
		"rescue":
			if not comms_ok:
				comms_ok = true
				log.append("Antena reconfigurada; contato com a nave restaurado.")
			rescue += 1
	actions_left -= 1
	var text_line: String = "DIA %d • %s." % [day, entry["title"]]
	log.append(text_line)
	history.append(text_line)
	changed.emit()
	return true

func inspect_anomaly() -> bool:
	if day != 3 or actions_left <= 0 or int(resources["energy"]) < 4 or ended or science > 0:
		return false
	resources["energy"] = int(resources["energy"]) - 4
	actions_left -= 1
	science = 1
	log.append("DIA 3 • O sinal desconhecido era reflexão de rádio no relevo. Dados científicos registrados.")
	history.append("Anomalia investigada sem atribuir origem extraterrestre.")
	changed.emit()
	return true

func end_day() -> void:
	if ended:
		return
	var solar_gain: int = 14 if panels_ok else 5
	if day == 4:
		solar_gain = 3 if panels_ok else 1
	resources["energy"] = mini(100, int(resources["energy"]) + solar_gain - 10)
	resources["oxygen"] = int(resources["oxygen"]) - 9 - (6 if leak else 0)
	resources["water"] = int(resources["water"]) - 8 + (5 if recycler_ok else 2)
	resources["supplies"] = int(resources["supplies"]) - 7
	log.append("DIA %d • Balanço: solar +%d, base −10 energia; tripulação −9 O₂, −8 água, −7 suprimentos." % [day, solar_gain])
	if day == 4:
		if shelter < 60:
			_fail("O abrigo não resistiu à tempestade solar. A missão foi interrompida.")
			return
		shelter -= 25
		log.append("A tempestade passou. O abrigo perdeu 25 pontos de integridade.")
	for key in resources:
		if int(resources[key]) <= 0:
			_fail("O sistema de %s chegou a zero; a tripulação não pode continuar." % _resource_name(key))
			return
	if day == 7:
		if rescue < 3:
			_fail("A nave chegou, mas os três procedimentos de resgate não foram concluídos.")
		elif shelter < 20:
			_fail("A estação ficou instável demais para um resgate seguro.")
		else:
			ended = true
			won = true
			outcome = "A baliza guiou a nave através da última luz. A tripulação voltou para casa."
			log.append("MISSÃO CONCLUÍDA • Tripulação resgatada.")
			changed.emit()
			finished.emit()
		return
	day += 1
	actions_left = 2
	_apply_day_event()
	changed.emit()

func _apply_day_event() -> void:
	match day:
		2:
			panels_ok = false
			log.append("DIA 2 • Falha solar: produção cai de +14 para +5 por dia.")
		3:
			log.append("DIA 3 • Alerta solar para o dia 4. A anomalia de rádio pode ser investigada.")
		4:
			log.append("DIA 4 • Tempestade solar em curso. Integridade 60 exigida ao fim do dia.")
		5:
			recycler_ok = false
			log.append("DIA 5 • Falha no filtro: recuperação de água cai de +5 para +2 por dia.")
		6:
			leak = true
			comms_ok = false
			log.append("DIA 6 • Vazamento de O₂ e antena fora de alinhamento.")
		7:
			log.append("DIA 7 • Última luz. A nave de resgate iniciou a aproximação.")

func _fail(reason: String) -> void:
	ended = true
	won = false
	outcome = reason
	log.append("MISSÃO ENCERRADA • " + reason)
	changed.emit()
	finished.emit()

func _resource_name(key: String) -> String:
	match key:
		"energy": return "energia"
		"oxygen": return "oxigênio"
		"water": return "água"
		_: return "suprimentos"

func score() -> int:
	var value: int = (70 if won else (day - 1) * 7) + rescue * 8 + science * 12
	for key in resources:
		value += maxi(0, int(resources[key])) / 8
	value += maxi(0, shelter) / 5
	return value

func to_data() -> Dictionary:
	return {"day": day, "actions_left": actions_left, "resources": resources.duplicate(true), "shelter": shelter,
		"rescue": rescue, "panels_ok": panels_ok, "recycler_ok": recycler_ok, "leak": leak,
		"comms_ok": comms_ok, "science": science, "ended": ended, "won": won,
		"outcome": outcome, "log": log.duplicate(), "history": history.duplicate()}

static func from_data(data: Dictionary) -> MissionModel:
	var m := MissionModel.new()
	m.day = clampi(int(data.get("day", 1)), 1, 7)
	m.actions_left = clampi(int(data.get("actions_left", 2)), 0, 2)
	var loaded: Dictionary = data.get("resources", {})
	for key in MissionConfig.START:
		m.resources[key] = clampi(int(loaded.get(key, MissionConfig.START[key])), 0, 100)
	m.shelter = clampi(int(data.get("shelter", 48)), 0, 100)
	m.rescue = clampi(int(data.get("rescue", 0)), 0, 3)
	m.panels_ok = bool(data.get("panels_ok", true))
	m.recycler_ok = bool(data.get("recycler_ok", true))
	m.leak = bool(data.get("leak", false))
	m.comms_ok = bool(data.get("comms_ok", true))
	m.science = clampi(int(data.get("science", 0)), 0, 1)
	m.ended = bool(data.get("ended", false))
	m.won = bool(data.get("won", false))
	m.outcome = str(data.get("outcome", ""))
	m.log.clear()
	for item in data.get("log", []): m.log.append(str(item))
	m.history.clear()
	for item in data.get("history", []): m.history.append(str(item))
	return m

