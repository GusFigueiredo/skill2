extends RefCounted

const SHEET := preload("res://sprites/Personagens/sprite sheet onça.png")
const FRAME_SIZE := Vector2(260, 164)
const REFERENCE_SOURCE_WIDTH := 194.0
static var cached_frames: Dictionary = {}

# Every pose uses the same scale. The crouching, jumping and fallen jaguar
# therefore keep their proportions instead of growing to fill each cell.
static func build(target_width: float = 142.0) -> SpriteFrames:
    if cached_frames.has(target_width):
        return cached_frames[target_width]
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    var image := SHEET.get_image()
    var factor := target_width / REFERENCE_SOURCE_WIDTH
    var frame_size := Vector2(maxf(FRAME_SIZE.x, ceilf(target_width * 1.8)), maxf(FRAME_SIZE.y, ceilf(target_width * 1.15)))
    frames.set_meta("frame_size", frame_size)
    frames.set_meta("visual_width", target_width)
    frames.set_meta("source_scale", factor)

    var clean_bushes := [
        Rect2i(0, 0, 162, 160),
        Rect2i(162, 0, 148, 160),
        Rect2i(310, 0, 146, 160),
        Rect2i(456, 0, 141, 160),
    ]
    var reveal_bushes := [
        Rect2i(597, 0, 141, 160),
        Rect2i(738, 0, 154, 160),
        Rect2i(892, 0, 158, 160),
    ]
    var emergence := [
        Rect2i(0, 160, 235, 145),
        Rect2i(235, 160, 295, 145),
        Rect2i(530, 160, 300, 145),
        Rect2i(830, 160, 300, 145),
        Rect2i(1130, 160, 318, 145),
    ]
    var movement := [
        Rect2i(0, 305, 238, 142),
        Rect2i(238, 305, 282, 142),
        Rect2i(520, 305, 240, 142),
    ]
    _add(frames, image, "bush_idle", [clean_bushes[0]], 1.0, true, factor, frame_size)
    _add(frames, image, "bush_rustle", clean_bushes, 11.0, false, factor, frame_size)
    _add(frames, image, "bush_reveal", reveal_bushes, 8.0, false, factor, frame_size)
    _add(frames, image, "emerge", emergence, 10.0, false, factor, frame_size)
    _add(frames, image, "leap", [emergence[3], emergence[4]], 9.0, false, factor, frame_size)
    _add(frames, image, "idle", movement, 3.5, true, factor, frame_size)
    _add(frames, image, "run", movement, 10.0, true, factor, frame_size)
    _add(frames, image, "paw", [
        Rect2i(0, 447, 215, 193),
        Rect2i(215, 447, 245, 193),
        Rect2i(460, 447, 250, 193),
    ], 10.0, false, factor, frame_size)
    _add(frames, image, "bite", [
        Rect2i(0, 640, 170, 155),
        Rect2i(170, 640, 170, 155),
        Rect2i(340, 640, 180, 155),
        Rect2i(520, 640, 200, 155),
    ], 11.0, false, factor, frame_size)
    _add(frames, image, "death", [
        Rect2i(0, 795, 180, 123),
        Rect2i(180, 795, 180, 123),
        Rect2i(360, 795, 190, 123),
        Rect2i(550, 795, 180, 123),
    ], 7.0, false, factor, frame_size)
    # This source pose already contains the protagonist holding the neck.
    # Its motion is supplied by the grapple controller, without doubling him.
    _add(frames, image, "struggle", [Rect2i(0, 918, 230, 168)], 1.0, true, factor, frame_size)
    _add(frames, image, "hurt", [movement[0]], 1.0, false, factor, frame_size)
    # Actors select animations on their own AnimatedSprite2D. The immutable
    # frame resource and its resized images can be shared by all five bushes,
    # both enemies and the grapple composition.
    cached_frames[target_width] = frames
    return frames

static func grounded_offset(frames: SpriteFrames) -> Vector2:
    var frame_size: Vector2 = frames.get_meta("frame_size", FRAME_SIZE)
    return Vector2(0.0, -frame_size.y * 0.5)

static func visual_width(frames: SpriteFrames) -> float:
    return float(frames.get_meta("visual_width", 142.0))

static func source_scale(frames: SpriteFrames) -> float:
    return float(frames.get_meta("source_scale", 142.0 / REFERENCE_SOURCE_WIDTH))

static func _add(frames: SpriteFrames, image: Image, animation: StringName, regions: Array, fps: float, loop: bool, factor: float, frame_size: Vector2) -> void:
    frames.add_animation(animation)
    frames.set_animation_speed(animation, fps)
    frames.set_animation_loop(animation, loop)
    frames.set_meta(String(animation) + "_source_regions", regions)
    for cell: Rect2i in regions:
        var used := image.get_region(cell).get_used_rect()
        var pose := image.get_region(Rect2i(cell.position + used.position, used.size))
        pose.resize(maxi(1, roundi(pose.get_width() * factor)), maxi(1, roundi(pose.get_height() * factor)), Image.INTERPOLATE_NEAREST)
        var texture := AtlasTexture.new()
        texture.atlas = ImageTexture.create_from_image(pose)
        texture.region = Rect2(Vector2.ZERO, pose.get_size())
        var padding := frame_size - Vector2(pose.get_size())
        texture.margin = Rect2(Vector2(padding.x * 0.5, padding.y), padding)
        texture.filter_clip = true
        frames.add_frame(animation, texture)
