extends RefCounted

static func panel(rect: Rect2) -> Panel:
	var result := Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.065, 0.91)
	style.border_color = Color(0.66, 0.48, 0.24, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 8
	result.add_theme_stylebox_override("panel", style)
	return result

static func setup(level: Node2D) -> void:
	level.add_child(preload("res://scripts/Atmosphere.gd").new())
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	level.add_child(overlay)
	var shade := ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.material = ShaderMaterial.new()
	shade.material.shader = preload("res://shaders/atmosphere.gdshader")
	overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hud := level.get_node("HUD")
	var plate := panel(Rect2(20, 18, 410, 92))
	hud.add_child(plate)
	hud.move_child(plate, 0)
	hud.get_node("TutorialLabel").hide()
	hud.get_node("ControlsLabel").hide()
	var positions := {
		"HealthBar": Rect2(24, 20, 400, 65),
		"HealthLabel": Rect2(48, 80, 340, 26),
		"WaveLabel": Rect2(48, 106, 360, 26),
		"AttackCooldown": Rect2(48, 90, 156, 6),
		"DodgeCooldown": Rect2(222, 90, 156, 6),
		"CooldownLabel": Rect2(48, 149, 340, 24),
		"ControlsLabel": Rect2(820, 24, 430, 54),
		"TutorialLabel": Rect2(44, 650, 1192, 42),
	}
	for node_name in positions:
		var control: Control = hud.get_node(node_name)
		control.position = positions[node_name].position
		control.size = positions[node_name].size
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if control is Label:
			control.add_theme_color_override("font_color", Color("f4e2be"))
			control.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
			control.add_theme_constant_override("shadow_offset_y", 2)
			control.add_theme_font_size_override("font_size", 20 if node_name == "TutorialLabel" else 18)
	for label_name in ["HealthLabel", "WaveLabel", "CooldownLabel"]:
		hud.get_node(label_name).hide()
	hud.get_node("ControlsLabel").horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for bar_name in ["AttackCooldown", "DodgeCooldown"]:
		var bar: ProgressBar = hud.get_node(bar_name)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("172827")
		background.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("d9ae62") if bar_name == "AttackCooldown" else Color("69bfae")
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", background)
		bar.add_theme_stylebox_override("fill", fill)
	hud.get_node("BossHealth/BossName").text = "BOITATÁ"
	var death := level.get_node("DeathScreen")
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.color = Color(0.015, 0.035, 0.04, 0.85)
	death.add_child(veil)
	death.move_child(veil, 0)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = death.get_node("CenterContainer")
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box: VBoxContainer = center.get_node("VBoxContainer")
	box.add_theme_constant_override("separation", 24)
	var title: Label = box.get_node("Label")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("efcd85"))
	death.set_script(preload("res://scripts/DeathPresentation.gd"))
	death.setup_buttons()
