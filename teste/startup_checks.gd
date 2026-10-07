extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	change_scene_to_file("res://splash.tscn")
	await process_frame
	await process_frame
	var splash = current_scene
	assert(splash.logo.texture.resource_path == "res://sprites/logo empresa.png")
	await create_timer(3.3).timeout
	assert(current_scene.scene_file_path == "res://menu.tscn", "Splash must automatically open the menu")
	current_scene._start_or_resume()
	var transition = root.get_node("SceneTransition")
	assert(transition.busy and paused)
	while transition.busy:
		await process_frame
	assert(current_scene.scene_file_path == "res://prologue.tscn" and not paused)
	current_scene._skip_prologue()
	while transition.busy:
		await process_frame
	assert(current_scene.scene_file_path == "res://level_map.tscn" and not paused)
	current_scene._start_selected_stage()
	while transition.busy:
		await process_frame
	assert(current_scene.scene_file_path == "res://main.tscn" and not paused)
	current_scene.player.hp = 0
	current_scene._reset_scene()
	while transition.busy:
		await process_frame
	assert(current_scene.player.hp == current_scene.player.max_hp and current_scene.wave_index == 0)
	assert(not transition.screen.visible and not paused)
	change_scene_to_file("res://splash.tscn")
	await process_frame
	await process_frame
	current_scene._finish()
	current_scene._finish()
	await create_timer(0.6).timeout
	assert(current_scene.scene_file_path == "res://menu.tscn", "Skipping must open the menu only once")
	print("PASS: company splash, automatic advance, skip, loading and restart")
	quit()
