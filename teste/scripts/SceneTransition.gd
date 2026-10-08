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
var exit_camera: Camera2D
var exit_target_x := 0.0
var exit_tween: Tween
const FADE_SECONDS := 0.6

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

func load_level(path: String = "res://main.tscn") -> void:
	if busy:
		return
	busy = true
	await _load_destination(path)

# Every gameplay stage calls the same exit and loading sequence.
func complete_level(level: Node2D, path: String) -> void:
	if busy:
		return
	busy = true
	phase = "waiting_for_defeat"
	level.finished = true
	var hero := level.get_node("Player") as CharacterBody2D
	var visual := hero.get_node("Sprite") as AnimatedSprite2D
	var original := hero.get_node("Camera2D") as Camera2D
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
	phase = "walking_out"
	visual.play("walk")
	level.get_node("HUD").hide()
	if level.get("music") != null:
		level.music.process_mode = Node.PROCESS_MODE_ALWAYS
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
