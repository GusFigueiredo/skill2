extends CanvasLayer

var reveal: Tween
var showing_death: bool = false

func setup_buttons() -> void:
	var box: VBoxContainer = $CenterContainer/VBoxContainer
	var reset: Button = box.get_node("ResetButton")
	preload("res://scripts/GameMenu.gd").style_button(reset)
	reset.custom_minimum_size = Vector2(420, 64)
	var menu := Button.new()
	menu.name = "MenuButton"
	menu.text = "Voltar ao menu"
	menu.custom_minimum_size = reset.custom_minimum_size
	preload("res://scripts/GameMenu.gd").style_button(menu)
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	box.add_child(menu)

func show_death() -> void:
	if showing_death:
		return
	showing_death = true
	if reveal:
		reveal.kill()
	var title: Label = $CenterContainer/VBoxContainer/Label
	var button: Button = $CenterContainer/VBoxContainer/ResetButton
	var menu: Button = $CenterContainer/VBoxContainer/MenuButton
	var veil: ColorRect = $Veil
	var box: VBoxContainer = $CenterContainer/VBoxContainer
	box.add_theme_constant_override("separation", 56)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Times New Roman", "Liberation Serif", "serif"])
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color("a32b28"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.text = "MORREU"
	title.modulate.a = 0.0
	button.text = "Reiniciar fase"
	for action in [button, menu]:
		action.modulate.a = 0.0
		action.disabled = true
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action.release_focus()
	veil.color = Color(0.005, 0.005, 0.005, 0.0)
	visible = true
	# A slow reveal keeps the fatal moment visible beneath the dark overlay.
	reveal = create_tween()
	reveal.set_parallel(true)
	reveal.tween_property(veil, "color:a", 0.72, 1.6)
	reveal.tween_property(title, "modulate:a", 1.0, 2.2).set_delay(0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reveal.chain().tween_interval(0.6)
	reveal.chain().tween_property(button, "modulate:a", 1.0, 0.55)
	reveal.parallel().tween_property(menu, "modulate:a", 1.0, 0.55)
	reveal.chain().tween_callback(func():
		for action in [button, menu]:
			action.disabled = false
			action.mouse_filter = Control.MOUSE_FILTER_STOP
		button.grab_focus()
	)
