extends Control

const MAP_SCENE := "res://level_map.tscn"
const WORLD_SIZE := Vector2(1280, 720)
const RUINS_BACKGROUND := preload("res://sprites/Menu/Background.png")
const FOREST_BACKGROUND := preload("res://sprites/cenario/Fases1e2/backgroundFases.png")
const PLAYER_FRAMES := preload("res://sprites/characters/player.tres")
const ENEMY_FRAMES := preload("res://sprites/characters/enemy.tres")
const BOITATA_FRAMES := preload("res://sprites/characters/boitata.tres")
const BEAT_DURATIONS := [6.0, 4.5, 3.8, 7.0, 6.0]

const STORY_FRAMES: Array[Dictionary] = [
	{
		"title": "RATANABÁ, A CIDADE PERDIDA",
		"body": "Séculos depois do desaparecimento de Ratanabá, um historiador atravessa as ruínas em busca de pistas."
	},
	{
		"title": "VESTÍGIOS DO PASSADO",
		"body": "Entre pedras partidas, ele encontra um artefato. A relíquia desperta sob suas mãos."
	},
	{
		"title": "A PASSAGEM",
		"body": "Uma luz antiga rompe o tempo. O historiador é lançado para o passado, quando Ratanabá ainda era habitada."
	},
	{
		"title": "A FLORESTA REVIDA",
		"body": "Criaturas atacam sem aviso. O viajante enfrenta os primeiros inimigos e percebe que a floresta esconde uma ameaça maior."
	},
	{
		"title": "A SOMBRA DO CORPO SECO",
		"body": "A Cuca prepara um ritual. Seu objetivo: impedir que o Corpo Seco atravesse para este mundo."
	}
]

var frame_index: int = 0
var frame_elapsed: float = 0.0
var transitioning: bool = false
var attack_started: bool = false
var enemy_hurt_started: bool = false
var enemy_fall_started: bool = false
var boitata_charge_started: bool = false
var boitata_dash_started: bool = false
var title_label: Label
var body_label: Label
var progress_label: Label
var next_button: Button
var world: Node2D
var city_layer: Node2D
var artifact_layer: Node2D
var forest_detail_layer: Node2D
var ruins_background: TextureRect
var forest_layer: TextureRect
var forest_floor: Polygon2D
var player_figure: AnimatedSprite2D
var enemy_figure: AnimatedSprite2D
var boitata_figure: AnimatedSprite2D
var artifact: Polygon2D
var artifact_glow: Polygon2D
var impact_flash: Polygon2D
var corpo_seco: Node2D
var scene_flash: ColorRect
var flash_tween: Tween

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_world()
	_build_story_ui()
	resized.connect(_resize_world)
	_resize_world()
	_show_frame()

func _build_world() -> void:
	ruins_background = TextureRect.new()
	ruins_background.name = "RatanabaBackdrop"
	ruins_background.texture = RUINS_BACKGROUND
	ruins_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruins_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ruins_background.modulate = Color(0.78, 0.68, 0.48, 0.82)
	ruins_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ruins_background)
	ruins_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var forest := TextureRect.new()
	forest.name = "ForestBackdrop"
	forest.texture = FOREST_BACKGROUND
	forest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	forest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	forest.modulate = Color(0.76, 0.9, 0.72, 0.94)
	forest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forest.visible = false
	add_child(forest)
	forest.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	forest_layer = forest

	world = Node2D.new()
	world.name = "CinematicWorld"
	add_child(world)

	city_layer = Node2D.new()
	city_layer.name = "RatanabaRuins"
	world.add_child(city_layer)
	_add_ruins()

	var ground := Polygon2D.new()
	ground.name = "ForestFloor"
	ground.polygon = PackedVector2Array([
		Vector2(0, 508), Vector2(220, 492), Vector2(470, 516), Vector2(710, 500),
		Vector2(980, 515), Vector2(1280, 490), Vector2(1280, 720), Vector2(0, 720)
	])
	ground.color = Color("223624")
	world.add_child(ground)
	forest_floor = ground

	forest_detail_layer = Node2D.new()
	forest_detail_layer.name = "ForestSilhouettes"
	world.add_child(forest_detail_layer)
	_add_forest_details()

	artifact_layer = Node2D.new()
	artifact_layer.name = "ArtifactScene"
	world.add_child(artifact_layer)
	artifact_glow = _make_polygon(
		"ArtifactGlow",
		PackedVector2Array([Vector2(0, -88), Vector2(48, 0), Vector2(0, 88), Vector2(-48, 0)]),
		Color(0.83, 0.6, 0.2, 0.22)
	)
	artifact_layer.add_child(artifact_glow)
	artifact = _make_polygon(
		"AwakeningArtifact",
		PackedVector2Array([Vector2(0, -42), Vector2(25, 0), Vector2(0, 42), Vector2(-25, 0)]),
		Color("f5d277")
	)
	artifact_layer.add_child(artifact)
	_add_artifact_rays()

	player_figure = _make_character("PlayerFigure", PLAYER_FRAMES, Vector2(205, 505), 1.0)
	world.add_child(player_figure)
	enemy_figure = _make_character("EnemyFigure", ENEMY_FRAMES, Vector2(1000, 505), 1.0)
	world.add_child(enemy_figure)
	boitata_figure = _make_character("BoitataFigure", BOITATA_FRAMES, Vector2(1110, 505), 1.45)
	boitata_figure.offset = Vector2(0, -84)
	boitata_figure.modulate = Color("f3a36c")
	world.add_child(boitata_figure)

	impact_flash = _make_polygon(
		"ImpactFlash",
		PackedVector2Array([
			Vector2(0, -37), Vector2(8, -12), Vector2(31, -23), Vector2(18, 0),
			Vector2(38, 12), Vector2(10, 15), Vector2(0, 39), Vector2(-8, 14),
			Vector2(-33, 22), Vector2(-18, 0), Vector2(-38, -12), Vector2(-12, -15)
		]),
		Color("ffe49a")
	)
	world.add_child(impact_flash)

	corpo_seco = _make_corpo_seco()
	world.add_child(corpo_seco)

	scene_flash = ColorRect.new()
	scene_flash.name = "SceneFlash"
	scene_flash.color = Color(1, 0.88, 0.56, 0)
	scene_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_flash)
	scene_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _add_ruins() -> void:
	var stone := Color("555342")
	var shadow := Color("292f27")
	var left_wall := _make_polygon("RuinWallLeft", PackedVector2Array([
		Vector2(0, 505), Vector2(0, 248), Vector2(60, 248), Vector2(60, 202),
		Vector2(102, 202), Vector2(102, 238), Vector2(146, 238), Vector2(146, 136),
		Vector2(190, 136), Vector2(190, 220), Vector2(226, 220), Vector2(226, 181),
		Vector2(265, 181), Vector2(265, 505)
	]), stone)
	city_layer.add_child(left_wall)
	var right_wall := _make_polygon("RuinWallRight", PackedVector2Array([
		Vector2(0, 505), Vector2(0, 285), Vector2(39, 285), Vector2(39, 244),
		Vector2(91, 244), Vector2(91, 271), Vector2(128, 271), Vector2(128, 177),
		Vector2(171, 177), Vector2(171, 248), Vector2(212, 248), Vector2(212, 220),
		Vector2(250, 220), Vector2(250, 505)
	]), shadow)
	right_wall.position = Vector2(1020, 0)
	city_layer.add_child(right_wall)

	for window_position in [
		Vector2(66, 302), Vector2(163, 282), Vector2(1084, 334), Vector2(1154, 306)
	]:
		var window := _make_polygon("DarkWindow", PackedVector2Array([
			Vector2(-9, -14), Vector2(9, -14), Vector2(9, 14), Vector2(-9, 14)
		]), Color("302f27"))
		window.position = window_position
		city_layer.add_child(window)

	var rubble := _make_polygon("BrokenRubble", PackedVector2Array([
		Vector2(0, 0), Vector2(75, -21), Vector2(142, -5), Vector2(190, 0),
		Vector2(170, 22), Vector2(42, 27)
	]), Color("68614a"))
	rubble.position = Vector2(330, 490)
	city_layer.add_child(rubble)

func _add_forest_details() -> void:
	for index in range(9):
		var x := 25.0 + index * 158.0
		var trunk := _make_polygon("ForestTrunk", PackedVector2Array([
			Vector2(-14, 0), Vector2(-10, -174), Vector2(9, -174), Vector2(15, 0)
		]), Color(0.12, 0.18, 0.12, 0.8))
		trunk.position = Vector2(x, 525)
		forest_detail_layer.add_child(trunk)
		var canopy := _make_polygon("ForestCanopy", PackedVector2Array([
			Vector2(-78, -162), Vector2(-51, -209), Vector2(-19, -224),
			Vector2(2, -262), Vector2(37, -228), Vector2(67, -216),
			Vector2(86, -166), Vector2(47, -143), Vector2(-49, -145)
		]), Color(0.11, 0.23, 0.14, 0.83))
		canopy.position = Vector2(x, 525)
		forest_detail_layer.add_child(canopy)

func _add_artifact_rays() -> void:
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var ray := _make_polygon("ArtifactRay", PackedVector2Array([
			Vector2(-5, -12), Vector2(5, -12), Vector2(3, -94), Vector2(-3, -94)
		]), Color(0.98, 0.76, 0.35, 0.22))
		ray.position = Vector2(685, 339)
		ray.rotation = angle
		artifact_layer.add_child(ray)

func _make_character(
	node_name: String,
	frames: SpriteFrames,
	feet_position: Vector2,
	sprite_scale: float
) -> AnimatedSprite2D:
	var character := AnimatedSprite2D.new()
	character.name = node_name
	character.sprite_frames = frames
	character.position = feet_position
	character.scale = Vector2.ONE * sprite_scale
	character.offset = Vector2(0, -52.5)
	character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	character.play("idle")
	return character

func _make_corpo_seco() -> Node2D:
	var reveal := Node2D.new()
	reveal.name = "CorpoSecoReveal"
	var cloak := _make_polygon("TatteredCloak", PackedVector2Array([
		Vector2(-7, -70), Vector2(-28, -55), Vector2(-37, -27), Vector2(-55, -9),
		Vector2(-75, 17), Vector2(-61, 28), Vector2(-39, 7), Vector2(-27, -7),
		Vector2(-32, 31), Vector2(-47, 77), Vector2(-20, 82), Vector2(-3, 43),
		Vector2(11, 80), Vector2(36, 77), Vector2(22, 25), Vector2(29, -7),
		Vector2(45, 15), Vector2(61, 36), Vector2(73, 25), Vector2(56, -10),
		Vector2(37, -39), Vector2(18, -61)
	]), Color(0.025, 0.018, 0.016, 0.98))
	reveal.add_child(cloak)
	var head := _make_polygon("DriedHead", PackedVector2Array([
		Vector2(-17, -79), Vector2(-12, -91), Vector2(0, -97), Vector2(12, -91),
		Vector2(18, -79), Vector2(15, -65), Vector2(0, -58), Vector2(-14, -65)
	]), Color(0.04, 0.025, 0.02, 1))
	reveal.add_child(head)
	for eye_x in [-7.0, 7.0]:
		var eye := _make_polygon("EmberEye", PackedVector2Array([
			Vector2(-3, -2), Vector2(3, -2), Vector2(3, 2), Vector2(-3, 2)
		]), Color("ff7042"))
		eye.position = Vector2(eye_x, -80)
		reveal.add_child(eye)
	return reveal

func _make_polygon(node_name: String, points: PackedVector2Array, tint: Color) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = node_name
	shape.polygon = points
	shape.color = tint
	return shape

func _build_story_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "StoryPanel"
	panel.anchor_left = 0.055
	panel.anchor_top = 0.72
	panel.anchor_right = 0.945
	panel.anchor_bottom = 0.965
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.047, 0.038, 0.95)
	panel_style.border_color = Color("bd9b54")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 26
	panel_style.content_margin_right = 26
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color("efcd85"))
	content.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 19)
	body_label.add_theme_color_override("font_color", Color("f3ead1"))
	content.add_child(body_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)
	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", Color("d1bd91"))
	footer.add_child(progress_label)
	var skip_button := _make_button("Pular prólogo")
	skip_button.pressed.connect(_open_map)
	footer.add_child(skip_button)
	next_button = _make_button("Avançar")
	next_button.pressed.connect(_advance)
	footer.add_child(next_button)

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(170, 44)
	button.theme = preload("res://themes/pindorama.tres")
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("ffe3a1"))
	button.add_theme_color_override("font_hover_color", Color("fff1c7"))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("294330")
	normal.border_color = Color("bd9b54")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3b5a3d")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	return button

func _resize_world() -> void:
	if not is_instance_valid(world):
		return
	world.scale = Vector2(size.x / WORLD_SIZE.x, size.y / WORLD_SIZE.y)

func _process(delta: float) -> void:
	if transitioning:
		return
	frame_elapsed += delta
	_update_beat_visuals()
	if frame_elapsed >= BEAT_DURATIONS[frame_index]:
		_advance()

func _show_frame() -> void:
	var frame: Dictionary = STORY_FRAMES[frame_index]
	title_label.text = str(frame["title"])
	body_label.text = str(frame["body"])
	progress_label.text = "PRÓLOGO  •  %d / %d" % [frame_index + 1, STORY_FRAMES.size()]
	next_button.text = "Ver mapa" if frame_index == STORY_FRAMES.size() - 1 else "Avançar"
	frame_elapsed = 0.0
	attack_started = false
	enemy_hurt_started = false
	enemy_fall_started = false
	boitata_charge_started = false
	boitata_dash_started = false

	city_layer.visible = frame_index < 2
	ruins_background.visible = frame_index < 2
	forest_layer.visible = frame_index >= 2
	forest_floor.visible = frame_index >= 2
	forest_detail_layer.visible = frame_index >= 2
	artifact_layer.visible = frame_index == 1
	artifact_layer.modulate.a = 0.0 if frame_index == 1 else 1.0
	artifact.scale = Vector2.ONE
	artifact_glow.scale = Vector2.ONE
	player_figure.visible = true
	enemy_figure.visible = frame_index == 3
	boitata_figure.visible = frame_index == 4
	corpo_seco.visible = false
	impact_flash.visible = false

	match frame_index:
		0:
			player_figure.position = Vector2(135, 505)
			player_figure.flip_h = false
			player_figure.play("walk")
			enemy_figure.play("idle")
			boitata_figure.play("idle")
		1:
			player_figure.position = Vector2(500, 505)
			player_figure.play("idle")
			artifact_layer.position = Vector2(675, 340)
		2:
			player_figure.position = Vector2(365, 505)
			player_figure.play("jump")
			_flash(Color(1, 0.88, 0.56, 0.9), 0.8)
		3:
			player_figure.position = Vector2(510, 505)
			player_figure.play("idle")
			enemy_figure.position = Vector2(950, 505)
			enemy_figure.play("walk")
			enemy_figure.flip_h = true
		4:
			player_figure.position = Vector2(445, 505)
			player_figure.play("idle")
			boitata_figure.position = Vector2(1110, 505)
			boitata_figure.play("walk")
			boitata_figure.flip_h = true
			corpo_seco.position = Vector2(795, 400)
			corpo_seco.scale = Vector2.ONE * 1.2

func _update_beat_visuals() -> void:
	match frame_index:
		0:
			var walk_time := minf(frame_elapsed, 3.6)
			player_figure.position.x = 135.0 + walk_time * 75.0
			if frame_elapsed >= 3.6 and player_figure.animation != "idle":
				player_figure.play("idle")
		1:
			var approach_time := minf(frame_elapsed, 1.5)
			player_figure.position.x = 500.0 + approach_time * 78.0
			if frame_elapsed < 1.5:
				if player_figure.animation != "walk":
					player_figure.play("walk")
			elif player_figure.animation != "idle":
				player_figure.play("idle")
			artifact_layer.modulate.a = clampf((frame_elapsed - 1.0) / 0.8, 0.0, 1.0)
			if frame_elapsed >= 1.8:
				var pulse := 1.0 + 0.12 * sin(frame_elapsed * 5.0)
				artifact.scale = Vector2.ONE * pulse
				artifact_glow.scale = Vector2.ONE * (1.0 + 0.18 * sin(frame_elapsed * 3.5))
				artifact_glow.rotation += 0.006
		2:
			player_figure.position.x = 365.0 + minf(frame_elapsed, 2.4) * 42.0
			if frame_elapsed > 2.4 and player_figure.animation != "idle":
				player_figure.play("idle")
		3:
			_update_battle_beat()
		4:
			_update_final_reveal()

func _update_battle_beat() -> void:
	if frame_elapsed < 0.9:
		player_figure.position.x = 510.0 + frame_elapsed * 110.0
		if player_figure.animation != "walk":
			player_figure.play("walk")
	elif frame_elapsed < 1.35 and player_figure.animation != "idle":
		player_figure.play("idle")
	if frame_elapsed < 1.25:
		enemy_figure.position.x = 950.0 - frame_elapsed * 200.0
		if enemy_figure.animation != "walk":
			enemy_figure.play("walk")
	elif not attack_started:
		attack_started = true
		enemy_figure.play("attack")
	if frame_elapsed >= 1.35 and not enemy_hurt_started:
		enemy_hurt_started = true
		player_figure.play("hurt")
		_flash(Color(1, 0.25, 0.12, 0.62), 0.2)
	if frame_elapsed >= 2.65 and player_figure.animation != "attack":
		player_figure.play("attack")
	if frame_elapsed >= 2.9 and not enemy_fall_started:
		enemy_fall_started = true
		enemy_figure.play("hurt")
		impact_flash.position = Vector2(675, 394)
		impact_flash.visible = true
		_flash(Color(1, 0.76, 0.35, 0.48), 0.25)
	if frame_elapsed >= 3.45 and enemy_figure.animation != "death":
		enemy_figure.play("death")
	if frame_elapsed > 4.2 and impact_flash.visible:
		impact_flash.visible = false

func _update_final_reveal() -> void:
	if frame_elapsed < 1.8:
		boitata_figure.position.x = 1110.0 - frame_elapsed * 125.0
	elif not boitata_charge_started:
		boitata_charge_started = true
		boitata_figure.play("windup")
	elif frame_elapsed >= 2.55 and frame_elapsed < 3.25:
		if not boitata_dash_started:
			boitata_dash_started = true
			boitata_figure.play("dash")
		boitata_figure.position.x = 885.0 - (frame_elapsed - 2.55) * 190.0
	elif frame_elapsed >= 3.25:
		boitata_figure.visible = false
	if frame_elapsed >= 3.4:
		corpo_seco.visible = true
		corpo_seco.position.y = 415.0 - minf(frame_elapsed - 3.4, 1.2) * 34.0

func _flash(tint: Color, duration: float) -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	scene_flash.color = tint
	flash_tween = create_tween()
	flash_tween.tween_property(scene_flash, "color:a", 0.0, duration)

func _advance() -> void:
	if transitioning:
		return
	if frame_index == STORY_FRAMES.size() - 1:
		_open_map()
		return
	frame_index += 1
	_show_frame()

func _open_map() -> void:
	if transitioning:
		return
	transitioning = true
	get_node("/root/SceneTransition").load_level(MAP_SCENE)

func _skip_prologue() -> void:
	_open_map()

func _unhandled_input(event: InputEvent) -> void:
	if transitioning or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_skip_prologue()
	elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_RIGHT:
		_advance()
	get_viewport().set_input_as_handled()
