extends Node3D

const NAVY := Color("121b2a")
const PANEL := Color(0.075, 0.11, 0.18, 0.93)
const CYAN := Color("67dad5")
const WARM := Color("f2b663")
const RED := Color("ea695d")
const WHITE := Color("e8edf1")
const MUTED := Color("9baabb")

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
var day_title: Label
var day_brief: Label
var forecast_label: Label
var actions_label: Label
var rescue_label: Label
var site_title: Label
var site_info: Label
var site_action_button: Button
var log_text: RichTextLabel
var resource_bars: Dictionary = {}
var resource_labels: Dictionary = {}
var action_buttons: Dictionary = {}
var anomaly_button: Button
var selected_site: String = "habitat"
var tutorial_seen: bool = false

func _ready() -> void:
	_build_environment()
	world = LunarDiorama.new(); add_child(world)
	world.site_selected.connect(_on_site_selected)
	sound = Soundscape.new(); add_child(sound)
	model = MissionModel.new()
	_build_ui()
	_refresh()
	_show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not menu.visible and not modal.visible:
			world.pick_from_screen(camera, event.position)
	if event.is_action_pressed("ui_cancel") and not menu.visible:
		if modal.visible: modal.visible = false
		else: _show_pause()

func _build_environment() -> void:
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5; camera.position = Vector3(10.5, 13.0, 16.0)
	add_child(camera); camera.look_at(Vector3(0, 0, 0)); camera.current = true
	sun_light = DirectionalLight3D.new(); sun_light.rotation_degrees = Vector3(-53, -32, 0)
	sun_light.light_color = Color("f5dfc0"); sun_light.light_energy = 1.25; sun_light.shadow_enabled = true; add_child(sun_light)
	var fill := OmniLight3D.new(); fill.position = Vector3(-5, 7, 4)
	fill.light_color = CYAN; fill.light_energy = 0.5; fill.omni_range = 22; add_child(fill)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("09111e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8897ae")
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	# Earth is an original procedural globe above the horizon.
	var earth := MeshInstance3D.new(); var sphere := SphereMesh.new()
	sphere.radial_segments = 24; sphere.rings = 12; earth.mesh = sphere
	earth.position = Vector3(-6.5, -1.1, -9.0); earth.scale = Vector3.ONE * 1.08
	var planet_shader := Shader.new()
	planet_shader.code = """shader_type spatial;
render_mode unshaded, cull_back;
void fragment() {
	float land = sin(UV.x * 9.0 + sin(UV.y * 8.0) * 1.5) * cos(UV.y * 13.0 - sin(UV.x * 5.0) * 1.2);
	float cloud = sin(UV.x * 27.0 + UV.y * 8.0) * cos(UV.y * 20.0 - UV.x * 3.0);
	vec3 color = mix(vec3(0.045, 0.24, 0.5), vec3(0.11, 0.38, 0.31), smoothstep(0.42, 0.65, land));
	color = mix(color, vec3(0.78, 0.89, 0.94), smoothstep(0.65, 0.85, cloud) * 0.35);
	ALBEDO = color;
	EMISSION = color * 0.28;
}"""
	var planet_material := ShaderMaterial.new(); planet_material.shader = planet_shader
	earth.material_override = planet_material; add_child(earth)
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	for i in range(54):
		var star := MeshInstance3D.new(); var quad := SphereMesh.new(); quad.radial_segments = 4; quad.rings = 2
		var nx: float = fposmod(sin(float(i) * 78.233) * 43758.5453, 1.0)
		var ny: float = fposmod(sin(float(i) * 13.913) * 25432.3531, 1.0)
		var screen_point := Vector2(screen_size.x * (0.25 + nx * 0.5), screen_size.y * ((0.12 + ny * 0.13) if i < 27 else (0.78 + ny * 0.14)))
		star.mesh = quad; star.position = camera.project_position(screen_point, 35.0)
		star.scale = Vector3.ONE * (0.014 + float(i % 3) * 0.01)
		var glow := StandardMaterial3D.new(); glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color(0.8, 0.91, 1.0, 0.75); glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		star.material_override = glow; add_child(star)

func _build_ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	hud = Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(hud)
	var top := _panel(hud, Vector2(20, 16), Vector2(-20, 94), true)
	var top_row := HBoxContainer.new(); top_row.add_theme_constant_override("separation", 18); top.add_child(top_row)
	var brand := _label(top_row, "LAST LIGHT", 27, WHITE); brand.custom_minimum_size.x = 245
	day_label = _label(top_row, "DIA 1 / 7", 18, WARM); day_label.custom_minimum_size.x = 122
	for key in ["energy", "oxygen", "water", "supplies"]:
		var card := VBoxContainer.new(); card.custom_minimum_size.x = 183; top_row.add_child(card)
		var title := _label(card, _resource_title(key), 13, MUTED)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		resource_labels[key] = title
		var bar := ProgressBar.new(); bar.custom_minimum_size = Vector2(172, 15)
		bar.max_value = 100; bar.show_percentage = false
		bar.add_theme_stylebox_override("background", _style(Color("253548"), 7))
		bar.add_theme_stylebox_override("fill", _style(CYAN if key != "supplies" else WARM, 7))
		card.add_child(bar); resource_bars[key] = bar
	var menu_button := _button(top_row, "☰  PAUSA", false)
	menu_button.pressed.connect(_show_pause)
	var left := _panel(hud, Vector2(20, 110), Vector2(370, -22), false)
	var left_column := _column(left)
	day_title = _label(left_column, "", 24, WHITE)
	day_brief = _label(left_column, "", 15, MUTED); day_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_brief.custom_minimum_size.y = 118
	_add_divider(left_column)
	forecast_label = _label(left_column, "", 16, WARM); forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast_label.custom_minimum_size.y = 78
	_add_divider(left_column)
	rescue_label = _label(left_column, "", 16, CYAN)
	var module_header := _label(left_column, "MÓDULO SELECIONADO", 12, MUTED)
	module_header.custom_minimum_size.y = 24
	site_title = _label(left_column, "", 20, WHITE)
	site_info = _label(left_column, "", 14, MUTED); site_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	site_info.custom_minimum_size.y = 76
	site_action_button = _button(left_column, "", true)
	site_action_button.custom_minimum_size.y = 42
	site_action_button.pressed.connect(_on_site_action)
	var science_button := _button(left_column, "RELATÓRIO CIENTÍFICO  ↗", false)
	science_button.pressed.connect(_show_science)
	_add_divider(left_column)
	_label(left_column, "REGISTRO DA MISSÃO", 12, MUTED)
	log_text = RichTextLabel.new(); log_text.bbcode_enabled = false; log_text.scroll_active = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.add_theme_font_size_override("normal_font_size", 13)
	log_text.add_theme_color_override("default_color", MUTED)
	left_column.add_child(log_text)
	var right := _panel(hud, Vector2(-375, 110), Vector2(-20, -22), true)
	var right_column := _column(right)
	_label(right_column, "CENTRO DE COMANDO", 22, WHITE)
	actions_label = _label(right_column, "", 15, WARM)
	_add_divider(right_column)
	for action in MissionConfig.ACTION_ORDER:
		var spec: Dictionary = MissionConfig.ACTIONS[action]
		var costs: Array[String] = []
		for key in spec["cost"]: costs.append("%s %d" % [_resource_short(key), int(spec["cost"][key])])
		var gains := {"solar": "+8 energia", "oxygen": "+23 O₂", "water": "+19 água", "food": "+19 suprimentos", "shelter": "+28 abrigo", "rescue": "+1 etapa de resgate"}
		var text_value: String = str(spec["title"]) + "\n" + "  •  ".join(costs) + "\n→  " + str(gains[action])
		var button := _button(right_column, text_value, true)
		button.custom_minimum_size.y = 70
		button.pressed.connect(_on_action.bind(action))
		button.tooltip_text = str(spec["tip"])
		action_buttons[action] = button
	anomaly_button = _button(right_column, "INVESTIGAR ANOMALIA\nEnergia 4  •  +ciência", true)
	anomaly_button.custom_minimum_size.y = 62
	anomaly_button.pressed.connect(_on_anomaly)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; right_column.add_child(spacer)
	var end_button := _button(right_column, "ENCERRAR DIA  →", true)
	end_button.custom_minimum_size.y = 60
	end_button.pressed.connect(_confirm_end_day)
	var foot := _label(hud, "CLIQUE NOS MÓDULOS PARA INSPECIONAR  •  UNIDADES DIDÁTICAS", 12, MUTED)
	foot.anchor_left = 0.5; foot.anchor_right = 0.5
	foot.anchor_top = 1.0; foot.anchor_bottom = 1.0
	foot.offset_left = -300; foot.offset_right = 300
	foot.offset_top = -28; foot.offset_bottom = -8
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu = ColorRect.new(); menu.color = Color(0.02, 0.04, 0.08, 0.82)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.add_child(menu)
	modal = ColorRect.new(); modal.color = Color(0.02, 0.04, 0.08, 0.77)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.add_child(modal)
	modal_box = _center_box(modal); modal.visible = false

func _panel(parent: Control, top_left: Vector2, bottom_right: Vector2, right_anchor: bool) -> PanelContainer:
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", _style(PANEL, 18, CYAN.darkened(0.72)))
	if right_anchor:
		panel.anchor_left = 1.0 if top_left.x < 0 else 0.0
		panel.anchor_right = 1.0
		panel.offset_left = top_left.x; panel.offset_right = bottom_right.x
	else:
		panel.offset_left = top_left.x; panel.offset_right = bottom_right.x
	panel.offset_top = top_left.y
	panel.anchor_bottom = 1.0 if bottom_right.y < 0 else 0.0
	panel.offset_bottom = bottom_right.y
	parent.add_child(panel)
	return panel

func _column(parent: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	parent.add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 9)
	margin.add_child(column)
	return column

func _label(parent: Control, value: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, important: bool) -> Button:
	var button := Button.new(); button.text = value
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_stylebox_override("normal", _style(Color("1c3042") if important else Color("172736"), 10, CYAN.darkened(0.72)))
	button.add_theme_stylebox_override("hover", _style(Color("2c5260"), 10, CYAN))
	button.add_theme_stylebox_override("pressed", _style(Color("355d6c"), 10, WARM))
	button.add_theme_stylebox_override("disabled", _style(Color("17202a"), 10))
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

func _center_box(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", _style(PANEL, 20, CYAN.darkened(0.45)))
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -285; panel.offset_right = 285
	panel.offset_top = -275; panel.offset_bottom = 275
	parent.add_child(panel)
	return _column(panel)

func _show_menu() -> void:
	menu.visible = true; modal.visible = false
	for child in menu.get_children(): child.queue_free()
	var box := _center_box(menu)
	_label(box, "L A S T   L I G H T", 30, WHITE)
	var subtitle := _label(box, "Sete dias. Uma base lunar. Cada decisão importa.", 16, WARM)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_divider(box)
	var intro := _label(box, "A comunicação com a Terra caiu. Mantenha energia, oxigênio, água e suprimentos acima de zero; reforce o abrigo antes da tempestade e complete três etapas de resgate.", 16, MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 140
	var start := _button(box, "INICIAR MISSÃO", true); start.custom_minimum_size.y = 56
	start.pressed.connect(_new_game)
	var continue_button := _button(box, "CONTINUAR", false); continue_button.custom_minimum_size.y = 48
	continue_button.disabled = not MissionSave.exists(); continue_button.pressed.connect(_continue_game)
	var settings := _button(box, "CONFIGURAÇÕES", false); settings.custom_minimum_size.y = 48; settings.pressed.connect(_show_settings)
	var credits := _button(box, "CRÉDITOS E FONTES", false); credits.custom_minimum_size.y = 48; credits.pressed.connect(_show_credits)

func _new_game() -> void:
	MissionSave.clear(); model = MissionModel.new(); tutorial_seen = false
	menu.visible = false; sound.cue("click"); _refresh(); MissionSave.save(model)
	_show_tutorial()

func _continue_game() -> void:
	var loaded := MissionSave.load_game()
	if loaded == null: return
	model = loaded; tutorial_seen = true; menu.visible = false
	sound.cue("click"); _refresh()
	if model.ended: _show_result()

func _show_tutorial() -> void:
	if tutorial_seen: return
	tutorial_seen = true
	_show_modal("PROTOCOLO DE EMERGÊNCIA", "Você dispõe de duas ações por dia. Observe os custos antes de agir. Ao terminar, a base consome recursos e os eventos avançam. No dia 3, prepare o abrigo para a tempestade do dia 4.", [{"text": "ENTENDI", "call": func(): modal.visible = false}])

func _show_pause() -> void:
	sound.cue("click")
	_show_modal("MISSÃO PAUSADA", "Seu progresso é salvo após cada ação e a cada dia. A tripulação aguarda sua próxima decisão.", [
		{"text": "CONTINUAR", "call": func(): modal.visible = false},
		{"text": "REINICIAR", "call": _restart_confirm},
		{"text": "MENU PRINCIPAL", "call": _show_menu}
	])

func _restart_confirm() -> void:
	_show_modal("REINICIAR MISSÃO?", "O progresso da campanha atual será substituído por um novo começo.", [
		{"text": "CANCELAR", "call": func(): modal.visible = false},
		{"text": "REINICIAR", "call": _new_game}
	])

func _confirm_end_day() -> void:
	_show_modal("ENCERRAR DIA %d?" % model.day, "A base produzirá e consumirá recursos. Ações restantes serão perdidas. Confira a previsão antes de continuar.", [
		{"text": "VOLTAR", "call": func(): modal.visible = false},
		{"text": "CONFIRMAR", "call": _end_day}
	])

func _end_day() -> void:
	modal.visible = false
	var previous: Dictionary = model.resources.duplicate(true)
	var previous_shelter: int = model.shelter
	model.end_day(); MissionSave.save(model); _refresh()
	sound.cue("failure" if model.ended and not model.won else ("warning" if model.day == 4 or model.day == 6 else "click"))
	if model.ended: _show_result()
	else: _show_day_report(previous, previous_shelter)

func _show_day_report(previous: Dictionary, previous_shelter: int) -> void:
	var changes: Array[String] = []
	for key in ["energy", "oxygen", "water", "supplies"]:
		var difference: int = int(model.resources[key]) - int(previous[key])
		changes.append("%s %+d" % [_resource_title(key), difference])
	var body: String = MissionConfig.DAY_BRIEFS[model.day]
	body += "\n\nBALANÇO DO DIA ANTERIOR\n" + "  •  ".join(changes)
	if model.shelter != previous_shelter:
		body += "\nAbrigo %+d" % (model.shelter - previous_shelter)
	body += "\n\n" + model.log.back()
	_show_modal("DIA %d • %s" % [model.day, MissionConfig.DAY_TITLES[model.day]], body, [
		{"text": "ABRIR CENTRO DE COMANDO", "call": func(): modal.visible = false}
	])

func _show_result() -> void:
	var title: String = "MISSÃO CONCLUÍDA" if model.won else "MISSÃO ENCERRADA"
	var content: String = model.outcome + "\n\nPONTUAÇÃO: %d\nResgate: %d/3  •  Ciência: %d/1  •  Abrigo: %d/100\n\n" % [model.score(), model.rescue, model.science, model.shelter]
	content += "PAINÉIS: %s  •  FILTRO: %s\n" % ["operacionais" if model.panels_ok else "avariados", "operacional" if model.recycler_ok else "avariado"]
	content += "PESQUISA: %s\n\n" % ("anomalia investigada" if model.science > 0 else "não realizada")
	content += "Os valores são unidades didáticas. O registro à esquerda mostra a sequência completa da missão."
	_show_modal(title, content, [
		{"text": "RELATÓRIO CIENTÍFICO", "call": _show_science},
		{"text": "NOVA MISSÃO", "call": _new_game},
		{"text": "MENU", "call": _show_menu}
	])
	sound.cue("success" if model.won else "failure")

func _show_science() -> void:
	var science_text := "SUPORTE À VIDA • O sistema ECLSS usa recuperação de água, revitalização do ar e geração de oxigênio por eletrólise.\n\n"
	science_text += "ENERGIA • Energia e armazenamento devem sustentar sistemas mesmo com falhas e iluminação variável.\n\n"
	science_text += "RADIAÇÃO • Eventos solares exigem proteção. A integridade do abrigo é uma abstração didática.\n\n"
	science_text += "CULTIVO • Plantas precisam de ambiente controlado, água, luz e nutrientes; a colheita em poucos dias é aceleração de gameplay.\n\n"
	science_text += "Fontes: NASA ECLSS, Lunar Surface Technology, Space Radiation e Biological & Physical Sciences. Links completos em docs/SCIENCE.md."
	_show_modal("RELATÓRIO CIENTÍFICO", science_text, [{"text": "FECHAR", "call": func(): modal.visible = false}])

func _show_credits() -> void:
	_show_modal("CRÉDITOS", "LAST LIGHT • Cenário e áudio procedurais originais; modelos 3D selecionados do Kenney Space Kit (CC0).\n\nConceitos científicos: NASA ECLSS, NASA Lunar Surface Technology e NASA Biological & Physical Sciences. Referências completas em docs/SCIENCE.md.\n\nGodot Engine 4.7.", [{"text": "VOLTAR", "call": func(): modal.visible = false; _show_menu()}])

func _show_settings() -> void:
	_show_modal("CONFIGURAÇÕES", "Volume geral da música e dos efeitos.", [{"text": "VOLTAR", "call": func(): modal.visible = false; _show_menu()}])
	var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = 0.01
	slider.value = sound.volume; slider.custom_minimum_size.y = 50
	modal_box.add_child(slider)
	slider.move_to_front(); slider.value_changed.connect(sound.set_volume)

func _show_modal(title: String, body: String, buttons: Array) -> void:
	modal.visible = true
	for child in modal_box.get_children(): child.queue_free()
	var title_color: Color = CYAN if title == "MISSÃO CONCLUÍDA" else (RED if title == "MISSÃO ENCERRADA" else (WARM if title.contains("DIA") else WHITE))
	_label(modal_box, title, 25, title_color)
	_add_divider(modal_box)
	var content := _label(modal_box, body, 15, MUTED)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for item in buttons:
		var button := _button(modal_box, str(item["text"]), true)
		button.custom_minimum_size.y = 48
		button.pressed.connect(item["call"])

func _on_action(action: String) -> void:
	if not model.do_action(action): return
	world.pulse(str(MissionConfig.ACTIONS[action]["site"]))
	sound.cue("action"); MissionSave.save(model); _refresh()

func _on_anomaly() -> void:
	if model.inspect_anomaly():
		sound.cue("success"); MissionSave.save(model); _refresh()

func _on_site_selected(site: String) -> void:
	selected_site = site; _refresh_site()

func _on_site_action() -> void:
	var site_actions := {"solar": "solar", "oxygen": "oxygen", "water": "water", "greenhouse": "food", "shelter": "shelter", "antenna": "rescue"}
	if site_actions.has(selected_site):
		_on_action(str(site_actions[selected_site]))

func _refresh() -> void:
	world.set_model(model)
	sun_light.light_color = Color("fa9e82") if model.day == 4 else Color("f5dfc0")
	day_label.text = "DIA %d / 7" % model.day
	day_title.text = MissionConfig.DAY_TITLES[model.day]
	day_brief.text = MissionConfig.DAY_BRIEFS[model.day]
	actions_label.text = "%d / 2 AÇÕES RESTANTES" % model.actions_left
	rescue_label.text = "RESGATE  %d / 3   •   ABRIGO  %d / 100" % [model.rescue, model.shelter]
	forecast_label.text = _forecast()
	for key in resource_bars:
		var bar: ProgressBar = resource_bars[key]
		bar.value = int(model.resources[key])
		resource_labels[key].text = "%s  %d" % [_resource_title(key), int(model.resources[key])]
		bar.tooltip_text = "%s: %d / 100" % [_resource_title(key), int(model.resources[key])]
		bar.add_theme_stylebox_override("fill", _style(RED if int(model.resources[key]) <= 18 else (WARM if key == "supplies" else CYAN), 7))
	for action in action_buttons:
		action_buttons[action].disabled = not model.can_do(action)
	anomaly_button.visible = model.day == 3 and model.science == 0
	anomaly_button.disabled = model.actions_left <= 0 or int(model.resources["energy"]) < 4
	log_text.text = "\n\n".join(model.log.slice(maxi(0, model.log.size() - 7)))
	_refresh_site()

func _refresh_site() -> void:
	if not site_title: return
	var names := {"habitat": "Habitat principal", "solar": "Fazenda solar", "oxygen": "Gerador de oxigênio", "water": "Recuperação de água", "greenhouse": "Estufa", "shelter": "Abrigo blindado", "antenna": "Antena de resgate", "landing": "Zona de pouso"}
	var key: String = "antenna" if selected_site == "landing" else selected_site
	site_title.text = names.get(selected_site, selected_site)
	site_info.text = MissionConfig.SCIENCE.get(key, "Área reservada à nave de resgate.")
	var site_actions := {"solar": "solar", "oxygen": "oxygen", "water": "water", "greenhouse": "food", "shelter": "shelter", "antenna": "rescue"}
	site_action_button.visible = site_actions.has(selected_site)
	if site_action_button.visible:
		var action: String = str(site_actions[selected_site])
		site_action_button.text = str(MissionConfig.ACTIONS[action]["title"]).to_upper() + "  →"
		site_action_button.disabled = not model.can_do(action)

func _forecast() -> String:
	match model.day:
		1: return "PREVISÃO  •  Amanhã: falha nos painéis solares."
		2: return "ALERTA  •  Repare a geração; radiação em aumento."
		3: return "ALERTA SOLAR  •  Amanhã: abrigo ≥ 60."
		4: return "TEMPESTADE  •  Abrigo ≥ 60 ao encerrar o dia."
		5: return "CRISE HÍDRICA  •  O filtro reduz a recuperação diária."
		6: return "FALHAS MÚLTIPLAS  •  Vazamento e antena desalinhada."
		_: return "ÚLTIMA LUZ  •  Resgate 3/3 para vencer."

func _resource_title(key: String) -> String:
	match key:
		"energy": return "ENERGIA"
		"oxygen": return "OXIGÊNIO"
		"water": return "ÁGUA"
		_: return "SUPRIMENTOS"

func _resource_short(key: String) -> String:
	match key:
		"energy": return "Energia"
		"oxygen": return "O₂"
		"water": return "Água"
		_: return "Suprimentos"
