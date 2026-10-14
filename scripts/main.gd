extends Node3D

const CYAN := Color("67dad5")
const WARM := Color("f2b663")
const RED := Color("ea695d")
const WHITE := Color("e8edf1")
const MUTED := Color("a2afbf")
const PANEL := Color(0.045, 0.075, 0.12, 0.84)
const SITE_ACTIONS := {"solar": "solar", "oxygen": "oxygen", "water": "water", "greenhouse": "food", "shelter": "shelter", "antenna": "rescue"}
const SITE_NAMES := {"habitat": "habitat", "solar": "painéis solares", "oxygen": "módulo de oxigênio", "water": "reciclador de água", "greenhouse": "estufa", "shelter": "abrigo", "antenna": "antena", "landing": "plataforma de pouso"}
const DAILY_ROUTE := {
	1: ["rescue", "oxygen"], 2: ["solar", "rescue"], 3: ["shelter", "food"],
	4: ["water", "rescue"], 5: ["water", "food"], 6: ["oxygen", "shelter"],
	7: ["food", "oxygen"]
}

var model: MissionModel
var world: LunarDiorama
var camera: Camera3D
var sound: Soundscape
var sun_light: DirectionalLight3D
var hud: Control
var menu: ColorRect
var modal: ColorRect
var modal_box: VBoxContainer
var day_label: Label
var objective_label: Label
var prompt_label: Label
var hint_label: Label
var rescue_label: Label
var prompt_panel: PanelContainer
var resource_bars: Dictionary = {}
var resource_labels: Dictionary = {}
var repair_panel: PanelContainer
var repair_title: Label
var repair_hint: Label
var gauge: Control
var gauge_target: ColorRect
var gauge_needle: ColorRect
var selected_site: String = ""
var objective_site: String = "antenna"
var nearby_site: String = ""
var repair_action: String = ""
var repair_hits: int = 0
var repair_clock: float = 0.0
var repair_target: float = 0.5
var toast_clock: float = 0.0
var move_target: Vector3 = Vector3.INF
var walk_clock: float = 0.0

func _ready() -> void:
	_build_environment()
	world = LunarDiorama.new(); add_child(world)
	sound = Soundscape.new(); add_child(sound)
	model = MissionModel.new()
	_build_ui()
	_refresh()
	_show_menu()

func _process(delta: float) -> void:
	if menu.visible or modal.visible or model.ended:
		return
	if repair_action != "":
		repair_clock += delta
		_update_gauge()
		return
	_move_player(delta)
	_update_nearby()
	if toast_clock > 0.0:
		toast_clock -= delta
		if toast_clock <= 0.0:
			_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not menu.visible:
		if repair_action != "": _cancel_repair()
		elif modal.visible: modal.visible = false
		else: _show_pause()
		get_viewport().set_input_as_handled()
		return
	if menu.visible or modal.visible or model.ended:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if repair_action == "": _interact()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and repair_action != "":
			_check_repair()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and repair_action == "":
		_click_to_walk(event.position)

func _build_environment() -> void:
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.8; camera.position = Vector3(10.5, 13.0, 16.0)
	add_child(camera); camera.look_at(Vector3(0, 0, 0)); camera.current = true
	sun_light = DirectionalLight3D.new(); sun_light.rotation_degrees = Vector3(-53, -32, 0)
	sun_light.light_color = Color("f5dfc0"); sun_light.light_energy = 1.25; sun_light.shadow_enabled = true; add_child(sun_light)
	var fill := OmniLight3D.new(); fill.position = Vector3(-5, 7, 4)
	fill.light_color = CYAN; fill.light_energy = 0.55; fill.omni_range = 22; add_child(fill)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("09111e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8897ae")
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var earth := MeshInstance3D.new(); var sphere := SphereMesh.new()
	sphere.radial_segments = 24; sphere.rings = 12; earth.mesh = sphere
	earth.position = Vector3(-6.5, -1.1, -9.0); earth.scale = Vector3.ONE * 1.08
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_back;
void fragment() {
	float land = sin(UV.x * 9.0 + sin(UV.y * 8.0) * 1.5) * cos(UV.y * 13.0 - sin(UV.x * 5.0) * 1.2);
	float cloud = sin(UV.x * 27.0 + UV.y * 8.0) * cos(UV.y * 20.0 - UV.x * 3.0);
	vec3 color = mix(vec3(0.045, 0.24, 0.5), vec3(0.11, 0.38, 0.31), smoothstep(0.42, 0.65, land));
	color = mix(color, vec3(0.78, 0.89, 0.94), smoothstep(0.65, 0.85, cloud) * 0.35);
	ALBEDO = color; EMISSION = color * 0.28;
}"""
	var material := ShaderMaterial.new(); material.shader = shader
	earth.material_override = material; add_child(earth)
	var screen: Vector2 = get_viewport().get_visible_rect().size
	for i in range(54):
		var star := MeshInstance3D.new(); var dot := SphereMesh.new(); dot.radial_segments = 4; dot.rings = 2
		var nx: float = fposmod(sin(float(i) * 78.233) * 43758.5453, 1.0)
		var ny: float = fposmod(sin(float(i) * 13.913) * 25432.3531, 1.0)
		var point := Vector2(screen.x * (0.25 + nx * 0.5), screen.y * ((0.12 + ny * 0.13) if i < 27 else (0.78 + ny * 0.14)))
		star.mesh = dot; star.position = camera.project_position(point, 35.0)
		star.scale = Vector3.ONE * (0.014 + float(i % 3) * 0.01)
		var glow := StandardMaterial3D.new(); glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color(0.8, 0.91, 1.0, 0.75); glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		star.material_override = glow; add_child(star)

func _build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(hud)
	var top := _panel(hud, Vector2(22, 18), Vector2(392, 105))
	var top_column := _column(top, 10)
	var heading := HBoxContainer.new(); top_column.add_child(heading)
	day_label = _label(heading, "DIA 1 / 7", 22, WARM)
	var brand := _label(heading, "LAST LIGHT", 13, MUTED)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_label = _label(top_column, "", 17, WHITE)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vitals := _panel(hud, Vector2(-260, 18), Vector2(-22, 155), true)
	var vitals_column := _column(vitals, 7)
	for key in ["energy", "oxygen", "water", "supplies"]:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 8); vitals_column.add_child(row)
		var label := _label(row, {"energy":"⚡", "oxygen":"O₂", "water":"H₂O", "supplies":"▣"}[key], 13, MUTED)
		label.custom_minimum_size.x = 34
		var bar := ProgressBar.new(); bar.custom_minimum_size = Vector2(135, 10)
		bar.max_value = 100; bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_theme_stylebox_override("background", _style(Color("263544"), 5))
		row.add_child(bar); resource_bars[key] = bar
		var value := _label(row, "", 12, MUTED); value.custom_minimum_size.x = 24
		resource_labels[key] = value
	var mission_status := _panel(hud, Vector2(22, -65), Vector2(270, -18))
	mission_status.anchor_top = 1.0; mission_status.anchor_bottom = 1.0
	var status_column := _column(mission_status, 5)
	rescue_label = _label(status_column, "", 14, CYAN)
	prompt_panel = _panel(hud, Vector2(-320, -108), Vector2(320, -18))
	prompt_panel.anchor_left = 0.5; prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0; prompt_panel.anchor_bottom = 1.0
	var prompt_column := _column(prompt_panel, 7)
	prompt_label = _label(prompt_column, "", 20, WHITE)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = _label(prompt_column, "WASD / setas para andar  •  clique para ir", 13, MUTED)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	repair_panel = _panel(hud, Vector2(-275, -175), Vector2(275, -18))
	repair_panel.anchor_left = 0.5; repair_panel.anchor_right = 0.5
	repair_panel.anchor_top = 1.0; repair_panel.anchor_bottom = 1.0
	var repair_column := _column(repair_panel, 11)
	repair_title = _label(repair_column, "", 20, WARM)
	repair_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	repair_hint = _label(repair_column, "", 14, MUTED)
	repair_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gauge = Control.new(); gauge.custom_minimum_size = Vector2(470, 32); repair_column.add_child(gauge)
	var track := ColorRect.new(); track.color = Color("263544")
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); track.offset_top = 10; track.offset_bottom = -10
	gauge.add_child(track)
	gauge_target = ColorRect.new(); gauge_target.color = CYAN
	gauge_target.position = Vector2(220, 7); gauge_target.size = Vector2(64, 18); gauge.add_child(gauge_target)
	gauge_needle = ColorRect.new(); gauge_needle.color = WHITE
	gauge_needle.position = Vector2(0, 3); gauge_needle.size = Vector2(5, 26); gauge.add_child(gauge_needle)
	repair_panel.visible = false
	menu = ColorRect.new(); menu.color = Color(0.015, 0.035, 0.065, 0.74)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.add_child(menu)
	modal = ColorRect.new(); modal.color = Color(0.015, 0.035, 0.065, 0.68)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.add_child(modal)
	modal_box = _center_box(modal); modal.visible = false

func _move_player(delta: float) -> void:
	var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var direction := Vector3.ZERO
	if x != 0.0 or y != 0.0:
		var right: Vector3 = camera.global_basis.x; right.y = 0.0; right = right.normalized()
		var forward: Vector3 = camera.global_basis.z; forward.y = 0.0; forward = forward.normalized()
		direction = (right * x + forward * y).normalized()
		move_target = Vector3.INF
	elif move_target != Vector3.INF:
		var delta_to: Vector3 = move_target - world.astronaut.position; delta_to.y = 0.0
		if delta_to.length() > 0.15: direction = delta_to.normalized()
		else: move_target = Vector3.INF
	if direction == Vector3.ZERO:
		world.astronaut.position.y = lerpf(world.astronaut.position.y, 0.42, minf(1.0, delta * 10.0))
		return
	var next: Vector3 = world.astronaut.position + direction * delta * 2.75
	var flat := Vector2(next.x, next.z)
	if flat.length() > 5.22:
		flat = flat.normalized() * 5.22
	for site in world.site_nodes:
		var center: Vector3 = world.site_nodes[site].position
		var radius: float = 1.16 if site == "habitat" else (1.08 if site == "greenhouse" else (0.94 if site in ["oxygen", "water", "shelter"] else 0.43))
		var offset := flat - Vector2(center.x, center.z)
		if offset.length() < radius:
			flat = Vector2(center.x, center.z) + offset.normalized() * radius
	world.astronaut.position.x = flat.x; world.astronaut.position.z = flat.y
	world.astronaut.rotation.y = lerp_angle(world.astronaut.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 12.0))
	walk_clock += delta * 13.0
	world.astronaut.position.y = 0.42 + absf(sin(walk_clock)) * 0.055

func _click_to_walk(point: Vector2) -> void:
	var origin: Vector3 = camera.project_ray_origin(point)
	var direction: Vector3 = camera.project_ray_normal(point)
	if absf(direction.y) < 0.001: return
	var travel: float = -origin.y / direction.y
	if travel < 0.0: return
	var hit: Vector3 = origin + direction * travel
	if Vector2(hit.x, hit.z).length() > 5.2: return
	move_target = Vector3(hit.x, 0.42, hit.z)

func _update_nearby() -> void:
	var best := 99.0
	var nearest := ""
	for site in world.site_nodes:
		var center: Vector3 = world.site_nodes[site].position
		var distance := Vector2(world.astronaut.position.x - center.x, world.astronaut.position.z - center.z).length()
		var reach := 1.85 if site == "solar" else (1.7 if site in ["habitat", "greenhouse", "shelter"] else 1.42)
		if distance < reach and distance < best:
			best = distance; nearest = site
	if nearest != nearby_site:
		nearby_site = nearest
		if toast_clock <= 0.0: _update_prompt()

func _update_prompt() -> void:
	if repair_action != "": return
	if nearby_site == "":
		prompt_label.text = "Siga o marcador luminoso"
		hint_label.text = "WASD / setas para andar  •  clique para ir"
	elif nearby_site == "habitat":
		prompt_label.text = "[E] Encerrar o dia"
		hint_label.text = "%d tarefa(s) restante(s)  •  ESC pausa" % model.actions_left
	elif nearby_site == "landing" and model.day == 3 and model.science == 0:
		prompt_label.text = "[E] Investigar sinal"
		hint_label.text = "Pesquisa opcional"
	elif SITE_ACTIONS.has(nearby_site):
		var action: String = SITE_ACTIONS[nearby_site]
		prompt_label.text = "[E] %s" % MissionConfig.ACTIONS[action]["title"]
		hint_label.text = "Calibre o equipamento com ESPAÇO"
	else:
		prompt_label.text = SITE_NAMES.get(nearby_site, "Base lunar").capitalize()
		hint_label.text = "Siga o marcador luminoso"

func _interact() -> void:
	_update_nearby()
	if nearby_site == "habitat":
		if model.actions_left == 0: _end_day()
		else: _confirm_end_day()
	elif nearby_site == "landing" and model.day == 3 and model.science == 0:
		if model.inspect_anomaly():
			sound.cue("success"); MissionSave.save(model); _refresh(); _toast("Sinal pesquisado • dados enviados")
	elif SITE_ACTIONS.has(nearby_site):
		var action: String = SITE_ACTIONS[nearby_site]
		if not model.can_do(action):
			_toast("Sem recursos ou ações para este reparo")
			sound.cue("warning")
			return
		_start_repair(action)

func _start_repair(action: String) -> void:
	repair_action = action; repair_hits = 0; repair_clock = 0.0; repair_target = 0.5
	move_target = Vector3.INF
	repair_panel.visible = true
	prompt_panel.visible = false
	repair_title.text = str(MissionConfig.ACTIONS[action]["title"]).to_upper()
	repair_hint.text = "ESPAÇO no brilho azul  •  0 / 2"
	_update_gauge()
	sound.cue("click")

func _update_gauge() -> void:
	var width: float = maxf(1.0, gauge.size.x - 5.0)
	var pulse: float = 0.5 + 0.5 * sin(repair_clock * (3.8 + float(repair_hits) * 0.7) - PI * 0.5)
	gauge_needle.position.x = pulse * width
	gauge_target.position.x = repair_target * width - 32.0

func _check_repair() -> void:
	var pulse: float = gauge_needle.position.x / maxf(1.0, gauge.size.x - 5.0)
	if absf(pulse - repair_target) <= 0.092:
		repair_hits += 1
		sound.cue("action")
		repair_hint.text = "ESPAÇO no brilho azul  •  %d / 2" % repair_hits
		repair_clock = 0.0
		repair_target = 0.64 if repair_hits == 1 else 0.5
		if repair_hits >= 2: _complete_repair()
	else:
		sound.cue("warning")
		repair_hint.text = "Fora do pulso • tente de novo"

func _complete_repair() -> void:
	var action := repair_action
	_cancel_repair()
	if model.do_action(action):
		world.pulse(str(MissionConfig.ACTIONS[action]["site"]))
		sound.cue("success")
		MissionSave.save(model)
		_refresh()
		_toast("Sistema estabilizado")

func _cancel_repair() -> void:
	repair_action = ""
	repair_panel.visible = false
	prompt_panel.visible = true
	_update_prompt()

func _recommendation() -> String:
	if model.actions_left <= 0: return "habitat"
	for action in DAILY_ROUTE[model.day]:
		if not _did_today(action) and model.can_do(action): return str(MissionConfig.ACTIONS[action]["site"])
	for action in MissionConfig.ACTION_ORDER:
		if model.can_do(action): return str(MissionConfig.ACTIONS[action]["site"])
	return "habitat"

func _did_today(action: String) -> bool:
	var token := "DIA %d • %s." % [model.day, MissionConfig.ACTIONS[action]["title"]]
	return model.history.has(token)

func _refresh() -> void:
	world.set_model(model)
	sun_light.light_color = Color("fa9e82") if model.day == 4 else Color("f5dfc0")
	day_label.text = "DIA %d / 7" % model.day
	objective_site = _recommendation()
	world.select_site(objective_site)
	selected_site = objective_site
	if objective_site == "habitat":
		objective_label.text = "Volte ao habitat e encerre o dia"
	else:
		var action: String = SITE_ACTIONS[objective_site]
		objective_label.text = "%s  →  %s" % [str(MissionConfig.ACTIONS[action]["title"]), SITE_NAMES[objective_site]]
	rescue_label.text = "RESGATE %d / 3     •     %d / 2 reparos" % [model.rescue, 2 - model.actions_left]
	for key in resource_bars:
		var value: int = model.resources[key]
		resource_bars[key].value = value
		resource_bars[key].add_theme_stylebox_override("fill", _style(RED if value <= 18 else (WARM if value <= 35 else CYAN), 5))
		resource_labels[key].text = str(value)
		resource_bars[key].tooltip_text = "%s %d / 100" % [key, value]
	_update_nearby()
	_update_prompt()

func _toast(message: String) -> void:
	toast_clock = 2.3
	prompt_label.text = message
	hint_label.text = ""

func _end_day() -> void:
	modal.visible = false
	model.end_day(); MissionSave.save(model); _refresh()
	sound.cue("failure" if model.ended and not model.won else ("warning" if model.day in [4, 6] else "click"))
	if model.ended: _show_result()
	else:
		world.astronaut.position = Vector3(1.85, 0.42, 3.58)
		nearby_site = ""
		var alerts := {2: "Painéis avariados", 3: "Alerta solar", 4: "Tempestade solar", 5: "Filtro de água danificado", 6: "Vazamento de oxigênio", 7: "Nave de resgate à vista"}
		_toast("DIA %d  •  %s" % [model.day, alerts.get(model.day, "Continue")])

func _confirm_end_day() -> void:
	_show_modal("ENCERRAR DIA?", "Ainda há %d reparo(s) disponível(is)." % model.actions_left, [
		{"text": "CONTINUAR", "call": func(): modal.visible = false},
		{"text": "ENCERRAR", "call": _end_day}
	])

func _show_menu() -> void:
	menu.visible = true; modal.visible = false; repair_action = ""; repair_panel.visible = false
	prompt_panel.visible = true
	for child in menu.get_children(): child.queue_free()
	var box := _center_box(menu)
	_label(box, "L A S T   L I G H T", 30, WHITE)
	_label(box, "Sete dias para manter a base viva.", 16, WARM)
	_add_divider(box)
	var start := _button(box, "INICIAR MISSÃO", true); start.custom_minimum_size.y = 54
	start.pressed.connect(_new_game)
	var resume := _button(box, "CONTINUAR", false); resume.custom_minimum_size.y = 46
	resume.disabled = not MissionSave.exists(); resume.pressed.connect(_continue_game)
	var credits := _button(box, "CRÉDITOS / CIÊNCIA", false); credits.custom_minimum_size.y = 46
	credits.pressed.connect(_show_credits)

func _new_game() -> void:
	MissionSave.clear(); model = MissionModel.new()
	world.astronaut.position = Vector3(1.85, 0.42, 3.58)
	move_target = Vector3.INF; nearby_site = ""
	menu.visible = false; modal.visible = false
	sound.cue("click"); _refresh(); MissionSave.save(model)
	_toast("WASD para andar  •  E para interagir")

func _continue_game() -> void:
	var loaded := MissionSave.load_game()
	if loaded == null: return
	model = loaded; menu.visible = false; modal.visible = false
	world.astronaut.position = Vector3(1.85, 0.42, 3.58)
	move_target = Vector3.INF; nearby_site = ""
	sound.cue("click"); _refresh()
	if model.ended: _show_result()

func _show_pause() -> void:
	_show_modal("MISSÃO PAUSADA", "WASD / setas: mover     E: interagir     Espaço: calibrar", [
		{"text": "CONTINUAR", "call": func(): modal.visible = false},
		{"text": "CIÊNCIA", "call": _show_science},
		{"text": "MENU", "call": _show_menu}
	])

func _show_result() -> void:
	var title: String = "MISSÃO CONCLUÍDA" if model.won else "MISSÃO ENCERRADA"
	var body: String = ("A tripulação voltou para casa." if model.won else model.outcome) + "\n\nPontuação %d  •  Resgate %d / 3" % [model.score(), model.rescue]
	_show_modal(title, body, [
		{"text": "NOVA MISSÃO", "call": _new_game},
		{"text": "MENU", "call": _show_menu}
	])

func _show_science() -> void:
	_show_modal("CIÊNCIA DA MISSÃO", "Ar e água são reciclados em sistemas de suporte à vida. Painéis fornecem energia; abrigos reduzem a exposição à radiação. Os valores do jogo são simplificados.\n\nFontes NASA: ECLSS, Lunar Surface Technology e Space Radiation. Links em docs/SCIENCE.md.", [
		{"text": "VOLTAR", "call": _show_pause}
	])

func _show_credits() -> void:
	_show_modal("CRÉDITOS", "LAST LIGHT • cenário e áudio originais. Modelos 3D: Kenney Space Kit (CC0).\n\nConceitos científicos: NASA. Referências em docs/SCIENCE.md.", [
		{"text": "VOLTAR", "call": _show_menu}
	])

func _show_modal(title: String, body: String, buttons: Array) -> void:
	modal.visible = true
	for child in modal_box.get_children(): child.queue_free()
	_label(modal_box, title, 26, RED if title == "MISSÃO ENCERRADA" else WARM)
	_add_divider(modal_box)
	var content := _label(modal_box, body, 16, MUTED)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for item in buttons:
		var button := _button(modal_box, str(item["text"]), true)
		button.custom_minimum_size.y = 46
		button.pressed.connect(item["call"])

func _panel(parent: Control, top_left: Vector2, bottom_right: Vector2, right_anchor: bool = false) -> PanelContainer:
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", _style(PANEL, 13, Color("345163")))
	if right_anchor: panel.anchor_left = 1.0; panel.anchor_right = 1.0
	panel.offset_left = top_left.x; panel.offset_right = bottom_right.x
	panel.offset_top = top_left.y; panel.offset_bottom = bottom_right.y
	parent.add_child(panel)
	return panel

func _column(parent: Control, margin_size: int = 16) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, margin_size)
	parent.add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	return column

func _center_box(parent: Control) -> VBoxContainer:
	var panel := _panel(parent, Vector2(-260, -210), Vector2(260, 210))
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	return _column(panel, 24)

func _label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, important: bool) -> Button:
	var button := Button.new(); button.text = value
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_stylebox_override("normal", _style(Color("1c3042") if important else Color("172736"), 9, CYAN.darkened(0.65)))
	button.add_theme_stylebox_override("hover", _style(Color("2c5260"), 9, CYAN))
	button.add_theme_stylebox_override("pressed", _style(Color("355d6c"), 9, WARM))
	button.add_theme_stylebox_override("disabled", _style(Color("17202a"), 9))
	button.add_theme_color_override("font_disabled_color", Color("647386"))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	return button

func _style(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color
	style.corner_radius_top_left = radius; style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = 1; style.border_width_top = 1
	style.border_width_right = 1; style.border_width_bottom = 1
	return style

func _add_divider(parent: Control) -> void:
	var line := HSeparator.new(); line.add_theme_stylebox_override("separator", _style(Color("365063"), 0))
	parent.add_child(line)
