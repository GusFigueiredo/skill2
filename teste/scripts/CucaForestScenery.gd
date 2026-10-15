extends Node2D

# The three source paintings share one pixel scale and one horizon. Gameplay and
# collisions remain in CucaForest; this node only composes the forest approach.
const FOREST_TEXTURE := preload("res://sprites/cenario/Fase5/background.png")
const ROAD_TEXTURE := preload("res://sprites/cenario/Fase5/cha.png")
const CAVE_TEXTURE := preload("res://sprites/cenario/Fase5/entrada caverna.png")
const FOREST_SHADER := preload("res://shaders/cuca_forest_scenery.gdshader")
const MIST_SHADER := preload("res://shaders/cuca_forest_mist.gdshader")
const STAGE_LENGTH := 4400.0
const CAVE_DOOR := Vector2(4260.0, 467.0)
const CAVE_TRIGGER := Vector2(3700.0, 450.0)

var level: Node2D
var elapsed := 0.0
var background: Sprite2D
var cave: Sprite2D
var configured := false

func setup(owner_level: Node2D) -> void:
	level = owner_level
	if is_inside_tree():
		_configure()

func _ready() -> void:
	name = "CucaForestScenery"
	if level == null:
		level = get_parent() as Node2D
	_configure()

func _configure() -> void:
	if configured or level == null:
		return
	configured = true
	z_index = -5
	# Replace the warm atmosphere from the first forest, keeping its combat FX.
	for child in level.get_children():
		var child_script := child.get_script() as Script
		if child_script != null and child_script.resource_path.ends_with("/Atmosphere.gd"):
			child.hide()
			child.set_process(false)
	background = level.get_node("Background") as Sprite2D
	_prepare_painting(background, FOREST_TEXTURE, Vector2(-1200.0, 62.0), 0.56, -30)
	var road := level.get_node("Ground") as Sprite2D
	_prepare_painting(road, ROAD_TEXTURE, Vector2(-1200.0, 260.0), 0.52, -20)
	# An inexpensive haze sits between the painting and the fighters, so the
	# moss and silhouettes remain readable even in the darker final stretch.
	var mist := ColorRect.new()
	mist.name = "ForestMist"
	mist.position = Vector2(-700.0, 200.0)
	mist.size = Vector2(STAGE_LENGTH + 1400.0, 360.0)
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist.z_index = -12
	var mist_material := ShaderMaterial.new()
	mist_material.shader = MIST_SHADER
	mist.material = mist_material
	level.add_child(mist)
	cave = Sprite2D.new()
	cave.name = "CaveEntrance"
	cave.texture = CAVE_TEXTURE
	cave.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cave.centered = false
	cave.position = Vector2(3960.0, 260.0)
	cave.scale = Vector2.ONE * 0.3
	cave.z_index = -10
	cave.modulate = Color(0.87, 0.93, 0.86)
	cave.set_meta("door_position", CAVE_DOOR)
	cave.set_meta("approach_position", CAVE_TRIGGER)
	level.add_child(cave)
	var marker := Marker2D.new()
	marker.name = "CaveDoor"
	marker.position = CAVE_DOOR
	level.add_child(marker)

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
	var paint_material := ShaderMaterial.new()
	paint_material.shader = FOREST_SHADER
	paint_material.set_shader_parameter("art_origin", origin)
	paint_material.set_shader_parameter("art_scale", art_scale)
	paint_material.set_shader_parameter("art_size", artwork.get_size())
	paint_material.set_shader_parameter("is_background", depth == -30)
	sprite.material = paint_material

func _process(delta: float) -> void:
	elapsed += delta
	if background != null and is_instance_valid(level):
		var camera := get_viewport().get_camera_2d()
		if camera != null:
			# Distant trunks move more slowly than the path. Vertical anchoring
			# keeps roots aligned while the player walks in and out of depth.
			background.position.x = -1200.0 + (camera.get_screen_center_position().x - 355.0) * 0.13
			background.material.set_shader_parameter("art_origin", background.position)
	queue_redraw()

func _draw() -> void:
	if not configured:
		return
	var view := get_viewport_rect()
	var inverse := get_canvas_transform().affine_inverse()
	var left := (inverse * view.position).x - 40.0
	var right := (inverse * view.end).x + 40.0
	# Small square cores preserve the pixel-art language. Sparse, soft halos
	# make the light breathe without placing bright blobs on the combat lane.
	for index in range(86):
		var seed := float(index) * 2.39996
		var x := fposmod(float(index) * 137.73 + sin(elapsed * 0.17 + seed) * 16.0, STAGE_LENGTH - 180.0) + 45.0
		if x < left or x > right:
			continue
		var y := 288.0 + fposmod(float(index) * 61.37, 190.0) + sin(elapsed * 0.33 + seed) * 9.0
		var pulse := pow(0.5 + 0.5 * sin(elapsed * 1.05 + seed), 2.0)
		var opacity := 0.09 + pulse * 0.46
		var point := Vector2(x, y)
		var shade := Color(0.76, 0.87, 0.37, opacity)
		draw_circle(point, 5.0, Color(shade.r, shade.g, shade.b, opacity * 0.025))
		draw_circle(point, 2.8, Color(shade.r, shade.g, shade.b, opacity * 0.065))
		draw_rect(Rect2(point.floor(), Vector2.ONE), shade)
	# A few leaves travel slowly through the upper plane, leaving the path
	# unobstructed and avoiding the visual noise of a full particle shower.
	for index in range(19):
		var x := fposmod(index * 271.9 + elapsed * (2.0 + index % 3), STAGE_LENGTH)
		if x < left or x > right:
			continue
		var y := 218.0 + fposmod(index * 93.7 + elapsed * 4.4, 132.0)
		var point := Vector2(x + sin(elapsed * 0.6 + index) * 10.0, y)
		var leaf_color := Color(0.40, 0.49, 0.22, 0.34)
		draw_line(point, point + Vector2(2.2, sin(elapsed + index) * 1.8), leaf_color, 1.0)
