extends ProgressBar

@export_enum("player", "enemy", "boss") var frame_kind: String = "enemy"

const CHARACTER_FRAME := preload("res://sprites/hud/barra de vida personagem e inimigo.png")
const BOSS_FRAME := preload("res://sprites/hud/barra de vida boss.png")
const FRAME_SHADER := preload("res://shaders/health_frame.gdshader")

var opening: Rect2
var source_size: Vector2

func _ready() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("background", StyleBoxEmpty.new())
	add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	var atlas := AtlasTexture.new()
	match frame_kind:
		"player":
			atlas.atlas = CHARACTER_FRAME
			atlas.region = Rect2(0, 0, 2172, 350)
			opening = Rect2(454, 187, 1236, 69)
		"boss":
			atlas.atlas = BOSS_FRAME
			atlas.region = Rect2(0, 0, 2172, 724)
			opening = Rect2(450, 402, 1270, 82)
		_:
			atlas.atlas = CHARACTER_FRAME
			atlas.region = Rect2(0, 350, 2172, 374)
			opening = Rect2(423, 127, 1319, 73)
	source_size = atlas.region.size
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.texture = atlas
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = FRAME_SHADER
	# Atlas shaders receive UV coordinates relative to the complete source image.
	var source_opening := opening
	source_opening.position += atlas.region.position
	var image_size := Vector2(atlas.atlas.get_size())
	material.set_shader_parameter("opening", Vector4(source_opening.position.x / image_size.x, source_opening.position.y / image_size.y, source_opening.end.x / image_size.x, source_opening.end.y / image_size.y))
	frame.material = material
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_changed.connect(func(_amount: float): queue_redraw())
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if source_size == Vector2.ZERO:
		return
	var amount := get_fill_ratio()
	if amount <= 0.0:
		return
	var factor := size / source_size
	var fill := Rect2(opening.position * factor, opening.size * factor)
	fill.size.x *= amount
	draw_rect(fill, Color("3abf58") if frame_kind == "player" else Color("dc303a"))

func get_fill_ratio() -> float:
	return clampf((value - min_value) / maxf(1.0, max_value - min_value), 0.0, 1.0)
