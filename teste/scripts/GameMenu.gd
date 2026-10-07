extends CanvasLayer

@export var main_menu: bool = true
@export var title_text: String = "PINDORAMA"
@export var title_image: Texture2D

const MENU_BACKGROUND := preload("res://sprites/Menu/Background.png")
const MENU_LOGO := preload("res://sprites/Menu/extracted/logo.png")
const GOLD_CURSOR := preload("res://sprites/Menu/extracted/cursor.png")
const MENU_THEME := preload("res://themes/pindorama.tres")
const BUTTON_SHEET := preload("res://sprites/Menu/botões menu.png")
# The sheet contains the glowing selection above the idle variants.
const BUTTON_NORMAL_REGION := Rect2(50, 440, 985, 300)
const BUTTON_SELECTED_REGION := Rect2(50, 100, 985, 340)
const BACKGROUND_FADE_DURATION := 0.35
const MENU_FADE_DURATION := 1.1
const MENU_BUTTON_SIZE := Vector2(360, 112)

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
		var black_backdrop := ColorRect.new()
		black_backdrop.name = "BlackBackdrop"
		black_backdrop.color = Color.BLACK
		black_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(black_backdrop)
		black_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	if main_menu:
		var atmosphere := ColorRect.new()
		atmosphere.name = "ForestAtmosphere"
		atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var atmosphere_material := ShaderMaterial.new()
		atmosphere_material.shader = preload("res://shaders/menu_atmosphere.gdshader")
		atmosphere.material = atmosphere_material
		panel.add_child(atmosphere)
		atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var particles := preload("res://scripts/MenuAtmosphere.gd").new()
		particles.name = "MenuParticles"
		panel.add_child(particles)
		particles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buttons = VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(560, 0)
	buttons.add_theme_constant_override("separation", 18)
	center.add_child(buttons)
	if main_menu:
		var logo_center := CenterContainer.new()
		logo_center.name = "MenuLogoCenter"
		logo_center.custom_minimum_size = Vector2(560, 165)
		logo_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(logo_center)
		var image := TextureRect.new()
		image.name = "MenuLogo"
		image.texture = title_image if title_image else MENU_LOGO
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(560, 165)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_center.add_child(image)
		var logo_shadow := TextureRect.new()
		logo_shadow.name = "LogoShadow"
		logo_shadow.texture = image.texture
		logo_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_shadow.show_behind_parent = true
		logo_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var shadow_material := ShaderMaterial.new()
		shadow_material.shader = preload("res://shaders/logo_shadow.gdshader")
		logo_shadow.material = shadow_material
		image.add_child(logo_shadow)
		logo_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		logo_shadow.offset_left = 5
		logo_shadow.offset_top = 8
		logo_shadow.offset_right = 5
		logo_shadow.offset_bottom = 8
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
		_animate_entrance()

func _animate_entrance() -> void:
	for node_name in ["MenuBackground", "ForestAtmosphere", "MenuParticles"]:
		var backdrop := panel.get_node(NodePath(node_name)) as CanvasItem
		backdrop.modulate.a = 0.0
		var reveal := backdrop.create_tween()
		reveal.tween_property(backdrop, "modulate:a", 1.0, BACKGROUND_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var delay := 0.2
	for child in buttons.get_children():
		if not child is Control or not child.visible:
			continue
		child.modulate.a = 0.0
		var entrance := child.create_tween()
		entrance.tween_interval(delay)
		entrance.tween_property(child, "modulate:a", 1.0, MENU_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		delay += 0.09

func _add_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button)
	button.pressed.connect(callback)
	buttons.add_child(button)
	return button

static func style_button(button: Button) -> void:
	button.custom_minimum_size = MENU_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.theme = MENU_THEME
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 30)

	var normal_style := StyleBoxTexture.new()
	normal_style.texture = BUTTON_SHEET
	normal_style.region_rect = BUTTON_NORMAL_REGION
	normal_style.texture_margin_left = 0
	normal_style.texture_margin_right = 0
	normal_style.texture_margin_top = 0
	normal_style.texture_margin_bottom = 0
	normal_style.content_margin_left = 32
	normal_style.content_margin_right = 32
	normal_style.content_margin_top = 18
	normal_style.content_margin_bottom = 18
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxTexture.new()
	hover_style.texture = BUTTON_SHEET
	hover_style.region_rect = BUTTON_SELECTED_REGION
	hover_style.texture_margin_left = 0
	hover_style.texture_margin_right = 0
	hover_style.texture_margin_top = 0
	hover_style.texture_margin_bottom = 0
	hover_style.content_margin_left = 32
	hover_style.content_margin_right = 32
	hover_style.content_margin_top = 18
	hover_style.content_margin_bottom = 18
	button.set_meta("menu_normal_style", normal_style)
	button.set_meta("menu_selected_style", hover_style)
	button.add_theme_stylebox_override("disabled", normal_style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Mouse and keyboard share one focus owner, so only one button is selected.
	button.mouse_entered.connect(func():
		if not button.disabled:
			button.grab_focus()
	)
	button.mouse_exited.connect(func():
		if button.has_focus():
			button.release_focus()
	)
	button.focus_entered.connect(func(): _select_button(button, true))
	button.focus_exited.connect(func(): _select_button(button, false))
	button.resized.connect(func(): _align_button_frame(button))
	_select_button(button, false, false)
	button.add_theme_color_override("font_color", Color("ffe3a1"))
	button.add_theme_color_override("font_hover_color", Color("fff1c7"))
	button.add_theme_color_override("font_pressed_color", Color("ffcd70"))
	button.add_theme_color_override("font_outline_color", Color("29180e"))
	button.add_theme_constant_override("outline_size", 4)

static func _align_button_frame(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	var normal_style: StyleBoxTexture = button.get_meta("menu_normal_style")
	var selected_style: StyleBoxTexture = button.get_meta("menu_selected_style")
	# Initialize existing buttons too: their size may already be final when styled.
	for style in [normal_style, selected_style]:
		style.content_margin_top = button.size.y * 0.14
		style.content_margin_bottom = button.size.y * 0.28
	# Keep the stone frame aligned; only the extra glow extends above it.
	selected_style.expand_margin_top = button.size.y * 40.0 / 300.0

static func _select_button(button: Button, selected: bool, animate: bool = true) -> void:
	_align_button_frame(button)
	var style: StyleBoxTexture = button.get_meta("menu_selected_style" if selected else "menu_normal_style")
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.pivot_offset = button.size * 0.5
	button.z_index = 1 if selected else 0
	var previous: Tween = button.get_meta("menu_scale_tween") if button.has_meta("menu_scale_tween") else null
	if previous and previous.is_valid():
		previous.kill()
	var target := Vector2.ONE * (1.06 if selected else 1.0)
	if not animate or not button.is_inside_tree():
		button.scale = target
		return
	var tween := button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, 0.16)
	button.set_meta("menu_scale_tween", tween)

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
		get_node("/root/SceneTransition").load_level("res://prologue.tscn")
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
