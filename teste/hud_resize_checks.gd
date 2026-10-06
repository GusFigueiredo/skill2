extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items")
	assert(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep")
	# Model the project's scaling on a window, including non-16:9 sizes.
	var window := Window.new()
	window.content_scale_size = Vector2i(1280, 720)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.add_child(window)
	var scene = load("res://main.tscn").instantiate()
	window.add_child(scene)
	scene.set_process(false)
	for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
		actor.set_physics_process(false)
	for resolution in [Vector2i(1152, 648), Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 1024), Vector2i(2560, 1080)]:
		window.size = resolution
		await process_frame
		await process_frame
		var viewport_rect := window.get_visible_rect()
		assert(viewport_rect.size.is_equal_approx(Vector2(1280, 720)), "HUD must retain its design coordinates at %s" % resolution)
		for control_name in ["HealthBar", "AttackCooldown", "DodgeCooldown", "ControlsLabel", "TutorialLabel"]:
			var control: Control = scene.get_node("HUD/" + control_name)
			assert(viewport_rect.encloses(control.get_global_rect()), "%s clipped at %s" % [control_name, resolution])
	window.queue_free()
	await process_frame
	print("PASS: HUD fits small, maximized, 4:3 and ultrawide windows")
	quit()
