extends RefCounted

const SHEET := preload("res://sprites/cenario/Fases6/estalactite.png")
const SOURCE_HEIGHT := 294.0
static var cache: Dictionary = {}

## All frames preserve the source scale: breaking the tip never enlarges it.
static func build(height: float = 130.0) -> SpriteFrames:
	if cache.has(height):
		return cache[height]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add(frames, "hanging", [Rect2(0, 100, 240, 440)], 1.0, true)
	_add(frames, "cracking", [Rect2(240, 100, 240, 440), Rect2(480, 100, 240, 440)], 4.0, false)
	_add(frames, "falling", [Rect2(50, 714, 123, 224)], 1.0, true)
	var burst: Array[Rect2] = []
	for column in range(1, 6):
		burst.append(Rect2(column * 240, 620, 240, 360))
	_add(frames, "shatter", burst, 13.0, false)
	frames.set_meta("source_scale", height / SOURCE_HEIGHT)
	frames.set_meta("tip_height", height)
	frames.set_meta("fall_height", 224.0 * height / SOURCE_HEIGHT)
	cache[height] = frames
	return frames

static func ceiling_cap() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(960, 100, 240, 108)
	atlas.filter_clip = true
	return atlas

static func _add(frames: SpriteFrames, animation: StringName, cells: Array, fps: float, looping: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_loop(animation, looping)
	frames.set_animation_speed(animation, fps)
	for cell: Rect2 in cells:
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = cell
		atlas.filter_clip = true
		frames.add_frame(animation, atlas)
