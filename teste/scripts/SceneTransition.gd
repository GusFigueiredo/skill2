extends CanvasLayer

const MINIMUM_DISPLAY_SECONDS := 1.2
const GAME_LOGO := preload("res://sprites/Menu/extracted/logo.png")
var busy: bool = false
var screen: Control
var content: VBoxContainer
var progress_bar: ProgressBar
var status_label: Label
var elapsed: float = 0.0
var fade_screen: ColorRect
var phase := "idle"
var checkpoint_destination := ""
var exit_camera: Camera2D
var exit_target_x := 0.0
var exit_tween: Tween
var exit_leaf_index := 0
var exit_leaf_count := 0
const FADE_SECONDS := 0.6

class LilyLanding extends Node2D:

	var elapsed := 0.0
	const DURATION := 0.58

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 4

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= DURATION:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var progress := clampf(elapsed / DURATION, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
		for ring in range(2):
			var spread := clampf(progress * 1.5 - ring * 0.22, 0.0, 1.0)
			draw_arc(Vector2.ZERO, 24.0 + spread * 54.0, 0, TAU, 40, Color(0.62, 0.89, 0.78, (1.0 - spread) * 0.4), 1.4, true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	screen = Control.new()
	screen.name = "LoadingScreen"
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.draw.connect(_draw_embers)
	var background := ColorRect.new()
	background.color = Color("081310")
	screen.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The drawing belongs above the background, beneath the centered logo.
	background.show_behind_parent = true
	var center := CenterContainer.new()
	screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	center.add_child(content)
	var logo := TextureRect.new()
	logo.texture = GAME_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 140)
	content.add_child(logo)
	status_label = Label.new()
	status_label.text = "Carregando"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color("efcd85"))
	content.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 3)
	progress_bar.show_percentage = false
	for state in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("d9ae62") if state == "fill" else Color("22352a")
		style.set_corner_radius_all(2)
		progress_bar.add_theme_stylebox_override(state, style)
	content.add_child(progress_bar)
	screen.resized.connect(_resize_content)
	_resize_content()
	screen.hide()
	fade_screen = ColorRect.new()
	fade_screen.name = "SceneFade"
	fade_screen.color = Color.BLACK
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_screen)
	fade_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_screen.hide()
	set_process(false)

func _resize_content() -> void:
	content.custom_minimum_size.x = minf(360.0, screen.size.x * 0.7)

func _process(delta: float) -> void:
	elapsed += delta
	status_label.text = "Carregando" + ".".repeat(int(elapsed * 2.0) % 4)
	screen.queue_redraw()

func _draw_embers() -> void:
	for i in range(14):
		var x := screen.size.x * fmod(float(i) * 0.618, 1.0)
		var y := screen.size.y - fmod(float(i) * 73.0 + elapsed * (12.0 + i), screen.size.y)
		var opacity := (0.12 + 0.12 * sin(elapsed * 1.8 + i)) * sin(PI * y / maxf(screen.size.y, 1.0))
		screen.draw_circle(Vector2(x + sin(elapsed + i) * 10.0, y), 1.5, Color(0.85, 0.65, 0.3, opacity))

func load_level(path: String = "res://main.tscn", resume_checkpoint: bool = false) -> void:
	if busy:
		return
	busy = true
	checkpoint_destination = path if resume_checkpoint else ""
	await _load_destination(path)

func take_checkpoint(path: String) -> Dictionary:
	if checkpoint_destination != path:
		return {}
	checkpoint_destination = ""
	return preload("res://scripts/CampaignProgress.gd").checkpoint()

# Every gameplay stage calls the same exit and loading sequence.
func complete_level(level: Node2D, path: String, rescue_camera: Camera2D = null, leaf_route: Array[Vector2] = []) -> void:
	if busy:
		return
	busy = true
	phase = "waiting_for_defeat"
	level.finished = true
	var hero := level.get_node("Player") as CharacterBody2D
	var visual := hero.get_node("Sprite") as AnimatedSprite2D
	var original := hero.get_node("Camera2D") as Camera2D
	var leaf_exit := is_instance_valid(rescue_camera) and not leaf_route.is_empty()
	exit_leaf_index = 0
	exit_leaf_count = 0
	# Preserve the rescue composition for the victory title as well as the farewell.
	if is_instance_valid(rescue_camera):
		exit_camera = rescue_camera
		exit_camera.make_current()
	hero.set_physics_process(false)
	hero.velocity = Vector2.ZERO
	hero.facing = 1
	hero.jump_height = 0.0
	hero.jump_speed = 0.0
	hero.is_dodging = false
	visual.set_process(false)
	visual.process_mode = Node.PROCESS_MODE_ALWAYS
	visual.flip_h = false
	visual.play("idle")
	# Leave the tree running so death animations and their fade can finish.
	while _has_defeat_visuals(level):
		await get_tree().process_frame
	phase = "celebrating"
	var victory := preload("res://scripts/VictoryFeedback.gd").new()
	level.add_child(victory)
	await victory.finished
	level.get_node("HUD").hide()
	if level.get("music") != null:
		level.music.process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_instance_valid(rescue_camera):
		exit_camera = Camera2D.new()
		exit_camera.process_mode = Node.PROCESS_MODE_ALWAYS
		level.add_child(exit_camera)
		exit_camera.global_position = original.get_screen_center_position()
		exit_camera.zoom = original.zoom
		exit_camera.make_current()
	# Keep the camera still and move the entire character beyond the visible right edge.
	var half_view := get_viewport().get_visible_rect().size.x / (2.0 * exit_camera.zoom.x)
	var left_of_sprite: float = hero.combat_bounds.position.x
	for index in visual.sprite_frames.get_frame_count("walk"):
		var texture := visual.sprite_frames.get_frame_texture("walk", index)
		var opaque := texture.get_image().get_used_rect()
		left_of_sprite = minf(left_of_sprite, visual.position.x + (opaque.position.x - texture.get_width() * 0.5) * visual.scale.x)
	exit_target_x = exit_camera.global_position.x + half_view - minf(0.0, left_of_sprite) + 40.0
	get_tree().paused = true
	if leaf_exit:
		phase = "jumping_out"
		await _leave_on_lilies(level, hero, visual, leaf_route)
	else:
		phase = "walking_out"
		visual.play("walk")
		exit_tween = create_tween()
		exit_tween.tween_property(visual, "position", hero.sprite_base_position, 0.15)
		exit_tween.tween_property(hero, "global_position:x", exit_target_x, maxf(0.15, (exit_target_x - hero.global_position.x) / maxf(1.0, hero.speed)))
		await exit_tween.finished
	phase = "fading_out"
	fade_screen.modulate.a = 0.0
	fade_screen.show()
	var fade := create_tween()
	fade.tween_property(fade_screen, "modulate:a", 1.0, FADE_SECONDS)
	await fade.finished
	await _load_destination(path)

func _leave_on_lilies(level: Node2D, hero: CharacterBody2D, visual: AnimatedSprite2D, route: Array[Vector2]) -> void:
	var landings: Array[Vector2] = []
	for point in route:
		if point.x > hero.global_position.x + 12.0:
			landings.append(point)
	# The final leap must carry the whole sprite beyond the frame before the fade.
	var last_point: Vector2 = hero.global_position if landings.is_empty() else landings.back()
	while last_point.x < exit_target_x:
		last_point += Vector2(minf(145.0, exit_target_x - last_point.x), -3.0)
		landings.append(last_point)
	exit_leaf_count = landings.size()
	var resting_scale := visual.scale
	hero.sound_effects.process_mode = Node.PROCESS_MODE_ALWAYS
	for landing in landings:
		var launch_point := hero.global_position
		var distance := launch_point.distance_to(landing)
		var flight_time := clampf(distance / 260.0, 0.44, 0.72)
		var height := clampf(distance * 0.45, 48.0, 82.0)
		visual.play("jump")
		hero.sound_effects.play_effect("jump")
		exit_tween = create_tween()
		exit_tween.tween_method(_jump_between_lilies.bind(hero, visual, launch_point, landing, height), 0.0, 1.0, flight_time)
		await exit_tween.finished
		hero.global_position = landing
		hero.jump_height = 0.0
		hero.shadow_opacity = 1.0
		visual.position = hero.sprite_base_position
		visual.play("idle")
		exit_leaf_index += 1
		var ripple := LilyLanding.new()
		level.add_child(ripple)
		ripple.global_position = landing + Vector2(0, 5)
		# A short compression gives each leaf a distinct, readable landing.
		exit_tween = create_tween()
		exit_tween.tween_property(visual, "scale", resting_scale * Vector2(1.04, 0.95), 0.065)
		exit_tween.tween_property(visual, "scale", resting_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await exit_tween.finished
	visual.scale = resting_scale

func _jump_between_lilies(progress: float, hero: CharacterBody2D, visual: AnimatedSprite2D, start: Vector2, finish: Vector2, height: float) -> void:
	hero.global_position = start.lerp(finish, progress)
	hero.jump_height = 4.0 * height * progress * (1.0 - progress)
	hero.shadow_opacity = 1.0 - (hero.jump_height / maxf(height, 1.0)) * 0.55
	visual.position = hero.sprite_base_position - Vector2(0, hero.jump_height)
	hero.queue_redraw()

func _has_defeat_visuals(level: Node2D) -> bool:
	for remains in get_tree().get_nodes_in_group("enemy_defeat_visuals"):
		if level.is_ancestor_of(remains):
			return true
	return false

func _load_destination(path: String) -> void:
	phase = "loading"
	elapsed = 0.0
	progress_bar.value = 0
	status_label.text = "Carregando"
	screen.modulate.a = 1.0
	screen.show()
	# Loading artwork is above the black transition veil.
	move_child(screen, get_child_count() - 1)
	set_process(true)
	get_tree().paused = true
	# Render the overlay before requesting any work from the resource loader.
	await get_tree().process_frame
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		await _fail_loading()
		return
	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			await _fail_loading()
			return
		if not progress.is_empty():
			progress_bar.value = float(progress[0]) * 95.0
		if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= MINIMUM_DISPLAY_SECONDS:
			break
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null or get_tree().change_scene_to_packed(scene) != OK:
		await _fail_loading()
		return
	progress_bar.value = 100
	status_label.text = "Pronto"
	await get_tree().process_frame
	await get_tree().process_frame
	# Cover the new scene with black before dismissing the loading screen.
	fade_screen.modulate.a = 1.0
	fade_screen.show()
	screen.hide()
	move_child(fade_screen, get_child_count() - 1)
	phase = "fading_in"
	var fade := create_tween()
	fade.tween_property(fade_screen, "modulate:a", 0.0, FADE_SECONDS)
	await fade.finished
	_close()

func _fail_loading() -> void:
	status_label.text = "Não foi possível carregar a fase"
	await get_tree().create_timer(1.5, true).timeout
	_close()

func _close() -> void:
	checkpoint_destination = ""
	screen.hide()
	fade_screen.hide()
	phase = "idle"
	exit_camera = null
	set_process(false)
	get_tree().paused = false
	busy = false

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()
