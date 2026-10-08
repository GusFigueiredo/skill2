extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
		actor.set_physics_process(false)
	scene.trigger_death()
	var screen = scene.get_node("DeathScreen")
	var title: Label = screen.get_node("CenterContainer/VBoxContainer/Label")
	var button: Button = screen.get_node("CenterContainer/VBoxContainer/ResetButton")
	var menu: Button = screen.get_node("CenterContainer/VBoxContainer/MenuButton")
	assert(button.get_theme_stylebox("normal") is StyleBoxTexture)
	assert(menu.get_theme_stylebox("normal").texture == button.get_theme_stylebox("normal").texture)
	assert(screen.visible and title.text == "MORREU")
	assert(title.get_theme_font("font") == button.get_theme_font("font"))
	assert(is_zero_approx(title.modulate.a))
	assert(button.disabled and is_zero_approx(button.modulate.a))
	assert(menu.disabled and is_zero_approx(menu.modulate.a))
	var original_tween = screen.reveal
	scene.trigger_death()
	assert(screen.reveal == original_tween, "Repeated death must not restart the reveal")
	screen.reveal.custom_step(1.5)
	assert(title.modulate.a > 0.0 and title.modulate.a < 1.0)
	assert(button.disabled and is_zero_approx(button.modulate.a), "Reset must wait for the death message")
	for step in range(60):
		screen.reveal.custom_step(0.1)
		if not screen.reveal.is_running():
			break
	assert(is_equal_approx(title.modulate.a, 1.0))
	assert(is_equal_approx(button.modulate.a, 1.0) and not button.disabled)
	assert(button.has_focus())
	assert(is_equal_approx(menu.modulate.a, 1.0) and not menu.disabled)
	menu.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://menu.tscn")
	if is_instance_valid(scene):
		scene.free()
	print("PASS: red death message fades in before reset appears and becomes interactive")
	quit()
