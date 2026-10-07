extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func run_checks() -> void:
	change_scene_to_file("res://menu.tscn")
	await process_frame
	await process_frame
	var menu = current_scene
	check(menu.panel.visible and menu.primary_button.text == "Jogar", "Game must open on main menu")
	var logo_center := menu.buttons.get_child(0) as CenterContainer
	var logo := logo_center.get_node("MenuLogo") as TextureRect
	var logo_shadow := logo.get_node("LogoShadow") as TextureRect
	check(is_equal_approx(logo_center.get_global_rect().get_center().x, menu.get_viewport().get_visible_rect().size.x * 0.5), "Menu logo container must stay horizontally centered")
	check(is_equal_approx(logo.get_global_rect().get_center().x, logo_center.get_global_rect().get_center().x), "Logo image must be centered inside its frame")
	check(logo_shadow.offset_left == 5.0 and logo_shadow.offset_top == 8.0 and logo_shadow.offset_right == 5.0 and logo_shadow.offset_bottom == 8.0, "Logo shadow must remain fully sized and sit behind the centered image")
	var controls_button: Button = menu.buttons.get_child(menu.primary_button.get_index() + 1)
	controls_button.mouse_entered.emit()
	check(controls_button.has_focus() and not menu.primary_button.has_focus(), "Mouse selection must move focus away from Jogar")
	check(menu.primary_button.get_theme_stylebox("normal") == menu.primary_button.get_meta("menu_normal_style"), "Jogar must stop glowing when another button is selected")
	await create_timer(0.2, true).timeout
	check(controls_button.scale.is_equal_approx(Vector2.ONE * 1.06), "Selected button must animate to six percent larger")
	check(menu.primary_button.scale.is_equal_approx(Vector2.ONE), "Previous selection must return to its original size")
	var selected_style: StyleBoxTexture = controls_button.get_theme_stylebox("normal")
	check(is_equal_approx(selected_style.expand_margin_top, controls_button.size.y * 40.0 / 300.0), "Selected glow must expand outside the frame instead of shrinking it")
	controls_button.mouse_exited.emit()
	await create_timer(0.2, true).timeout
	check(not controls_button.has_focus() and controls_button.scale.is_equal_approx(Vector2.ONE), "Leaving a button must clear selection and restore its size")
	menu.primary_button.grab_focus()
	await create_timer(0.2, true).timeout
	check(menu.primary_button.scale.is_equal_approx(Vector2.ONE * 1.06), "Keyboard focus must also animate selection")
	menu._toggle_controls()
	check(menu.controls_label.visible, "Controls must open")
	menu._start_or_resume()
	await start_level_from_menu()
	var level = current_scene
	var pause_menu = level.get_node("PauseMenu")
	check(not paused and not pause_menu.panel.visible, "Starting game must hide pause menu")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	pause_menu._unhandled_input(escape)
	check(paused and pause_menu.panel.visible, "Escape must pause and show menu")
	var position_before: Vector2 = level.player.position
	var cooldown_before: float = level.boss.charge_cooldown_timer
	await create_timer(0.15, true).timeout
	check(level.player.position == position_before and level.boss.charge_cooldown_timer == cooldown_before, "Paused game must freeze actors and combat timers")
	pause_menu._unhandled_input(escape)
	check(not paused and not pause_menu.panel.visible, "Escape must resume")
	pause_menu._set_paused(true)
	pause_menu._start_or_resume()
	check(not paused, "Continue button must resume")
	pause_menu._set_paused(true)
	pause_menu._return_to_menu()
	await process_frame
	await process_frame
	check(not paused and current_scene.main_menu, "Returning to menu must clear pause")
	current_scene._start_or_resume()
	await start_level_from_menu()
	check(current_scene.player.hp == current_scene.player.max_hp and current_scene.wave_index == 0, "New game must reset level")
	print("PASS: main menu, controls, start, Escape pause/resume, frozen combat, continue and return/new game")
	quit(0)

func start_level_from_menu() -> void:
	await wait_for_loading()
	check(current_scene.scene_file_path == "res://prologue.tscn", "Starting a game must open the prologue")
	for _frame in current_scene.STORY_FRAMES.size():
		current_scene._advance()
	await wait_for_loading()
	check(current_scene.scene_file_path == "res://level_map.tscn", "The prologue must lead to the level map")
	check(current_scene.stage_buttons.size() == 7, "The campaign map must contain seven stages")
	current_scene._start_selected_stage()
	await wait_for_loading()

func wait_for_loading() -> void:
	var transition = root.get_node("SceneTransition")
	check(transition.busy and transition.screen.visible and paused, "Loading must cover and freeze the previous scene")
	while transition.busy:
		await process_frame
	check(not transition.screen.visible and not paused, "Loading must release the game when ready")
