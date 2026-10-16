extends SceneTree

var output := ""
var capture_failed := false
var captures: Array[String] = []

func _initialize() -> void:
    call_deferred("preview")

func preview() -> void:
    if not OS.get_environment("APPDATA").contains("cuca-boss"):
        push_error("Use isolated APPDATA containing cuca-boss for boss previews")
        quit(1)
        return
    create_timer(65.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
    output = ProjectSettings.globalize_path("res://.validation/cuca-boss-previews")
    DirAccess.make_dir_recursive_absolute(output)
    change_scene_to_file("res://caverna6.tscn")
    await settle()
    var level = current_scene
    freeze_exploration(level)
    for wave in level.waves:
        for enemy in wave:
            if is_instance_valid(enemy):
                enemy.take_damage(enemy.hp)
    await process_frame
    level.wave_index = 2
    level.player.position = Vector2(4200, 450)
    level.player.get_node("Camera2D").reset_smoothing()
    level.player.get_node("Camera2D").force_update_scroll()
    await process_frame
    level._process(0)
    await create_timer(1.15).timeout
    await capture(level, "entrance")
    for _step in range(400):
        if not level.boss_intro_running:
            break
        await create_timer(0.02).timeout
    freeze_exploration(level)
    level.cuca_fight.set_physics_process(false)
    await capture_combat(level)
    print("PASS: Cuca boss previews rendered at 1280x720; ", captures, "; ", output)
    quit(1 if capture_failed else 0)

func capture_combat(level: Node) -> void:
    var fight = level.cuca_fight
    var hero = level.player
    fight.actor.visual.pause()
    await capture(level, "laboratory")
    fight._set_state(fight.State.CHANNELING)
    fight.actor.play("idle")
    fight.actor.visual.set_frame_and_progress(0, 0)
    fight.actor.visual.pause()
    await capture(level, "channel-shield")
    fight._begin_cast()
    fight.state_timer = 0.4
    fight.actor.visual.set_frame_and_progress(3, 0)
    fight.actor.visual.pause()
    await capture(level, "skull-cast")
    fight._set_state(fight.State.RECOVERY)
    var skull = fight._spawn_skull()
    skull.set_physics_process(false)
    skull._physics_process(0.30)
    await capture(level, "skull-flight")
    hero.position = Vector2(4490, 455)
    hero.facing = 1
    hero.attack_vertical = 0
    skull.position = hero.position + Vector2(65, 0)
    skull.direction = Vector2.LEFT
    skull._physics_process(0)
    await capture(level, "counter-window")
    hero.attack_cooldown_timer = 0
    hero._attack()
    skull._physics_process(0.04)
    await capture(level, "skull-reflected")
    for _step in range(100):
        if not is_instance_valid(skull) or skull.is_queued_for_deletion():
            break
        skull._physics_process(0.02)
    await capture(level, "cauldron-overload")
    fight._clear_attacks()
    await process_frame
    fight._set_state(fight.State.RECOVERY)
    hero.attack_cooldown_timer = 0
    hero.attack_flash_timer = 0
    hero.sprite.play("idle")
    hero.position = Vector2(4510, 450)
    fight.phase = 1
    level.current_boss_hint = "Saia das marcas no chão: veneno!"
    fight._spawn_poison()
    for hazard in fight.hazards:
        hazard.set_physics_process(false)
        hazard._physics_process(0.62)
    await capture(level, "poison-warning")
    hero.position = Vector2(4370, 490)
    for hazard in fight.hazards:
        hazard._physics_process(0.45)
    await capture(level, "poison-active")
    fight._clear_attacks()
    await process_frame
    hero.position = Vector2(4520, 450)
    level.current_boss_hint = "Uma onda vem aí — pule com Espaço!"
    hero.jump_height = 56
    hero.sprite.position = hero.sprite_base_position - Vector2(0, hero.jump_height)
    hero.sprite.play("jump")
    var wave = fight._spawn_wave()
    wave.set_physics_process(false)
    wave._physics_process(wave.warning + 0.01)
    await capture(level, "jumping-cauldron-wave")
    fight._clear_attacks()
    await process_frame
    hero.jump_height = 0
    hero.sprite.position = hero.sprite_base_position
    hero.sprite.play("idle")
    hero.position = Vector2(4530, 480)
    fight.phase = 2
    level.current_boss_hint = "Olhe as marcas: o teto vai cair!"
    fight._spawn_stones()
    for stone in fight.boss_stalactites:
        stone.set_physics_process(false)
        stone._physics_process(0.62)
    await capture(level, "ceiling-warning")
    hero.position = Vector2(4390, 440)
    for stone in fight.boss_stalactites:
        stone._begin_fall()
        stone._physics_process(0.30)
    await capture(level, "ceiling-falling")
    for stone in fight.boss_stalactites:
        stone._physics_process(0.60)
    await capture(level, "ceiling-shattered")
    fight._clear_attacks()
    await process_frame
    fight._set_state(fight.State.RECOVERY)
    hero.position = fight.actor.position - Vector2(60, 0)
    hero.facing = 1
    hero.attack_vertical = 0
    hero.attack_cooldown_timer = 0
    fight.actor.hp = 1
    await physics_frame
    await physics_frame
    hero._attack()
    fight.actor.visual.set_frame_and_progress(2, 0)
    fight.actor.visual.pause()
    await capture(level, "cuca-fallen")
    fight._physics_process(1.2)
    await create_timer(0.45).timeout
    await capture(level, "temporary-ending")

func capture(level: Node, label: String) -> void:
    level._update_hud()
    if is_instance_valid(level.cuca_fight):
        level.cuca_fight.queue_redraw()
    var camera: Camera2D = level.player.get_node("Camera2D")
    camera.reset_smoothing()
    camera.force_update_scroll()
    await settle()
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(output.path_join(label + ".png"))
    if error == OK:
        captures.append(label)
    else:
        capture_failed = true
        push_error("Could not save Cuca boss preview: " + label)

func freeze_exploration(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        var spawn: Tween = actor.get("spawn_tween")
        if spawn != null and spawn.is_valid():
            spawn.custom_step(3)
        actor.set_physics_process(false)
    for hazard in level.stalactites:
        hazard.process_mode = Node.PROCESS_MODE_DISABLED

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
