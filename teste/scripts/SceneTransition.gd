extends CanvasLayer

const MINIMUM_DISPLAY_SECONDS := 1.2
const GAME_LOGO := preload("res://sprites/Menu/extracted/logo.png")
var busy: bool = false
var screen: Control
var content: VBoxContainer
var progress_bar: ProgressBar
var status_label: Label
var elapsed: float = 0.0

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
	elapsed = 0.0
	progress_bar.value = 0
	status_label.text = "Carregando"
	screen.modulate.a = 1.0
	screen.show()
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
	var fade := create_tween()
	fade.tween_interval(0.15)
	fade.tween_property(screen, "modulate:a", 0.0, 0.35)
	await fade.finished
	_close()

func _fail_loading() -> void:
	status_label.text = "Não foi possível carregar a fase"
	await get_tree().create_timer(1.5, true).timeout
	_close()

func _close() -> void:
	screen.hide()
	set_process(false)
	get_tree().paused = false
	busy = false

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()
