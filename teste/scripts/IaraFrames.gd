extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite Sheet da Sereia Encantadora.png")
const FRAME_SIZE := Vector2(400, 260)

static func build() -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")

    var idle := [
        Rect2(30, 0, 240, 227),
        Rect2(300, 0, 260, 227),
        Rect2(570, 0, 270, 227),
        Rect2(890, 0, 290, 227),
    ]
    # The revised sheet spreads five complete poses across the entire second row.
    var attack := cells([0, 280, 570, 870, 1170, 1448], 227, 478)
    var preparation := [
        Rect2(30, 478, 280, 242),
        Rect2(350, 478, 325, 242),
        Rect2(690, 478, 300, 242),
    ]
    var attack_loop: Array[Rect2] = [attack[3], attack[4]]
    var animations := {
        "idle": {"regions": idle, "speed": 6.0, "loop": true},
        "attack": {"regions": attack, "speed": 14.0, "loop": false},
        "attack_loop": {"regions": attack_loop, "speed": 6.0, "loop": true},
        "preparation": {"regions": [preparation[0], preparation[1]], "speed": 6.0, "loop": true},
        "preparation_finish": {"regions": [preparation[2]], "speed": 6.0, "loop": false},
        "fall": {
            "regions": [
                Rect2(60, 720, 270, 214),
                Rect2(350, 720, 250, 214),
                Rect2(620, 720, 350, 214),
                Rect2(990, 720, 380, 214),
            ],
            "speed": 7.0,
            "loop": false,
        },
        "death": {
            "regions": [
                Rect2(60, 934, 340, 152),
                Rect2(400, 934, 350, 152),
                Rect2(750, 934, 370, 152),
            ],
            "speed": 6.0,
            "loop": false,
        },
    }

    for animation_name: String in animations:
        var animation: Dictionary = animations[animation_name]
        _add_animation(
            frames,
            animation_name,
            animation["regions"],
            animation["speed"],
            animation["loop"]
        )
    return frames

static func preparation_heart() -> AtlasTexture:
    var texture := AtlasTexture.new()
    texture.atlas = SHEET
    texture.region = Rect2(1170, 540, 65, 70)
    return texture

static func _add_animation(
    frames: SpriteFrames,
    animation_name: StringName,
    regions: Array,
    speed: float,
    loop: bool
) -> void:
    frames.add_animation(animation_name)
    frames.set_animation_speed(animation_name, speed)
    frames.set_animation_loop(animation_name, loop)
    for region: Rect2 in regions:
        var texture := AtlasTexture.new()
        texture.atlas = SHEET
        texture.region = region
        var margin_size := FRAME_SIZE - region.size
        texture.margin = Rect2(
            Vector2(margin_size.x * 0.5, margin_size.y),
            margin_size
        )
        frames.add_frame(animation_name, texture)

static func cells(edges: Array, top: float, bottom: float) -> Array[Rect2]:
    var result: Array[Rect2] = []
    for index in edges.size() - 1:
        result.append(Rect2(edges[index], top, edges[index + 1] - edges[index], bottom - top))
    return result
