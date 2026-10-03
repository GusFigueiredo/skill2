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
	menu._toggle_controls()
	check(menu.controls_label.visible, "Controls must open")
	menu._start_or_resume()
	await process_frame
	await process_frame
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
	await process_frame
	await process_frame
	check(current_scene.player.hp == current_scene.player.max_hp and current_scene.wave_index == 0, "New game must reset level")
	print("PASS: main menu, controls, start, Escape pause/resume, frozen combat, continue and return/new game")
	quit(0)
