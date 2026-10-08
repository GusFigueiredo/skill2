extends Control

const BACKGROUND := preload("res://sprites/Menu/Background.png")
const Progress = preload("res://scripts/CampaignProgress.gd")
const STAGES: Array[Dictionary] = [
	{"place": "Ratanabá", "short": "Ratanabá\nTutorial"},
	{"place": "Floresta da Ratanabá", "short": "Floresta\nBoitatá"},
	{"place": "Rio Negro", "short": "Rio Negro"},
	{"place": "Rio Negro", "short": "Iara"},
	{"place": "Caverna da Cuca", "short": "Caverna"},
	{"place": "Caverna da Cuca", "short": "Cuca"},
	{"place": "Floresta Amazônica", "short": "Amazônia\nCorpo Seco"}
]
const ROUTE_POINTS: Array[Vector2] = [
	Vector2(0.11, 0.64), Vector2(0.24, 0.39), Vector2(0.37, 0.60),
	Vector2(0.50, 0.35), Vector2(0.63, 0.59), Vector2(0.76, 0.34),
	Vector2(0.89, 0.58)
]

var stage_buttons: Array[Button] = []
var stage_labels: Array[Label] = []
var route_glow: Line2D
var route_line: Line2D
var details_label: Label
var start_button: Button
var transitioning: bool = false
var selected_stage := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_scene()
	_layout_route()
	_show_stage(0)
	stage_buttons[0].grab_focus()

func _build_scene() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.055, 0.045, 0.68)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var header := Label.new()
	header.text = "CAMINHO PELA FLORESTA"
	header.position = Vector2(48, 28)
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", Color("efcd85"))
	header.add_theme_color_override("font_shadow_color", Color.BLACK)
	header.add_theme_constant_override("shadow_offset_x", 2)
	header.add_theme_constant_override("shadow_offset_y", 2)
	add_child(header)

	var subtitle := Label.new()
	subtitle.text = "Sete etapas. Um ritual que precisa ser interrompido."
	subtitle.position = Vector2(50, 74)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("e0d3b2"))
	add_child(subtitle)

	route_glow = Line2D.new()
	route_glow.width = 16.0
	route_glow.default_color = Color(0.66, 0.51, 0.24, 0.38)
	route_glow.antialiased = true
	add_child(route_glow)

	route_line = Line2D.new()
	route_line.width = 5.0
	route_line.default_color = Color("e0bd72")
	route_line.antialiased = true
	add_child(route_line)

	for index in STAGES.size():
		var button := Button.new()
		button.text = str(index + 1)
		button.custom_minimum_size = Vector2(68, 68)
		button.size = Vector2(68, 68)
		button.add_theme_font_size_override("font_size", 25)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = not Progress.is_available(index)
		button.focus_mode = Control.FOCUS_ALL if Progress.is_available(index) else Control.FOCUS_NONE
		_style_stage_button(button, Progress.is_available(index))
		button.pressed.connect(_show_stage.bind(index))
		add_child(button)
		stage_buttons.append(button)

		var label := Label.new()
		label.text = str(STAGES[index]["short"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(126, 0)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("e7dfc8") if Progress.is_available(index) else Color("a5a28f"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		stage_labels.append(label)

	var footer := PanelContainer.new()
	footer.anchor_left = 0.06
	footer.anchor_top = 0.81
	footer.anchor_right = 0.94
	footer.anchor_bottom = 0.97
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color(0.035, 0.065, 0.05, 0.94)
	footer_style.border_color = Color("bd9b54")
	footer_style.set_border_width_all(2)
	footer_style.set_corner_radius_all(8)
	footer_style.content_margin_left = 20
	footer_style.content_margin_right = 20
	footer_style.content_margin_top = 10
	footer_style.content_margin_bottom = 10
	footer.add_theme_stylebox_override("panel", footer_style)
	add_child(footer)

	var footer_content := HBoxContainer.new()
	footer_content.add_theme_constant_override("separation", 16)
	footer.add_child(footer_content)

	details_label = Label.new()
	details_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details_label.add_theme_font_size_override("font_size", 18)
	details_label.add_theme_color_override("font_color", Color("f3ead1"))
	footer_content.add_child(details_label)

	start_button = Button.new()
	start_button.text = "Jogar fase 1"
	start_button.custom_minimum_size = Vector2(230, 54)
	start_button.theme = preload("res://themes/pindorama.tres")
	start_button.add_theme_font_size_override("font_size", 19)
	start_button.add_theme_color_override("font_color", Color("ffe3a1"))
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_action_button(start_button)
	start_button.pressed.connect(_start_selected_stage)
	footer_content.add_child(start_button)

	var back_button := Button.new()
	back_button.text = "Menu"
	back_button.anchor_left = 1.0
	back_button.anchor_right = 1.0
	back_button.offset_left = -150
	back_button.offset_top = 28
	back_button.offset_right = -50
	back_button.offset_bottom = 70
	back_button.custom_minimum_size = Vector2(100, 42)
	back_button.size = Vector2(100, 42)
	back_button.theme = preload("res://themes/pindorama.tres")
	back_button.add_theme_font_size_override("font_size", 16)
	_style_action_button(back_button)
	back_button.pressed.connect(_return_to_menu)
	add_child(back_button)

	resized.connect(_layout_route)

func _style_stage_button(button: Button, available: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("304933") if available else Color("333a32")
	normal.border_color = Color("f0ce82") if available else Color("817e6e")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(34)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("486748")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("fff0c4") if available else Color("b2ad99"))
	button.add_theme_color_override("font_disabled_color", Color("999584"))

func _style_action_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("294330")
	normal.border_color = Color("bd9b54")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3b5a3d")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

func _layout_route() -> void:
	if stage_buttons.size() != STAGES.size():
		return
	var points := PackedVector2Array()
	for index in ROUTE_POINTS.size():
		var point := Vector2(ROUTE_POINTS[index].x * size.x, ROUTE_POINTS[index].y * size.y)
		points.append(point)
		stage_buttons[index].position = point - stage_buttons[index].size * 0.5
		stage_labels[index].size = Vector2(126, 44)
		stage_labels[index].position = Vector2(point.x - 63, point.y + 38)
	route_glow.points = points
	route_line.points = points

func _show_stage(index: int) -> void:
	if index < 0 or index >= STAGES.size():
		return
	selected_stage = index
	start_button.text = "Jogar fase %d" % (index + 1)
	var stage: Dictionary = STAGES[index]
	if not Progress.is_available(index):
		details_label.text = "FASE %d - %s - conclua a fase anterior" % [index + 1, stage["place"]]
	elif index == 0:
		details_label.text = "FASE 1  •  %s — tutorial disponível" % stage["place"]
	elif index == 1:
		details_label.text = "FASE 2 - Ratanab\u00e1 - Boitat\u00e1 dispon\u00edvel"
	else:
		details_label.text = "FASE %d - %s - dispon\u00edvel" % [index + 1, stage["place"]]
	start_button.disabled = not Progress.is_available(index)

func _start_selected_stage() -> void:
	if transitioning or start_button.disabled or not Progress.is_available(selected_stage):
		return
	transitioning = true
	get_node("/root/SceneTransition").load_level(Progress.stage_path(selected_stage))

func _return_to_menu() -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().change_scene_to_file("res://menu.tscn")
