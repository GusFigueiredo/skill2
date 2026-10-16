extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite sheet vitoria regia.png")
const FRAME_SIZE := Vector2(300, 270)
const STANDING_SOURCE_HEIGHT := 175.0
const EMERGED_SOURCE_HEIGHT := 159.0
const LEAF_SOURCE_WIDTH := 140.0
const BASELINE_INSET := 12.0

static func build(target_height: float = 190.0) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    var image := SHEET.get_image()
    # Each animation keeps one scale: crouching must lower the head, not enlarge
    # the whole character to the height of a standing pose.
    var standing_scale := target_height / STANDING_SOURCE_HEIGHT
    var emerged_scale := target_height / EMERGED_SOURCE_HEIGHT
    var leaf_scale := target_height / LEAF_SOURCE_WIDTH
    var frame_size := Vector2(maxf(FRAME_SIZE.x, ceilf(target_height * 1.4)), maxf(FRAME_SIZE.y, ceilf(target_height * 1.25)))
    frames.set_meta("visual_height", target_height)
    frames.set_meta("frame_size", frame_size)
    frames.set_meta("leaf_width", float(roundi(target_height)))
    frames.set_meta("leaf_surface_offset", -42.0 * leaf_scale)
    frames.set_meta("standing_offset", Vector2(0.0, -42.0 * leaf_scale))
    frames.set_meta("emergence_start_scale", leaf_scale / emerged_scale)

    _add(frames, image, "plant", [Rect2i(71, 118, 140, 99)], [Vector2(140.5, 217)], 1.0, true, leaf_scale, frame_size)
    _add(frames, image, "transform", [
        Rect2i(312, 75, 140, 143),
        Rect2i(515, 61, 140, 161),
        Rect2i(740, 45, 134, 168),
        Rect2i(953, 45, 153, 178),
        Rect2i(1214, 53, 126, 165),
    ], [Vector2(382, 218), Vector2(585, 222), Vector2(807, 213), Vector2(1029, 223), Vector2(1281, 211)], 5.5, false, emerged_scale, frame_size)
    _add(frames, image, "idle", [
        Rect2i(94, 237, 132, 175),
        Rect2i(319, 239, 132, 175),
        Rect2i(506, 240, 119, 176),
        Rect2i(721, 239, 124, 174),
        Rect2i(928, 245, 127, 174),
        Rect2i(1175, 251, 128, 175),
    ], [Vector2(160, 412), Vector2(385, 414), Vector2(570.5, 416), Vector2(781, 413), Vector2(996, 419), Vector2(1246, 426)], 5.5, true, standing_scale, frame_size)

    # The flower becomes the heroine. Her support must therefore be a bare
    # leaf, rather than another copy of the flower appearing beneath her feet.
    frames.add_animation("leaf")
    frames.set_animation_speed("leaf", 1.0)
    frames.set_animation_loop("leaf", true)
    _add_pose(frames, "leaf", _bare_leaf(image), leaf_scale, frame_size)
    return frames

static func visual_height(frames: SpriteFrames) -> float:
    return float(frames.get_meta("visual_height", 190.0))

static func leaf_width(frames: SpriteFrames) -> float:
    return float(frames.get_meta("leaf_width", 190.0))

static func leaf_surface_offset(frames: SpriteFrames) -> float:
    return float(frames.get_meta("leaf_surface_offset", -41.5))

static func standing_offset(frames: SpriteFrames) -> Vector2:
    return frames.get_meta("standing_offset", Vector2(0.0, -32.0))

static func grounded_offset(frames: SpriteFrames) -> Vector2:
    var size: Vector2 = frames.get_meta("frame_size", FRAME_SIZE)
    return Vector2(0.0, -size.y * 0.5 + BASELINE_INSET)

static func emergence_start_scale(frames: SpriteFrames) -> float:
    return float(frames.get_meta("emergence_start_scale", 1.0))

static func _add(frames: SpriteFrames, image: Image, animation: StringName, regions: Array, anchors: Array, fps: float, loop: bool, factor: float, frame_size: Vector2) -> void:
    frames.add_animation(animation)
    frames.set_animation_speed(animation, fps)
    frames.set_animation_loop(animation, loop)
    for index in regions.size():
        var cell: Rect2i = regions[index]
        var used := image.get_region(cell).get_used_rect()
        var pose := image.get_region(Rect2i(cell.position + used.position, used.size))
        var anchor: Vector2 = anchors[index] - Vector2(cell.position + used.position)
        _add_pose(frames, animation, pose, factor, frame_size, anchor)

static func _add_pose(frames: SpriteFrames, animation: StringName, pose: Image, factor: float, frame_size: Vector2, anchor: Vector2 = Vector2.INF) -> void:
    if not anchor.is_finite():
        anchor = Vector2(pose.get_width() * 0.5, pose.get_height())
    pose.resize(maxi(1, roundi(pose.get_width() * factor)), maxi(1, roundi(pose.get_height() * factor)), Image.INTERPOLATE_NEAREST)
    var texture := AtlasTexture.new()
    texture.atlas = ImageTexture.create_from_image(pose)
    texture.region = Rect2(Vector2.ZERO, pose.get_size())
    var padding := frame_size - Vector2(pose.get_size())
    texture.margin = Rect2(Vector2(frame_size.x * 0.5 - roundf(anchor.x * factor), frame_size.y - BASELINE_INSET - roundf(anchor.y * factor)), padding)
    texture.filter_clip = true
    frames.add_frame(animation, texture)

static func _bare_leaf(image: Image) -> Image:
    var leaf := image.get_region(Rect2i(71, 151, 140, 66))
    # Reuse the source leaf's green grain in the small area previously covered
    # by the flower. Its rim and all the visible surrounding art stay intact.
    for y in range(24):
        for x in range(42, 101):
            var ellipse := Vector2((x - 70.0) / 66.0, (y - 23.0) / 20.0)
            if ellipse.length_squared() <= 1.0:
                leaf.set_pixel(x, y, image.get_pixel(71 + x, 177 + y % 6))
            else:
                leaf.set_pixel(x, y, Color.TRANSPARENT)
    return leaf

