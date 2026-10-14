extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite sheet vitoria regia.png")
const FRAME_SIZE := Vector2(300, 270)

static func build(target_height: float = 190.0) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    _add(frames, "plant", [Rect2i(50, 80, 200, 140)], 1.0, true, target_height)
    var transformation: Array[Rect2i] = []
    var transformation_edges := [280, 480, 710, 940, 1170, 1448]
    for index in range(5):
        transformation.append(Rect2i(transformation_edges[index], 40, transformation_edges[index + 1] - transformation_edges[index], 190))
    _add(frames, "transform", transformation, 5.0, false, target_height)
    var idle: Array[Rect2i] = []
    for index in range(5):
        idle.append(Rect2i(50 + index * 225, 230, 220, 200))
    _add(frames, "idle", idle, 5.0, true, target_height)
    var dash: Array[Rect2i] = []
    var edges := [50, 270, 490, 710, 940, 1160]
    for index in range(5):
        dash.append(Rect2i(edges[index], 430, edges[index + 1] - edges[index], 180))
    _add(frames, "dash", dash, 10.0, false, target_height)
    return frames

static func _add(frames: SpriteFrames, animation: StringName, regions: Array, fps: float, loop: bool, target_height: float) -> void:
    frames.add_animation(animation)
    frames.set_animation_speed(animation, fps)
    frames.set_animation_loop(animation, loop)
    var image := SHEET.get_image()
    for cell: Rect2i in regions:
        var used := image.get_region(cell).get_used_rect()
        var pose := image.get_region(Rect2i(cell.position + used.position, used.size))
        var factor := target_height / maxf(1.0, used.size.y)
        if animation == "plant":
            factor = target_height * 1.8 / maxf(1.0, used.size.x)
        elif animation == "transform":
            factor = target_height / 130.0
        pose.resize(maxi(1, roundi(used.size.x * factor)), maxi(1, roundi(used.size.y * factor)), Image.INTERPOLATE_NEAREST)
        var texture := AtlasTexture.new()
        texture.atlas = ImageTexture.create_from_image(pose)
        texture.region = Rect2(Vector2.ZERO, pose.get_size())
        var padding := FRAME_SIZE - Vector2(pose.get_size())
        texture.margin = Rect2(Vector2(padding.x * 0.5, padding.y), padding)
        texture.filter_clip = true
        frames.add_frame(animation, texture)

