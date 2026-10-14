extends RefCounted

# Boss-only checks skip the approach; the course checks exercise both real waves.
static func reach_boss(fight: Node) -> void:
    fight.set_process(false)
    fight.set_physics_process(false)
    if not fight.boss_area_entered:
        for index in range(2):
            for enemy in fight.waves[index]:
                if is_instance_valid(enemy):
                    if enemy.spawn_tween != null and enemy.spawn_tween.is_valid():
                        enemy.spawn_tween.custom_step(3.0)
                    enemy.hp = 0
                    fight._set_enemy_active(enemy, false)
            fight.player.position = Vector2(fight.SECOND_STAGE_GATE if index == 0 else fight.BOSS_GATE, 460)
            fight._process(0.0)
    for actor in fight.get_tree().get_nodes_in_group("player") + fight.get_tree().get_nodes_in_group("enemy"):
        actor.set_physics_process(false)

static func prepare_fight(fight: Node) -> void:
    reach_boss(fight)
    if fight.boss_intro_running:
        fight.entrance.finish()
    fight.player.set_physics_process(false)
