extends "res://build_character_sprites.gd"

# Reuse the established transparent sprite export and foot alignment pipeline.
func _initialize() -> void:
    source = Image.load_from_file("res://sprites/Personagens/sprite sheet personagem mapa2.png")
    pose_scale = 0.65
    build("enemy_map2", {
        "idle": pose_regions([[433, 6, 133, 149], [591, 10, 127, 145], [739, 10, 129, 144], [890, 10, 133, 145]]),
        "walk": pose_regions([[49, 160, 164, 149], [236, 160, 144, 149], [400, 164, 152, 145], [573, 166, 157, 143], [750, 163, 153, 146], [923, 167, 155, 142], [1102, 158, 145, 152], [1269, 160, 151, 149]]),
        "walk_up": pose_regions([[176, 323, 126, 148], [352, 323, 134, 139], [538, 323, 139, 148], [728, 323, 134, 148], [911, 323, 136, 142], [1099, 324, 134, 147]]),
        "walk_down": pose_regions([[154, 483, 147, 145], [346, 481, 147, 148], [533, 483, 160, 145], [727, 482, 153, 146], [912, 484, 161, 148], [1109, 486, 150, 143]]),
        "attack": pose_regions([[78, 643, 163, 126], [266, 640, 264, 129], [491, 629, 319, 140], [784, 636, 238, 133], [1010, 641, 173, 128], [1213, 629, 152, 140]]),
        "hurt": pose_regions([[326, 781, 171, 141], [551, 789, 152, 133], [754, 783, 150, 140], [965, 792, 134, 130]]),
        "death": pose_regions([[69, 911, 149, 148], [245, 931, 187, 128], [455, 950, 189, 111], [664, 964, 220, 97], [891, 977, 244, 83], [1146, 983, 259, 79]]),
    })
    print("PASS: Rio Negro enemy sheet exported")
    quit()

func pose_regions(boxes: Array) -> Array:
    # The sheet has uneven rows and overlapping pose widths; keep complete bodies.
    var result: Array = []
    for box in boxes:
        result.append(Rect2i(box[0], box[1], box[2], box[3]))
    return result
