extends Node2D

const BACKGROUND_TEXTURE := preload("res://sprites/cenario/Fases6/background.png")
const GROUND_TEXTURE := preload("res://sprites/cenario/Fases6/chão.png")
const STONE_SHADER := preload("res://shaders/cuca_cave_scenery.gdshader")
const MIST_SHADER := preload("res://shaders/cuca_cave_mist.gdshader")
const STAGE_LENGTH := 5200.0
const BACKGROUND_ORIGIN := Vector2(-1200.0, 62.0)
const PARALLAX_FACTOR := 0.13

var level: Node2D
var background: Sprite2D
var ground: Sprite2D
var ambient: CanvasModulate
var mist: ColorRect
var elapsed := 0.0
var configured := false
var anchor_center := Vector2(355.0, 380.0)

func setup(owner_level: Node2D) -> void:
	level = owner_level
	if is_inside_tree():
		_configure()

func _ready() -> void:
	name = "CucaCaveScenery"
	process_priority = 10
	if level == null:
		level = get_parent() as Node2D
	_configure()

func _configure() -> void:
	if configured or not is_instance_valid(level):
		return
	background = level.get_node_or_null("Background") as Sprite2D
	ground = level.get_node_or_null("Ground") as Sprite2D
	if background == null or ground == null:
		return
	configured = true
	z_index = -5
	# Presentation supplies a forest atmosphere to the inherited level. The
	# cave uses its own sparse mineral dust instead of leaves and fireflies.
	for child in level.get_children():
		var child_script := child.get_script() as Script
		if child_script != null and child_script.resource_path.ends_with("/Atmosphere.gd"):
			child.hide()
			child.set_process(false)
	_prepare_painting(background, BACKGROUND_TEXTURE, BACKGROUND_ORIGIN, 0.56, -30)
	_prepare_painting(ground, GROUND_TEXTURE, Vector2(-1200.0, 260.0), 0.52, -20)
	ambient = CanvasModulate.new()
	ambient.name = "CaveAmbient"
	# The supplied cave painting is already dark. A soft, even ambient keeps
	# enemies and floor edges readable without the removed wall torches.
	ambient.color = Color(0.84, 0.88, 0.86, 1.0)
	add_child(ambient)
	var dust_material := CanvasItemMaterial.new()
	dust_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = dust_material
	_build_mist()
	# Capture the displayed view after the encounter/checkpoint has placed
	# the player; no scenery jump when resuming in a later section.
	call_deferred("_capture_camera_anchor")

func _capture_camera_anchor() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		anchor_center = camera.get_screen_center_position()

func _prepare_painting(sprite: Sprite2D, artwork: Texture2D, origin: Vector2, art_scale: float, depth: int) -> void:
	sprite.texture = artwork
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.centered = false
	sprite.position = origin
	sprite.scale = Vector2.ONE * art_scale
	sprite.z_index = depth
	sprite.modulate = Color.WHITE
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = false
	sprite.region_rect = Rect2(0.0, 0.0, (STAGE_LENGTH + 2800.0) / art_scale, (1300.0 - origin.y) / art_scale)
	var stone_material := ShaderMaterial.new()
	stone_material.shader = STONE_SHADER
	stone_material.set_shader_parameter("is_background", depth == -30)
	sprite.material = stone_material

func _build_mist() -> void:
	mist = ColorRect.new()
	mist.name = "CaveDepthMist"
	mist.position = Vector2(-900.0, 205.0)
	mist.size = Vector2(STAGE_LENGTH + 2100.0, 360.0)
	mist.z_index = -12
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mist_material := ShaderMaterial.new()
	mist_material.shader = MIST_SHADER
	mist.material = mist_material
	level.add_child(mist)

func _process(delta: float) -> void:
	if not configured:
		return
	elapsed += delta
	var camera := get_viewport().get_camera_2d()
	var drift := (camera.get_screen_center_position().x - anchor_center.x) * PARALLAX_FACTOR if camera != null else 0.0
	background.position.x = BACKGROUND_ORIGIN.x + drift
	mist.material.set_shader_parameter("phase", elapsed)
	queue_redraw()

func _draw() -> void:
	if not configured:
		return
	var viewport := get_viewport_rect()
	var inverse := get_canvas_transform().affine_inverse()
	var left := (inverse * viewport.position).x - 25.0
	var right := (inverse * viewport.end).x + 25.0
	for index in range(74):
		var seed := float(index) * 2.39996
		var x := fposmod(index * 113.73 + sin(elapsed * 0.11 + seed) * 11.0, STAGE_LENGTH)
		if x < left or x > right:
			continue
		var y := 227.0 + fposmod(index * 43.7 + elapsed * (0.55 + index % 3 * 0.2), 197.0)
		var glow := 0.09 + (0.5 + 0.5 * sin(elapsed * 0.7 + seed)) * 0.13
		draw_rect(Rect2(Vector2(x, y).floor(), Vector2.ONE), Color(0.69, 0.77, 0.62, glow))
