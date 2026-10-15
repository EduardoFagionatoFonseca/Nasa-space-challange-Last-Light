extends Node3D

const CYAN := Color("67dad5")
const WARM := Color("f2b663")
const RED := Color("ea695d")
const WHITE := Color("e8edf1")
const MUTED := Color("a2afbf")
const PANEL := Color(0.045, 0.075, 0.12, 0.84)
const PLAYER_Y := 0.17
const SITE_ACTIONS := {"solar": "solar", "oxygen": "oxygen", "water": "water", "greenhouse": "food", "shelter": "shelter", "antenna": "rescue", "landing": "landing"}
const SITE_NAMES := {"habitat": "habitat", "solar": "painéis solares", "oxygen": "módulo de oxigênio", "water": "reciclador de água", "greenhouse": "estufa", "shelter": "abrigo", "antenna": "antena", "landing": "plataforma de pouso", "crater": "cratera recente"}
const DAILY_ROUTE := {
	1: ["rescue", "oxygen"], 2: ["solar", "rescue"], 3: ["shelter"],
	4: ["water", "rescue"], 5: ["water", "food"], 6: ["oxygen", "food"],
	7: ["landing", "oxygen"]
}
const GOALS := {"antenna": "Restabeleça contato para o resgate", "oxygen": "Estabilize o suporte de oxigênio",
	"solar": "Recupere a geração elétrica", "water": "Restabeleça o circuito de água",
	"greenhouse": "Garanta reservas para a tripulação", "shelter": "Prepare proteção para a tempestade",
	"crater": "Avalie o impacto recente", "landing": "Libere uma zona segura de pouso",
	"habitat": "Monitore os sistemas e o traje"}

var model: MissionModel
var world: LunarDiorama
var interior: LunarInterior
var camera: Camera3D
var sound: Soundscape
var sun_light: DirectionalLight3D
var fill_light: OmniLight3D
var earth_mesh: MeshInstance3D
var hud: Control
var menu: ColorRect
var modal: ColorRect
var modal_box: VBoxContainer
var day_label: Label
var clock_label: Label
var objective_label: Label
var prompt_label: Label
var hint_label: Label
var rescue_label: Label
var suit_label: Label
var prompt_panel: PanelContainer
var resource_bars: Dictionary = {}
var resource_labels: Dictionary = {}
var repair_panel: PanelContainer
var repair_title: Label
var repair_hint: Label
var gauge: Control
var gauge_target: ColorRect
var gauge_needle: ColorRect
var puzzle_choices: HBoxContainer
var choice_buttons: Array[Button] = []
var selected_site: String = ""
var objective_site: String = "antenna"
var nearby_site: String = ""
var repair_action: String = ""
var repair_hits: int = 0
var repair_clock: float = 0.0
var repair_target: float = 0.5
var repair_mistakes: int = 0
var puzzle_kind: String = "timing"
var suit_warned: bool = false
var storm_warned: bool = false
var storm_active_last: bool = false
var live_hud_clock: float = 0.0
var autosave_clock: float = 0.0
var toast_clock: float = 0.0
var move_target: Vector3 = Vector3.INF
var walk_clock: float = 0.0

func _ready() -> void:
	_build_environment()
	world = LunarDiorama.new(); add_child(world)
	interior = LunarInterior.new(); add_child(interior)
	sound = Soundscape.new(); add_child(sound)
	model = MissionModel.new()
	_build_ui()
	_refresh()
	_show_menu()

func _process(delta: float) -> void:
	if menu.visible or modal.visible or model.ended: return
	model.tick(delta)
	if model.ended:
		MissionSave.save(model); _show_result(); return
	if not model.inside_base:
		model.suit_oxygen = maxf(0.0, model.suit_oxygen - delta * 2.4)
		if model.suit_oxygen <= 30.0 and not suit_warned:
			suit_warned = true; sound.cue("warning"); _toast("O₂ do traje baixo • volte ao habitat")
		if model.suit_oxygen <= 0.0:
			model._fail("O oxigênio do traje acabou antes do retorno ao habitat.")
			MissionSave.save(model); _show_result(); return
	_update_storm(delta)
	if model.ended:
		MissionSave.save(model); _show_result(); return
	if model.day_seconds_left <= 0.0:
		if repair_action != "": _cancel_repair()
		_end_day()
		return
	live_hud_clock += delta; autosave_clock += delta
	if live_hud_clock >= 0.15:
		live_hud_clock = 0.0; _refresh_live()
	if autosave_clock >= 5.0:
		autosave_clock = 0.0; MissionSave.save(model)
	if repair_action != "":
		repair_clock += delta
		_update_gauge()
		return
	if not model.inside_base: _move_player(delta)
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
		elif event.keycode == KEY_F and model.inside_base:
			_refill_suit()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and repair_action == "" and not model.inside_base:
		_click_to_walk(event.position)

func _build_environment() -> void:
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.8; camera.position = Vector3(10.5, 13.0, 16.0)
	add_child(camera); camera.look_at(Vector3(0, 0, 0)); camera.current = true
	sun_light = DirectionalLight3D.new(); sun_light.rotation_degrees = Vector3(-53, -32, 0)
	sun_light.light_color = Color("f5dfc0"); sun_light.light_energy = 1.25; sun_light.shadow_enabled = true; add_child(sun_light)
	fill_light = OmniLight3D.new(); fill_light.position = Vector3(-5, 7, 4)
	fill_light.light_color = CYAN; fill_light.light_energy = 0.55; fill_light.omni_range = 22; add_child(fill_light)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("09111e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8897ae")
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	earth_mesh = MeshInstance3D.new(); var sphere := SphereMesh.new()
	var earth := earth_mesh
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
	clock_label = _label(heading, "01:00", 20, CYAN)
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	var mission_status := _panel(hud, Vector2(22, -92), Vector2(270, -18))
	mission_status.anchor_top = 1.0; mission_status.anchor_bottom = 1.0
	var status_column := _column(mission_status, 5)
	rescue_label = _label(status_column, "", 14, CYAN)
	suit_label = _label(status_column, "", 14, WHITE)
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
	puzzle_choices = HBoxContainer.new(); puzzle_choices.add_theme_constant_override("separation", 7)
	repair_column.add_child(puzzle_choices)
	for index in range(3):
		var choice := _button(puzzle_choices, "", true)
		choice.custom_minimum_size = Vector2(145, 40)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.pressed.connect(_on_choice.bind(index))
		choice_buttons.append(choice)
	puzzle_choices.visible = false
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
		world.astronaut.position.y = lerpf(world.astronaut.position.y, PLAYER_Y, minf(1.0, delta * 10.0))
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
			if offset.length() < 0.001: offset = Vector2.RIGHT
			flat = Vector2(center.x, center.z) + offset.normalized() * radius
	world.astronaut.position.x = flat.x; world.astronaut.position.z = flat.y
	world.astronaut.rotation.y = lerp_angle(world.astronaut.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 12.0))
	walk_clock += delta * 13.0
	world.astronaut.position.y = PLAYER_Y + absf(sin(walk_clock)) * 0.055

func _click_to_walk(point: Vector2) -> void:
	var clicked := ""
	var distance := 54.0
	for site in world.site_nodes:
		var node: Node3D = world.site_nodes[site]
		if not node.visible: continue
		var screen_point: Vector2 = camera.unproject_position(node.global_position + Vector3(0, 1.0, 0))
		var candidate: float = point.distance_to(screen_point)
		if candidate < distance:
			distance = candidate; clicked = site
	if clicked != "":
		var center: Vector3 = world.site_nodes[clicked].position
		var approach: Vector3 = world.astronaut.position - center; approach.y = 0.0
		if approach.length() < 0.01: approach = Vector3.RIGHT
		var reach := 1.42 if clicked in ["antenna", "water", "oxygen"] else (1.6 if clicked in ["habitat", "shelter", "greenhouse"] else 1.8)
		move_target = center + approach.normalized() * (reach - 0.12)
		move_target.y = PLAYER_Y
		return
	var origin: Vector3 = camera.project_ray_origin(point)
	var direction: Vector3 = camera.project_ray_normal(point)
	if absf(direction.y) < 0.001: return
	var travel: float = -origin.y / direction.y
	if travel < 0.0: return
	var hit: Vector3 = origin + direction * travel
	if Vector2(hit.x, hit.z).length() > 5.2: return
	move_target = Vector3(hit.x, PLAYER_Y, hit.z)

func _update_nearby() -> void:
	if model.inside_base:
		nearby_site = "interior"
		if toast_clock <= 0.0: _update_prompt()
		return
	var best := 99.0
	var nearest := ""
	for site in world.site_nodes:
		if not world.site_nodes[site].visible: continue
		var center: Vector3 = world.site_nodes[site].position
		var distance := Vector2(world.astronaut.position.x - center.x, world.astronaut.position.z - center.z).length()
		var reach := 1.85 if site == "solar" else (1.7 if site in ["habitat", "greenhouse", "shelter"] else 1.42)
		if site == objective_site and distance < reach:
			nearest = site
			break
		if distance < reach and distance < best:
			best = distance; nearest = site
	if nearest != nearby_site:
		nearby_site = nearest
		if toast_clock <= 0.0: _update_prompt()

func _update_prompt() -> void:
	if repair_action != "": return
	if model.inside_base:
		prompt_label.text = "[F] Recarregar traje    [E] Sair"
		hint_label.text = "O₂ do traje vem da reserva da base • abrigo contra radiação"
	elif nearby_site == "":
		prompt_label.text = "Siga o marcador luminoso"
		hint_label.text = "WASD / setas para andar  •  clique para ir"
	elif nearby_site == "habitat":
		prompt_label.text = "[E] Entrar no habitat"
		hint_label.text = "Recarregue o traje ou procure abrigo"
	elif nearby_site == "crater" and model.science == 0:
		prompt_label.text = "[E] Inspecionar cratera"
		hint_label.text = "Mapear detritos para uma aproximação segura"
	elif SITE_ACTIONS.has(nearby_site):
		var action: String = SITE_ACTIONS[nearby_site]
		prompt_label.text = "[E] %s" % MissionConfig.ACTIONS[action]["title"]
		var costs: Array[String] = []
		for key in MissionConfig.ACTIONS[action]["cost"]:
			var names := {"energy": "energia", "oxygen": "O₂", "water": "água", "supplies": "suprimentos"}
			costs.append("%s %d" % [names.get(key, key), MissionConfig.ACTIONS[action]["cost"][key]])
		hint_label.text = "Custo " + "  •  ".join(costs) + "  •  5 erros bloqueiam"
	else:
		prompt_label.text = SITE_NAMES.get(nearby_site, "Base lunar").capitalize()
		hint_label.text = "Siga o marcador luminoso"

func _interact() -> void:
	if model.inside_base:
		_exit_habitat()
		return
	_update_nearby()
	if nearby_site == "habitat":
		_enter_habitat()
	elif nearby_site == "crater" and model.science == 0:
		if model.inspect_anomaly():
			sound.cue("success"); MissionSave.save(model); _refresh(); _toast("Detritos mapeados • pouso pode ser preparado")
	elif SITE_ACTIONS.has(nearby_site):
		var action: String = SITE_ACTIONS[nearby_site]
		if not model.can_do(action):
			_toast("Sem recursos, dados ou equipamento disponível")
			sound.cue("warning")
			return
		_start_repair(action)

func _enter_habitat() -> void:
	model.inside_base = true
	_apply_view()
	move_target = Vector3.INF; nearby_site = "interior"
	sound.cue("click"); MissionSave.save(model); _update_prompt()

func _exit_habitat() -> void:
	model.inside_base = false
	_apply_view()
	nearby_site = ""
	sound.cue("click"); MissionSave.save(model); _update_nearby(); _update_prompt()

func _apply_view() -> void:
	world.visible = not model.inside_base
	interior.visible = model.inside_base
	sun_light.visible = not model.inside_base
	fill_light.visible = not model.inside_base
	earth_mesh.visible = not model.inside_base
	if model.inside_base:
		camera.position = Vector3(4.4, 4.2, 6.8); camera.size = 7.2
		camera.look_at(Vector3(0, 0.7, 0))
	else:
		camera.position = Vector3(10.5, 13.0, 16.0); camera.size = 12.8
		camera.look_at(Vector3.ZERO)

func _refill_suit() -> void:
	if model.refill_suit():
		suit_warned = false
		sound.cue("success"); MissionSave.save(model); _refresh_live()
		_toast("Traje recarregado com O₂ da base")
	else:
		sound.cue("warning"); _toast("Reserva de O₂ insuficiente ou traje cheio")

func _update_storm(delta: float) -> void:
	if model.day != 4:
		sun_light.light_color = Color("f5dfc0")
		storm_active_last = false
		return
	if model.day_seconds_left <= 40.0 and not storm_warned:
		storm_warned = true; sound.cue("warning")
		_toast("ALERTA SOLAR • procure abrigo em 10 s")
	var active: bool = model.day_seconds_left <= 30.0 and model.day_seconds_left > 14.0
	sun_light.light_color = RED if active else Color("f5dfc0")
	if active != storm_active_last:
		storm_active_last = active
		_refresh()
	if active:
		if not model.inside_base: model.radiation_exposure += delta
		elif model.shelter < 60: model.radiation_exposure += delta * 0.5
		if model.radiation_exposure >= 8.0:
			model._fail("Exposição à radiação: a tripulação não alcançou abrigo protegido a tempo.")

func _start_repair(action: String) -> void:
	repair_action = action; repair_hits = 0; repair_mistakes = 0
	repair_clock = 0.0; repair_target = 0.5
	puzzle_kind = "diagnostic" if action in ["oxygen", "shelter"] else ("sequence" if action in ["solar", "water", "food", "landing"] else "timing")
	move_target = Vector3.INF
	repair_panel.visible = true
	prompt_panel.visible = false
	repair_title.text = str(MissionConfig.ACTIONS[action]["title"]).to_upper()
	gauge.visible = puzzle_kind == "timing"
	puzzle_choices.visible = puzzle_kind != "timing"
	if puzzle_kind == "timing": repair_hint.text = "ESPAÇO no brilho azul • 0 / 2 • erros 0 / 5"
	elif puzzle_kind == "diagnostic":
		var labels: Array = ["Linha A 96", "Linha B 61", "Linha C 95"] if action == "oxygen" else ["Selo A 98", "Selo B 97", "Selo C 43"]
		for i in range(3): choice_buttons[i].text = labels[i]
		repair_hint.text = "Isole o ponto com leitura anormal • erros 0 / 5"
	else:
		var labels: Array = {"solar": ["O₂", "HAB", "COM"], "water": ["Bomba", "Filtro", "Teste"],
			"food": ["Água", "Nutrientes", "Luz"], "landing": ["Varrer", "Baliza", "Confirmar"]}[action]
		for i in range(3): choice_buttons[i].text = labels[i]
		repair_hint.text = _sequence_hint(action) + " • erros 0 / 5"
	_update_gauge()
	sound.cue("click")

func _sequence_hint(action: String) -> String:
	match action:
		"solar": return "Priorize ar, habitat e comunicação"
		"water": return "Faça circular, filtre e verifique"
		"food": return "Irrigue, nutra e ilumine"
		_: return "Verifique detritos, sinalize e confirme"

func _on_choice(index: int) -> void:
	if repair_action == "" or puzzle_kind == "timing": return
	var correct: int = (1 if repair_action == "oxygen" else 2) if puzzle_kind == "diagnostic" else repair_hits
	if index != correct:
		_puzzle_error()
		return
	repair_hits += 1
	sound.cue("action")
	world.pulse(str(MissionConfig.ACTIONS[repair_action]["site"]))
	if puzzle_kind == "diagnostic" or repair_hits >= 3:
		_complete_repair()
	else:
		repair_hint.text = "%s • %d / 3 • erros %d / 5" % [_sequence_hint(repair_action), repair_hits, repair_mistakes]

func _update_gauge() -> void:
	var width: float = maxf(1.0, gauge.size.x - 5.0)
	var pulse: float = 0.5 + 0.5 * sin(repair_clock * (3.8 + float(repair_hits) * 0.7) - PI * 0.5)
	gauge_needle.position.x = pulse * width
	gauge_target.position.x = repair_target * width - 32.0

func _check_repair() -> void:
	if repair_action == "" or puzzle_kind != "timing": return
	var pulse: float = gauge_needle.position.x / maxf(1.0, gauge.size.x - 5.0)
	if absf(pulse - repair_target) <= 0.12:
		repair_hits += 1
		sound.cue("action")
		world.pulse(str(MissionConfig.ACTIONS[repair_action]["site"]))
		repair_hint.text = "ESPAÇO no brilho azul • %d / 2 • erros %d / 5" % [repair_hits, repair_mistakes]
		repair_clock = 0.0
		repair_target = 0.64 if repair_hits == 1 else 0.5
		if repair_hits >= 2: _complete_repair()
	else:
		_puzzle_error()

func _puzzle_error() -> void:
	repair_mistakes += 1
	sound.cue("warning")
	if puzzle_kind == "sequence": repair_hits = 0
	if repair_mistakes >= 5:
		var action := repair_action
		_cancel_repair()
		model.record_repair_failure(action)
		MissionSave.save(model); _refresh()
		if model.ended: _show_result()
		else: _toast("Reparo perdido • equipamento bloqueado hoje")
	else:
		repair_hint.text = "Leitura incorreta • erros %d / 5" % repair_mistakes

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
	world.select_site(objective_site)
	_update_prompt()

func _recommendation() -> String:
	if model.day == 4 and model.day_seconds_left <= 30.0 and model.day_seconds_left > 14.0: return "habitat"
	if model.day >= 3 and model.science == 0: return "crater"
	if int(model.resources["energy"]) < 16 and model.can_do("solar"): return "solar"
	if int(model.resources["oxygen"]) < 18 and model.can_do("oxygen"): return "oxygen"
	for action in DAILY_ROUTE[model.day]:
		if not _did_today(action) and model.can_do(action): return str(MissionConfig.ACTIONS[action]["site"])
	return "habitat"

func _did_today(action: String) -> bool:
	var token := "DIA %d • %s." % [model.day, MissionConfig.ACTIONS[action]["title"]]
	return model.history.has(token)

func _refresh() -> void:
	world.set_model(model)
	day_label.text = "DIA %d / 7" % model.day
	objective_site = _recommendation()
	world.select_site(objective_site)
	selected_site = objective_site
	objective_label.text = "Procure abrigo contra a radiação" if model.day == 4 and objective_site == "habitat" else GOALS[objective_site]
	rescue_label.text = "RESGATE %d/3  •  POUSO %s" % [model.rescue, "OK" if model.landing_prepared else "PENDENTE"]
	_refresh_live()
	_update_nearby()
	_update_prompt()

func _refresh_live() -> void:
	clock_label.text = "%02d:%02d" % [int(ceilf(model.day_seconds_left)) / 60, int(ceilf(model.day_seconds_left)) % 60]
	clock_label.add_theme_color_override("font_color", RED if model.day_seconds_left <= 15.0 else CYAN)
	suit_label.text = "TRAJE O₂ %d%%" % int(ceilf(model.suit_oxygen))
	suit_label.add_theme_color_override("font_color", RED if model.suit_oxygen <= 30.0 else WHITE)
	for key in resource_bars:
		var value: int = model.resources[key]
		resource_bars[key].value = value
		resource_bars[key].add_theme_stylebox_override("fill", _style(RED if value <= 18 else (WARM if value <= 35 else CYAN), 5))
		resource_labels[key].text = str(value)
		resource_bars[key].tooltip_text = "%s %d / 100" % [key, value]

func _toast(message: String) -> void:
	toast_clock = 2.3
	prompt_label.text = message
	hint_label.text = ""

func _end_day() -> void:
	modal.visible = false
	model.end_day(); MissionSave.save(model); _refresh()
	storm_warned = false
	sound.cue("failure" if model.ended and not model.won else ("warning" if model.day in [4, 6] else "click"))
	if model.ended: _show_result()
	else:
		var alerts := {2: "Painéis avariados", 3: "Impacto próximo à base", 4: "Radiação prevista", 5: "Filtro de água danificado", 6: "Vazamento de oxigênio", 7: "Nave de resgate à vista"}
		_toast("DIA %d  •  %s" % [model.day, alerts.get(model.day, "Continue")])

func _show_menu() -> void:
	menu.visible = true; modal.visible = false; repair_action = ""; repair_panel.visible = false
	prompt_panel.visible = true
	for child in menu.get_children(): child.queue_free()
	var box := _center_box(menu, 150)
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
	world.astronaut.position = Vector3(1.85, PLAYER_Y, 3.58)
	_apply_view(); suit_warned = false; storm_warned = false; storm_active_last = false; autosave_clock = 0.0
	move_target = Vector3.INF; nearby_site = ""
	menu.visible = false; modal.visible = false
	sound.cue("click"); _refresh(); MissionSave.save(model)
	_toast("60 s por dia • E interage • F recarrega no habitat")

func _continue_game() -> void:
	var loaded := MissionSave.load_game()
	if loaded == null: return
	model = loaded; menu.visible = false; modal.visible = false
	world.astronaut.position = Vector3(1.85, PLAYER_Y, 3.58)
	_apply_view(); suit_warned = model.suit_oxygen <= 30.0; storm_warned = false
	move_target = Vector3.INF; nearby_site = ""
	sound.cue("click"); _refresh()
	if model.ended: _show_result()

func _show_pause() -> void:
	_show_modal("MISSÃO PAUSADA", "WASD/setas: mover  •  E: interagir  •  F: recarregar traje  •  Espaço: calibrar", [
		{"text": "CONTINUAR", "call": func(): modal.visible = false},
		{"text": "ÁUDIO", "call": _show_settings},
		{"text": "CIÊNCIA", "call": _show_science},
		{"text": "MENU", "call": _show_menu}
	])

func _show_settings() -> void:
	_show_modal("ÁUDIO", "Volume geral", [{"text": "VOLTAR", "call": _show_pause}])
	var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = 0.01
	slider.value = sound.volume; slider.custom_minimum_size.y = 48
	modal_box.add_child(slider)
	modal_box.move_child(slider, modal_box.get_child_count() - 2)
	slider.value_changed.connect(sound.set_volume)

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

func _center_box(parent: Control, half_height: int = 210) -> VBoxContainer:
	var panel := _panel(parent, Vector2(-260, -half_height), Vector2(260, half_height))
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
