extends RefCounted

# Each painting has a different amount of empty space. These anchors follow
# the rigid torch holder, keeping it planted while only the flame changes.
const SHEET := preload("res://sprites/cenario/Fases6/tocha.png")
const HOLDER_ANCHORS := [158.0, 430.0, 700.0, 975.0, 1253.0, 1520.0]
const FRAME_SIZE := Vector2(256.0, 650.0)
const GROUNDED_OFFSET := Vector2(-128.0, -644.0)

static func build() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("burn")
	frames.set_animation_loop("burn", true)
	frames.set_animation_speed("burn", 9.0)
	# Reverse through the intermediate drawings for a softer looping flame.
	for frame_index in [0, 1, 2, 3, 4, 5, 4, 3, 2, 1]:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(Vector2(HOLDER_ANCHORS[frame_index] - 128.0, 100.0), FRAME_SIZE)
		frame.filter_clip = true
		frames.add_frame("burn", frame)
	return frames
