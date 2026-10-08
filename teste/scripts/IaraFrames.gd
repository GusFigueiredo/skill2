extends RefCounted

const SHEET := preload("res://sprites/Personagens/Sprite Sheet da Sereia Encantadora.png")

# The supplied sheet has irregular cells. Atlas margins align every pose at the feet.
static func build() -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    var animations := {
        "idle": cells([150, 335, 530, 708, 920], 0, 226),
        "wave": cells([0, 245, 480, 708, 928, 1160, 1448], 226, 435),
        "sing": cells([28, 250, 478, 710, 930, 1160, 1448], 435, 638),
        "seduction": cells([28, 250, 478, 710, 930, 1160, 1448], 435, 638),
        "fall": [Rect2(85, 644, 203, 184), Rect2(288, 647, 247, 181), Rect2(535, 645, 215, 183), Rect2(750, 688, 310, 140), Rect2(1060, 704, 350, 124)],
        "hurt": cells([296, 535, 738, 997], 828, 978),
        "death": [Rect2(0, 928, 264, 158), Rect2(264, 982, 316, 104), Rect2(580, 994, 288, 92), Rect2(868, 1000, 262, 86), Rect2(1130, 1001, 318, 85)],
    }
    for animation_name in animations:
        frames.add_animation(animation_name)
        frames.set_animation_speed(animation_name, 7.0 if animation_name == "fall" else 6.0)
        frames.set_animation_loop(animation_name, animation_name in ["idle", "wave", "sing"])
        for region: Rect2 in animations[animation_name]:
            var texture := AtlasTexture.new()
            texture.atlas = SHEET
            texture.region = region
            texture.margin = Rect2(Vector2((340.0 - region.size.x) * 0.5, 240.0 - region.size.y), Vector2(340, 240) - region.size)
            frames.add_frame(animation_name, texture)
    return frames

static func cells(edges: Array, top: float, bottom: float) -> Array[Rect2]:
    var result: Array[Rect2] = []
    for index in edges.size() - 1:
        result.append(Rect2(edges[index], top, edges[index + 1] - edges[index], bottom - top))
    return result
