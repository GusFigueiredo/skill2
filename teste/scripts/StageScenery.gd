extends Node2D

# The distant painting follows a small fraction of the displayed camera's
# travel. The walkable road, pits and Iara's river bank stay in world space;
# only the road's texture joins receive the same seamless mirrored sampling.
const BACKGROUND_SHADER := preload("res://shaders/stage_scenery.gdshader")
const MIST_SHADER := preload("res://shaders/stage_depth_mist.gdshader")

var background: Sprite2D
var configured := false
var base_background_position := Vector2.ZERO
var anchor_center := Vector2.ZERO
var parallax_factor := 0.13
var elapsed := 0.0
var mist: ColorRect
var level: Node2D

func _ready() -> void:
	name = "StageScenery"
	level = get_parent() as Node2D
	process_priority = 10
	# Iara replaces the ground and adjusts Background after super._ready().
	# Capture that final composition instead of moving it back to Level1's.
	call_deferred("_configure")

func _configure() -> void:
	if configured or not is_instance_valid(level):
		return
	var stage := int(level.get("stage_index"))
	if stage < 0 or stage > 3:
		return
	background = level.get_node_or_null("Background") as Sprite2D
	if background == null or background.texture == null:
		return
	base_background_position = background.position
	anchor_center = _displayed_camera_center()
	var river_theme := stage >= 2
	background.z_index = -4
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The shader keeps the existing UVs and source painting scale, including
	# the oversized region used when the cutscene camera zooms out.
	var paint := ShaderMaterial.new()
	paint.shader = BACKGROUND_SHADER
	paint.set_shader_parameter("river_theme", river_theme)
	background.material = paint
	# Match the existing road's coordinates, alpha and modulation exactly.
	# BossGround deliberately keeps its original material: mirroring that
	# asymmetric painting would turn Iara's dry shore into a second river.
	var ground := level.get_node_or_null("Ground") as Sprite2D
	if ground != null:
		var road_paint := ShaderMaterial.new()
		road_paint.shader = BACKGROUND_SHADER
		road_paint.set_shader_parameter("is_background", false)
		ground.material = road_paint
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_mist(river_theme)
	configured = true

func _displayed_camera_center() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		return camera.get_screen_center_position()
	return Vector2(355.0, 380.0)

func _build_mist(river_theme: bool) -> void:
	mist = ColorRect.new()
	mist.name = "SceneryDepthMist"
	mist.position = Vector2(-2400.0, 185.0)
	mist.size = Vector2(9000.0, 345.0)
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist.z_index = -2
	var fog := ShaderMaterial.new()
	fog.shader = MIST_SHADER
	fog.set_shader_parameter("river_theme", river_theme)
	fog.set_shader_parameter("phase", elapsed)
	mist.material = fog
	level.add_child(mist)

func _process(delta: float) -> void:
	if not configured or not is_instance_valid(background):
		return
	elapsed += delta
	var center := _displayed_camera_center()
	# Use the active camera, including cinematic cameras. Zoom never enters
	# this calculation, and switching cameras does not reset the anchor.
	background.position.x = base_background_position.x + (center.x - anchor_center.x) * parallax_factor
	if is_instance_valid(mist):
		mist.material.set_shader_parameter("phase", elapsed)
