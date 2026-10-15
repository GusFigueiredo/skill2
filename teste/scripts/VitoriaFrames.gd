extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite sheet vitoria regia.png")
const FRAME_SIZE := Vector2(300, 270)
const STANDING_SOURCE_HEIGHT := 165.0
const EMERGED_SOURCE_HEIGHT := 136.0

static func build(target_height: float = 190.0) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    var image := SHEET.get_image()
    # Each animation keeps one scale: crouching must lower the head, not enlarge
    # the whole character to the height of a standing pose.
    var standing_scale := target_height / STANDING_SOURCE_HEIGHT
    var emerged_scale := target_height / EMERGED_SOURCE_HEIGHT
    var leaf_scale := target_height / 142.0
    var frame_size := Vector2(maxf(FRAME_SIZE.x, ceilf(target_height * 1.4)), maxf(FRAME_SIZE.y, ceilf(target_height * 1.25)))
    frames.set_meta("visual_height", target_height)
    frames.set_meta("frame_size", frame_size)
    frames.set_meta("leaf_width", float(roundi(target_height)))
    frames.set_meta("leaf_surface_offset", -31.0 * leaf_scale)
    frames.set_meta("standing_offset", Vector2(0.0, -23.0 * emerged_scale))

    _add(frames, image, "plant", [Rect2i(66, 118, 154, 88)], 1.0, true, leaf_scale, frame_size)
    _add(frames, image, "transform", [
        Rect2i(312, 104, 140, 97),
        Rect2i(510, 82, 140, 120),
        Rect2i(724, 86, 148, 132),
        Rect2i(964, 84, 141, 146),
        Rect2i(1226, 56, 144, 169),
    ], 5.5, false, emerged_scale, frame_size)
    _add(frames, image, "idle", [
        Rect2i(86, 236, 137, 173),
        Rect2i(307, 235, 136, 175),
        Rect2i(531, 237, 136, 173),
        Rect2i(735, 244, 138, 174),
        Rect2i(971, 249, 136, 173),
    ], 6.0, true, standing_scale, frame_size)
    _add(frames, image, "dash", [
        Rect2i(62, 442, 157, 142),
        Rect2i(270, 442, 165, 142),
        Rect2i(500, 441, 178, 143),
        Rect2i(710, 451, 192, 143),
        Rect2i(948, 454, 181, 145),
    ], 11.0, false, standing_scale, frame_size)

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
    return Vector2(0.0, -size.y * 0.5)

static func _add(frames: SpriteFrames, image: Image, animation: StringName, regions: Array, fps: float, loop: bool, factor: float, frame_size: Vector2) -> void:
    frames.add_animation(animation)
    frames.set_animation_speed(animation, fps)
    frames.set_animation_loop(animation, loop)
    for cell: Rect2i in regions:
        var used := image.get_region(cell).get_used_rect()
        var pose := image.get_region(Rect2i(cell.position + used.position, used.size))
        _add_pose(frames, animation, pose, factor, frame_size)

static func _add_pose(frames: SpriteFrames, animation: StringName, pose: Image, factor: float, frame_size: Vector2) -> void:
    pose.resize(maxi(1, roundi(pose.get_width() * factor)), maxi(1, roundi(pose.get_height() * factor)), Image.INTERPOLATE_NEAREST)
    var texture := AtlasTexture.new()
    texture.atlas = ImageTexture.create_from_image(pose)
    texture.region = Rect2(Vector2.ZERO, pose.get_size())
    var padding := frame_size - Vector2(pose.get_size())
    texture.margin = Rect2(Vector2(padding.x * 0.5, padding.y), padding)
    texture.filter_clip = true
    frames.add_frame(animation, texture)

static func _bare_leaf(image: Image) -> Image:
    var leaf := image.get_region(Rect2i(72, 151, 142, 51))
    # Reuse the source leaf's green grain in the small area previously covered
    # by the flower. Its rim and all the visible surrounding art stay intact.
    for y in range(21):
        for x in range(42, 99):
            var ellipse := Vector2((x - 70.0) / 66.0, (y - 20.0) / 20.0)
            if ellipse.length_squared() <= 1.0:
                leaf.set_pixel(x, y, image.get_pixel(72 + x, 174 + y % 6))
            else:
                leaf.set_pixel(x, y, Color.TRANSPARENT)
    return leaf

