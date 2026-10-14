extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite Sheet Iara cutscene.png")
const FRAME_SIZE := Vector2(400, 260)
const VISIBLE_HEIGHT := 225
const FOOT_PADDING := 1.0

# Complete poses, including the hair, tail and the laughter's blue particles.
const KISS_REGIONS: Array[Rect2i] = [
    Rect2i(72, 16, 138, 204),
    Rect2i(276, 18, 146, 205),
    Rect2i(487, 26, 147, 206),
]
const LAUGH_REGIONS: Array[Rect2i] = [
    Rect2i(75, 235, 142, 220),
    Rect2i(284, 241, 152, 213),
    Rect2i(495, 250, 148, 212),
    Rect2i(720, 250, 152, 213),
    Rect2i(954, 255, 147, 214),
    Rect2i(1212, 257, 146, 218),
]

static func append_to(
    frames: SpriteFrames,
    kiss_seconds: float,
    laugh_seconds: float
) -> void:
    var image := SHEET.get_image()
    _append_animation(frames, image, "intro_kiss", KISS_REGIONS, kiss_seconds)
    _append_animation(frames, image, "intro_laugh", LAUGH_REGIONS, laugh_seconds)

static func _append_animation(
    frames: SpriteFrames,
    image: Image,
    animation_name: StringName,
    regions: Array[Rect2i],
    seconds: float
) -> void:
    if frames.has_animation(animation_name):
        frames.remove_animation(animation_name)
    frames.add_animation(animation_name)
    frames.set_animation_loop(animation_name, false)
    frames.set_animation_speed(animation_name, float(regions.size()) / maxf(seconds, 0.001))

    for region: Rect2i in regions:
        var pose := image.get_region(region)
        var width := maxi(1, roundi(float(region.size.x) * VISIBLE_HEIGHT / region.size.y))
        # This sheet uses smaller, differently offset poses than the combat sheet.
        # Match idle's visible height and foot line inside its existing 400x260 frame.
        pose.resize(width, VISIBLE_HEIGHT, Image.INTERPOLATE_NEAREST)
        var texture := AtlasTexture.new()
        texture.atlas = ImageTexture.create_from_image(pose)
        texture.region = Rect2(Vector2.ZERO, Vector2(width, VISIBLE_HEIGHT))
        var margin_size := FRAME_SIZE - texture.region.size
        texture.margin = Rect2(
            Vector2(margin_size.x * 0.5, margin_size.y - FOOT_PADDING),
            margin_size
        )
        frames.add_frame(animation_name, texture)
