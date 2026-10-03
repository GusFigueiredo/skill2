extends CanvasLayer

@export var main_menu: bool = true
@export var title_text: String = "LENDAS DO BRASIL"
@export var title_image: Texture2D

var panel: Control
var buttons: VBoxContainer
var controls_label: Label
var primary_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	panel = Control.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("101e22") if main_menu else Color(0.025, 0.05, 0.06, 0.9)
	panel.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buttons = VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(460, 0)
	buttons.add_theme_constant_override("separation", 18)
	center.add_child(buttons)
	if main_menu and title_image:
		var image := TextureRect.new()
		image.texture = title_image
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(460, 150)
		buttons.add_child(image)
	else:
		var title := Label.new()
		title.text = title_text if main_menu else "PAUSADO"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color("efcd85"))
		buttons.add_child(title)
	primary_button = _add_button("Jogar" if main_menu else "Continuar", _start_or_resume)
	_add_button("Controles", _toggle_controls)
	controls_label = Label.new()
	controls_label.text = "WASD / setas: mover\nEspaço: pular | K: atacar\nShift: rolada | Esc: pausar / continuar"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.visible = false
	buttons.add_child(controls_label)
	if not main_menu:
		_add_button("Voltar ao menu", _return_to_menu)
	_add_button("Sair", _quit_game)
	panel.visible = main_menu
	if main_menu:
		var music := preload("res://scripts/MusicPlayer.gd").new()
		add_child(music)
		music.play_track("res://music/Menu.mp3")
		primary_button.grab_focus()

func _add_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	buttons.add_child(button)
	return button

func _unhandled_input(event: InputEvent) -> void:
	if main_menu or not event is InputEventKey or event.echo or not event.pressed or event.keycode != KEY_ESCAPE:
		return
	var level := get_parent()
	if level.finished or level.player.hp <= 0:
		return
	_set_paused(not get_tree().paused)
	get_viewport().set_input_as_handled()

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	panel.visible = value
	if value:
		primary_button.grab_focus()
	else:
		primary_button.release_focus()

func _start_or_resume() -> void:
	if main_menu:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		_set_paused(false)

func _toggle_controls() -> void:
	controls_label.visible = not controls_label.visible

func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
