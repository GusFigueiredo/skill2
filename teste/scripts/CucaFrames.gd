extends RefCounted

const SHEET := preload("res://sprites/Personagens/sprite sheet cuca.png")
const RITUAL_SHEET := preload("res://sprites/Personagens/cutscene cuca.png")
const FRAME_SIZE := Vector2(360, 184)
const BASELINE_INSET := 8.0
const STANDING_SOURCE_HEIGHT := 203.0
const RITUAL_SOURCE_HEIGHT := 354.0

static var cached_frames: Dictionary = {}
static var cached_ritual_frames: Dictionary = {}
static var cached_skull: Texture2D
static var cached_cauldron: Texture2D

## The source faces left. Every pose keeps its original scale and its feet
## stay on one baseline, including the crouching cast and the fallen poses.
static func build(target_height: float = 125.0) -> SpriteFrames:
	if cached_frames.has(target_height):
		return cached_frames[target_height]
	var frames := _new_frames(target_height, STANDING_SOURCE_HEIGHT)
	var image := SHEET.get_image()
	_add(frames, image, "idle", [
		Rect2i(22, 28, 228, 204),
		Rect2i(287, 30, 233, 202),
		Rect2i(565, 34, 264, 203),
		Rect2i(851, 30, 249, 208),
	], [Vector2(125, 231), Vector2(394, 231), Vector2(674, 236), Vector2(961, 236)], 5.0, true)
	_add(frames, image, "cast", [
		Rect2i(5, 265, 275, 178),
		Rect2i(320, 266, 282, 178),
		Rect2i(678, 261, 307, 189),
		Rect2i(1021, 262, 363, 188),
	], [Vector2(154, 443), Vector2(484, 444), Vector2(886, 449), Vector2(1288, 449)], 5.0, false)
	_add(frames, image, "recover", [
		Rect2i(404, 484, 248, 175),
		Rect2i(775, 490, 229, 169),
	], [Vector2(533, 659), Vector2(904, 659)], 6.0, false)
	_add(frames, image, "hurt", [Rect2i(29, 657, 235, 173)], [Vector2(146, 829)], 6.0, false)
	_add(frames, image, "death", [
		Rect2i(20, 868, 328, 122),
		Rect2i(364, 890, 345, 94),
		Rect2i(709, 896, 318, 90),
	], [Vector2(165, 990), Vector2(510, 983), Vector2(855, 985)], 5.0, false)
	cached_frames[target_height] = frames
	return frames

## The ritual sheet contains Cuca and the cauldron together. Anchoring on
## the cauldron's feet keeps the vessel still as her upper body stirs.
static func ritual_frames(target_height: float = 125.0) -> SpriteFrames:
	if cached_ritual_frames.has(target_height):
		return cached_ritual_frames[target_height]
	var frames := _new_frames(target_height, RITUAL_SOURCE_HEIGHT)
	var image := RITUAL_SHEET.get_image()
	var cells := [
		Rect2i(5, 522, 333, 358),
		Rect2i(355, 530, 314, 350),
		Rect2i(703, 542, 307, 336),
		Rect2i(1045, 550, 327, 335),
	]
	var anchors := [Vector2(120, 879), Vector2(470, 880), Vector2(815, 877), Vector2(1160, 884)]
	_add(frames, image, "mix", cells, anchors, 6.0, true)
	_add(frames, image, "idle", cells, anchors, 6.0, true)
	_add(frames, image, "prepare", [Rect2i(37, 85, 313, 356)], [Vector2(148, 440)], 1.0, true)
	cached_ritual_frames[target_height] = frames
	return frames

## These tight textures retain their native pixels so callers can choose
## projectile and scenery dimensions independently of the actor's height.
static func skull_texture() -> Texture2D:
	if cached_skull == null:
		cached_skull = _crop(SHEET, Rect2i(34, 473, 343, 118))
	return cached_skull

static func cauldron_texture() -> Texture2D:
	if cached_cauldron == null:
		cached_cauldron = _crop(RITUAL_SHEET, Rect2i(561, 123, 214, 305))
	return cached_cauldron

static func grounded_offset(frames: SpriteFrames) -> Vector2:
	var size: Vector2 = frames.get_meta("frame_size", FRAME_SIZE)
	return Vector2(0.0, -size.y * 0.5 + BASELINE_INSET)

static func visual_height(frames: SpriteFrames) -> float:
	return float(frames.get_meta("visual_height", 125.0))

static func source_scale(frames: SpriteFrames) -> float:
	return float(frames.get_meta("source_scale", 125.0 / STANDING_SOURCE_HEIGHT))

static func _new_frames(height: float, reference_height: float) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.set_meta("frame_size", Vector2(maxf(FRAME_SIZE.x, ceilf(height * 2.88)), maxf(FRAME_SIZE.y, ceilf(height * 1.472))))
	frames.set_meta("visual_height", height)
	frames.set_meta("source_scale", height / reference_height)
	frames.set_meta("faces_left", true)
	return frames

static func _add(frames: SpriteFrames, image: Image, animation: StringName, cells: Array, anchors: Array, fps: float, looping: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looping)
	frames.set_meta(String(animation) + "_source_regions", cells)
	var factor := source_scale(frames)
	var frame_size: Vector2 = frames.get_meta("frame_size", FRAME_SIZE)
	for index in cells.size():
		var cell: Rect2i = cells[index]
		var pose := image.get_region(cell)
		var anchor: Vector2 = anchors[index] - Vector2(cell.position)
		pose.resize(maxi(1, roundi(pose.get_width() * factor)), maxi(1, roundi(pose.get_height() * factor)), Image.INTERPOLATE_NEAREST)
		var texture := AtlasTexture.new()
		texture.atlas = ImageTexture.create_from_image(pose)
		texture.region = Rect2(Vector2.ZERO, pose.get_size())
		var padding := frame_size - Vector2(pose.get_size())
		texture.margin = Rect2(Vector2(frame_size.x * 0.5 - roundf(anchor.x * factor), frame_size.y - BASELINE_INSET - roundf(anchor.y * factor)), padding)
		texture.filter_clip = true
		frames.add_frame(animation, texture)

static func _crop(sheet: Texture2D, region: Rect2i) -> Texture2D:
	return ImageTexture.create_from_image(sheet.get_image().get_region(region))
