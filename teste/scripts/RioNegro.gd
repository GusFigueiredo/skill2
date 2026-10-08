extends "res://scripts/Level1.gd"

# Shared controls, combat, scenery extension and stage exit come from Level1.
func _setup_encounters() -> void:
    pits = []
    if stage_index == 2:
        arena_bounds = Rect2(40, 340, 2260, 220)
        $Enemy1.position = Vector2(620, 420)
        $Enemy2.position = Vector2(1100, 500)
        $Enemy3.position = Vector2(1660, 450)
        waves = [[$Enemy1, $Enemy2, $Enemy3]]
        player.get_node("Camera2D").limit_right = 2300
    else:
        arena_bounds = Rect2(40, 340, 2960, 220)
        $Enemy1.position = Vector2(650, 490)
        $Enemy2.position = Vector2(1180, 390)
        $Enemy3.position = Vector2(1880, 510)
        $Enemy4.position = Vector2(2560, 430)
        waves = [[$Enemy1, $Enemy2, $Enemy3, $Enemy4]]
        player.get_node("Camera2D").limit_right = 3000
