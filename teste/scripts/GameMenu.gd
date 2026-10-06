extends CanvasLayer

@export var main_menu: bool = true
@export var title_text: String = "PINDORAMA"
@export var title_image: Texture2D

const MENU_BACKGROUND := preload("res://sprites/Menu/extracted/background.png")
const MENU_LOGO := preload("res://sprites/Menu/extracted/logo.png")
const GOLD_CURSOR := preload("res://sprites/Menu/extracted/cursor.png")
const MENU_THEME := preload("res://themes/pindorama.tres")
const BUTTON_TEXTURES := {
	"normal": preload("res://sprites/Menu/extracted/button_normal.png"),
	"hover": preload("res://sprites/Menu/extracted/button_hover.png"),
	"pressed": preload("res://sprites/Menu/extracted/button_pressed.png"),
	"disabled": preload("res://sprites/Menu/extracted/button_disabled.png"),
}

var panel: Control
var buttons: VBoxContainer
var controls_label: Label
var primary_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	panel = Control.new()
	panel.theme = MENU_THEME
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.set_custom_mouse_cursor(GOLD_CURSOR, Input.CURSOR_ARROW, Vector2(1, 1))
	Input.set_custom_mouse_cursor(GOLD_CURSOR, Input.CURSOR_POINTING_HAND, Vector2(1, 1))
	if main_menu:
		var scenery := TextureRect.new()
		scenery.name = "MenuBackground"
		scenery.texture = MENU_BACKGROUND
		scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(scenery)
		scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.01, 0.025, 0.02, 0.2) if main_menu else Color(0.025, 0.05, 0.06, 0.9)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buttons = VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(560, 0)
	buttons.add_theme_constant_override("separation", 18)
	center.add_child(buttons)
	if main_menu:
		var image := TextureRect.new()
		image.name = "MenuLogo"
		image.texture = title_image if title_image else MENU_LOGO
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(560, 165)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	controls_label.add_theme_color_override("font_color", Color("f6dfab"))
	controls_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls_label.add_theme_constant_override("shadow_offset_x", 2)
	controls_label.add_theme_constant_override("shadow_offset_y", 2)
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
	button.custom_minimum_size = Vector2(340, 72)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 30)
	for state in BUTTON_TEXTURES:
		var style := StyleBoxTexture.new()
		style.texture = BUTTON_TEXTURES[state]
		style.texture_margin_left = 24
		style.texture_margin_right = 24
		style.texture_margin_top = 12
		style.texture_margin_bottom = 12
		style.content_margin_left = 32
		style.content_margin_right = 32
		button.add_theme_stylebox_override(state, style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("ffd878")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("ffe3a1"))
	button.add_theme_color_override("font_hover_color", Color("fff1c7"))
	button.add_theme_color_override("font_pressed_color", Color("ffcd70"))
	button.add_theme_color_override("font_outline_color", Color("29180e"))
	button.add_theme_constant_override("outline_size", 4)
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
