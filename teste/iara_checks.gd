extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    create_timer(35.0, true).timeout.connect(func():
        push_error("Iara checks timed out")
        quit(1)
    )
    for index in range(3):
        Progress.complete_stage(index)
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    freeze_fight(fight)
    check(fight.state == fight.State.IDLE and fight.boss.get_node("Sprite").animation == "idle", "Battle must start with idle Iara")
    check(not fight.key_prompt.visible, "Key prompts stay hidden before hypnosis")
    fight._physics_process(0.5)
    check(fight.state == fight.State.IDLE, "Opening idle must remain legible")
    fight._physics_process(fight.state_timer + 0.01)
    fight.boss.get_node("Sprite")._process(0)
    var iara_sprite: AnimatedSprite2D = fight.boss.get_node("Sprite")
    check(fight.state == fight.State.PREPARING and iara_sprite.animation == "preparation", "Preparation must use the preparation row")
    var boitata = load("res://ratanaba2.tscn").instantiate()
    check(fight.boss.max_hp == boitata.get_node("Boss").max_hp, "Iara and Boitata must have equal health")
    check(fight.player.attack_damage == boitata.get_node("Player").attack_damage, "Player damage must stay equal")
    boitata.free()
    check(fight.boss.hp == 6, "Iara starts with six HP")
    check(fight.player.get_node("Camera2D").zoom == Vector2(1.8, 1.8), "Iara fight must use normal gameplay zoom")
    check(not fight.player.get_node("Camera2D").top_level, "Camera must follow the hero normally")
    check(fight.player.sprite.scale == Vector2(0.9375, 0.9375), "Hero keeps the normal gameplay scale")
    check(fight.get_node("Ground").texture.resource_path.ends_with("chao boss fight Iara.png"), "Boss ground must use the supplied art")
    check(fight.get_node("HUD/BossHealth/BossName").text == "IARA", "HUD must name Iara")
    check(fight.get_node("HUD/BossHealth").visible, "Boss health must be visible")
    check(fight.player.position.x < fight.WATER_EDGE and fight.boss.position.x > fight.WATER_EDGE, "Start on dry bank, boss in water")
    var iara_frames: SpriteFrames = iara_sprite.sprite_frames
    for animation_name in ["idle", "attack", "attack_loop", "preparation", "preparation_finish", "fall", "death"]:
        check(fight.boss.get_node("Sprite").sprite_frames.has_animation(animation_name), "Missing Iara animation: " + animation_name)
    check(iara_frames.get_frame_count("idle") == 4 and iara_frames.get_animation_loop("idle"), "Idle must loop all four frames")
    check(iara_frames.get_frame_count("attack") == 5 and not iara_frames.get_animation_loop("attack"), "Attack must play its five frames once")
    check(iara_frames.get_frame_count("attack_loop") == 2 and iara_frames.get_animation_loop("attack_loop"), "Attack loop must alternate its last two frames")
    var attack_edges := [0, 280, 570, 870, 1170, 1448]
    for index in range(5):
        var attack_texture := iara_frames.get_frame_texture("attack", index) as AtlasTexture
        check(attack_texture.region == Rect2(attack_edges[index], 227, attack_edges[index + 1] - attack_edges[index], 251), "Attack must crop each complete pose in the revised sheet")
    var heart := preload("res://scripts/IaraFrames.gd").preparation_heart()
    check(heart.atlas == preload("res://scripts/IaraFrames.gd").SHEET and heart.region == Rect2(1170, 540, 65, 70), "Preparation hearts must use the supplied particle after row three")
    check(iara_frames.get_frame_count("preparation") == 2 and iara_frames.get_animation_loop("preparation"), "Preparation must alternate its first two frames")
    check(iara_frames.get_frame_count("preparation_finish") == 1, "Preparation must finish on its third frame")
    var prep_first := iara_frames.get_frame_texture("preparation", 0) as AtlasTexture
    var prep_second := iara_frames.get_frame_texture("preparation", 1) as AtlasTexture
    var prep_finish := iara_frames.get_frame_texture("preparation_finish", 0) as AtlasTexture
    check(prep_first.region.position.x == 30 and prep_second.region.position.x == 350 and prep_finish.region.position.x == 690, "Preparation must use the first two sheet frames before its third")
    check(iara_frames.get_frame_count("fall") == 4 and iara_frames.get_frame_count("death") == 3, "Fall and defeat must use their own rows")
    check(
        float(iara_frames.get_frame_count("attack")) / iara_frames.get_animation_speed("attack") + 0.1 <= fight.CAST_SECONDS,
        "All attack frames must finish before the spell arrives"
    )
    check(not fight.has_node("HUD/IaraInstructions") and not fight.resistance_bar.visible, "The top-right instructions must be removed while the resistance meter stays hidden until trance")
    var source_rows := {
        "idle": 0.0,
        "attack": 227.0,
        "attack_loop": 227.0,
        "preparation": 478.0,
        "preparation_finish": 478.0,
        "fall": 720.0,
        "death": 934.0,
    }
    for animation_name: String in source_rows:
        for index in iara_frames.get_frame_count(animation_name):
            var atlas := iara_frames.get_frame_texture(animation_name, index) as AtlasTexture
            check(is_equal_approx(atlas.region.position.y, source_rows[animation_name]), "Animation must use its assigned sprite-sheet row: " + animation_name)
    var loop_source_frames := [3, 4]
    for index in loop_source_frames.size():
        var loop_frame := iara_frames.get_frame_texture("attack_loop", index) as AtlasTexture
        var source_frame := iara_frames.get_frame_texture("attack", loop_source_frames[index]) as AtlasTexture
        check(loop_frame.region == source_frame.region, "Attack loop order must be 4-5")

    fight.boss.take_damage(1)
    check(fight.boss.hp == 6, "Iara must ignore damage outside her attack window")
    fight._physics_process(2.4)
    check(fight.state == fight.State.PREPARING, "Song must be telegraphed before the trance")
    iara_sprite._process(0.0)
    check(iara_sprite.animation == "preparation_finish", "Preparation must end on its third frame")
    fight._physics_process(0.11)
    check(fight.state == fight.State.CASTING, "Preparation must visibly launch the spell before hypnosis")
    iara_sprite._process(0.0)
    check(iara_sprite.animation == "idle" and iara_sprite.frame == 0 and not iara_sprite.is_playing(), "The first idle frame must appear between preparation and attack")
    iara_sprite._process(0.11)
    check(iara_sprite.animation == "attack", "Launching the spell must play the full attack sequence")
    check(not is_instance_valid(fight.player.seduction_source), "Hypnosis cannot begin before the spell arrives")
    fight._physics_process(0.3)
    check(fight.state == fight.State.CASTING, "Spell travel must be visible")
    fight._physics_process(0.26)
    check(fight.state == fight.State.SEDUCING, "Arriving spell must start seduction")
    iara_sprite._process(0.0)
    check(iara_sprite.animation == "attack", "Hypnosis must not interrupt the full attack sequence")
    iara_sprite.set_frame_and_progress(4, 0.0)
    iara_sprite.pause()
    iara_sprite._process(0.0)
    check(iara_sprite.animation == "attack_loop", "After the attack sequence, Iara must loop its last two frames")
    check(fight.player.seduction_source == fight.boss, "Trance must attach to Iara")
    check(fight.low_pass.cutoff_hz < 1000, "Trance must muffle the music")
    fight.camera_tween.custom_step(0.4)
    check(fight.player.get_node("Camera2D").zoom.x > 2.4 and fight.camera_is_focused, "Trance must zoom toward the hero")
    fight.key_prompt._process(0.04)
    check(fight.key_prompt.visible, "Trance must show sprites above the hero")
    check(fight.key_prompt.keys[0].rotation != 0 and fight.key_prompt.keys[1].rotation == 0, "Only the expected A key shakes first")
    var pursuer = fight.trance_enemy
    check(is_instance_valid(pursuer) and pursuer.speed == 30, "Trance must spawn a slow pursuer")
    pursuer.spawn_tween.custom_step(2)
    pursuer.set_physics_process(false)
    # Give the movement check room: the new spawn can already touch the hero.
    pursuer.position -= Vector2(80, 0)
    var pursuer_start: Vector2 = pursuer.position
    pursuer._physics_process(0.1)
    check(pursuer.velocity.length() <= 30.01 and pursuer.position.distance_to(fight.player.position) < pursuer_start.distance_to(fight.player.position), "Pursuer slowly closes the distance")
    pursuer.position = fight.player.position
    pursuer._update_contact_damage()
    check(fight.player.hp == 9, "Pursuer must hurt the charmed hero on contact")
    fight.player.hp = 10
    fight.player.damage_cooldown = 0
    pursuer.position = pursuer_start
    var hero = fight.player
    hero.attack_cooldown_timer = 0
    hero._attack()
    hero._start_dodge(1)
    check(hero.attack_cooldown_timer == 0 and not hero.is_dodging, "Trance blocks attacks and rolling")
    var start_x: float = hero.position.x
    hero._physics_process(0.05)
    check(hero.position.x > start_x, "Trance must pull the hero toward Iara")
    Input.action_press("ui_left")
    hero._physics_process(0.02)
    hero._physics_process(0.02)
    fight.key_prompt._process(0.04)
    check(fight.key_prompt.keys[0].texture == fight.key_prompt.pressed_textures[0], "Holding A must show the supplied pressed A sprite")
    check(fight.key_prompt.keys[0].rotation == 0 and fight.key_prompt.keys[1].rotation != 0, "After A, only the expected D key shakes")
    Input.action_release("ui_left")
    check(fight.resistance == 1.0, "Holding a direction must count once")
    fight.register_resistance(1)
    check(fight.resistance == 1.0, "Opposite input before 0.2 seconds must be ignored")
    fight._physics_process(0.19)
    fight.register_resistance(1)
    check(fight.resistance == 1.0, "Cooldown must still block at 0.19 seconds")
    fight._physics_process(0.01)
    Input.action_press("ui_right")
    hero._physics_process(0.01)
    fight.key_prompt._process(0)
    check(fight.key_prompt.keys[1].texture == fight.key_prompt.pressed_textures[1], "Holding D must show the supplied pressed D sprite")
    Input.action_release("ui_right")
    check(fight.resistance == 2.0, "Next opposite action is accepted at 0.2 seconds")
    fight.register_resistance(1)
    check(fight.resistance == 2.0, "Repeated same-direction presses cannot break the charm")
    fight._physics_process(1.3)
    check(fight.resistance < 2.0, "Resistance decays when input stops")
    break_charm(fight)
    check(fight.state == fight.State.FALLING, "Alternating directions must knock Iara down")
    check(not is_instance_valid(hero.seduction_source), "Breaking charm restores player control")
    fight.camera_tween.custom_step(0.3)
    check(not fight.key_prompt.visible and hero.get_node("Camera2D").zoom == Vector2(1.8, 1.8), "Charm break must hide prompts and restore zoom")
    check(not hero.get_node("Camera2D").top_level, "Normal camera following must return")
    check(fight.low_pass.cutoff_hz > 10000 and is_equal_approx(fight.music.pitch_scale, 1), "Breaking charm restores audio")
    fight._physics_process(0.76)
    check(fight.state == fight.State.MINIONS and fight.minions.size() == 3, "First cycle must keep the pursuer and summon two guards")
    for minion in fight.minions:
        if minion.spawn_tween.is_valid():
            minion.spawn_tween.custom_step(2)
        minion.set_physics_process(false)
        check(minion.visible and minion.hp > 0, "Minions must enter alive and visible")
    fight.boss.take_damage(1)
    check(fight.boss.hp == 6, "Living minions protect Iara")
    fight.minions[0].take_damage(100)
    fight._physics_process(0.01)
    check(fight.state == fight.State.MINIONS, "One remaining minion must keep the window closed")
    for index in range(1, fight.minions.size()):
        fight.minions[index].take_damage(100)
    fight._physics_process(0.01)
    check(fight.state == fight.State.VULNERABLE and is_equal_approx(fight.state_timer, 2), "Killing all minions opens a two-second window")

    # Use the real player attack query, verifying the downed boss remains hittable.
    hero.position = fight.boss.position - Vector2(100, 0)
    hero.facing = 1
    hero.attack_vertical = 0
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.boss.hp == 5, "A normal player strike must deal exactly one damage to Iara")
    check(fight.boss.get_node("Sprite").animation == "fall", "Iara remains down during the attack window")
    var body_bounds: Rect2 = fight.boss.combat_bounds
    var face: Vector2 = fight.boss.position + body_bounds.position + Vector2(24, 20)
    hero.position = face - Vector2(80, hero.combat_bounds.get_center().y)
    hero.attack_cooldown_timer = 0
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.boss.hp == 4, "Real strike against fallen Iara's face must register")
    var tail: Vector2 = fight.boss.position + Vector2(body_bounds.end.x - 20, body_bounds.get_center().y)
    hero.position = tail + Vector2(80, -hero.combat_bounds.get_center().y)
    hero.facing = -1
    hero.attack_cooldown_timer = 0
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.boss.hp == 3, "Real strike against fallen Iara's tail must register")
    fight._physics_process(2.01)
    check(fight.state == fight.State.PREPARING, "Expired window must restart the song")
    fight.boss.take_damage(1)
    check(fight.boss.hp == 3, "Window expiry restores protection")

    # At half health the next real cycle adds a third minion.
    fight.boss.hp = 3
    fight._begin_seduction()
    fight.trance_enemy.spawn_tween.custom_step(2)
    fight.trance_enemy.set_physics_process(false)
    hero.position = Vector2(260, 460)
    break_charm(fight)
    fight._physics_process(0.76)
    check(fight.minions.size() == 4, "Half-health cycle must keep the pursuer and summon three guards")
    for minion in fight.minions:
        if minion.spawn_tween.is_valid():
            minion.spawn_tween.custom_step(2)
        minion.set_physics_process(false)
        minion.take_damage(100)
    fight._physics_process(0.01)
    check(fight.state == fight.State.VULNERABLE, "Third minion must also gate the window")
    fight.boss.hp = 1
    fight.boss.take_damage(hero.attack_damage)
    check(fight.finished and fight.state == fight.State.DEFEATED, "The last normal hit must defeat Iara without rescue")
    check(Progress.completed_stages() == 4, "Defeat must save completion of phase four")
    var transition = root.get_node("SceneTransition")
    check(transition.phase == "waiting_for_defeat", "Stage exit must wait for Iara's death animation")
    while transition.busy:
        await process_frame
    check(current_scene.scene_file_path == "res://level_map.tscn", "Victory must return to the map")
    check(not current_scene.stage_buttons[3].disabled and current_scene.stage_buttons[4].disabled, "Iara can be replayed, Cuca remains locked")

    # Water keeps HP until a single three-second timer kills; retreat resets it.
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    fight = current_scene
    freeze_fight(fight)
    hero = fight.player
    hero.position.x = fight.WATER_EDGE + 10
    fight._update_water(0.1)
    check(hero.hp == 10 and fight.water_exposure > 0, "Water contact must not deal gradual damage")
    check(hero.sprite.material == fight.submersion_material, "Water exposure must progressively conceal the submerged body")
    var first_surface: float = fight.water_surface.y
    fight._update_water(1.0)
    check(fight.water_surface.y < first_surface, "The water must cover more of the hero as exposure increases")
    hero.position.x = 400
    fight._update_water(1)
    check(fight.water_exposure == 0, "Retreat to the bank must reset exposure")
    check(hero.sprite.material == fight.normal_player_material, "Retreat must restore the original player material")
    check(hero.shadow_opacity == 1.0, "Retreat must restore the hero's shadow")
    fight._begin_seduction()
    paused = true
    var timer: float = fight.state_timer
    await create_timer(0.1, true).timeout
    check(fight.state_timer == timer, "Pause must freeze seduction")
    paused = false
    fight._physics_process(fight.TRANSE_SECONDS + 0.1)
    check(fight.state == fight.State.DROWNING and hero.hp > 0, "Failure must start slow drowning, not instant death")
    check(hero.control_locked and not hero.is_physics_processing(), "Fatal drowning disables hero actions")
    fight._physics_process(1.5)
    check(hero.sprite.scale == Vector2(0.9375, 0.9375), "Drowning must preserve the hero's proportions")
    check(hero.sprite.position.y > hero.sprite_base_position.y, "Fatal drowning must progressively sink the hero")
    check(fight.veil.color.a > 0.18 and fight.low_pass.cutoff_hz < 850.0, "Drowning must gradually darken and muffle the river")
    fight._physics_process(1.4)
    check(hero.hp > 0 and not fight.death_screen.visible, "Hero survives until the end of three-second drowning")
    fight._physics_process(0.11)
    check(hero.hp == 0 and fight.death_screen.visible and hero.sprite.animation == "death", "Drowning must show normal death at three seconds")
    var dead_position: Vector2 = hero.sprite.position
    var dead_alpha: float = hero.sprite.modulate.a
    var dead_surface: Vector2 = fight.water_surface
    fight._process(fight.CORPSE_SINK_SECONDS * 0.5)
    check(hero.sprite.position.y > dead_position.y and hero.sprite.modulate.a < dead_alpha, "The dead body must continue descending and fading")
    check(hero.sprite.modulate.a > 0.0 and fight.water_surface == dead_surface, "Corpse fading must be gradual while the water surface stays fixed")
    paused = true
    var corpse_time: float = fight.corpse_elapsed
    await create_timer(0.1, true).timeout
    check(fight.corpse_elapsed == corpse_time, "Pause must freeze the sinking corpse")
    paused = false
    fight._process(fight.CORPSE_SINK_SECONDS)
    check(is_zero_approx(hero.sprite.modulate.a) and hero.hp == 0, "The drowned body must disappear completely without changing death state")
    check(is_zero_approx(hero.shadow_opacity), "The submerged body's shadow must disappear too")
    fight._reset_scene()
    while transition.busy:
        await process_frame
    check(current_scene.scene_file_path == "res://rio_negro4.tscn", "Restart must reload the Iara fight")
    check(current_scene.boss.hp == 6 and not current_scene.player.control_locked, "Restart must reset boss and player control")
    check(current_scene.corpse_elapsed < 0.0 and current_scene.player.sprite.modulate == Color.WHITE, "Restart must restore full visibility and clear corpse sinking")
    fight = current_scene
    freeze_fight(fight)
    hero = fight.player
    hero.position.x = fight.WATER_EDGE + 10
    fight._update_water(2.99)
    check(hero.hp == 10 and not fight.death_screen.visible, "Water must preserve HP at 2.99 seconds")
    hero._start_dodge(1)
    fight._update_water(0.01)
    check(hero.hp == 0 and fight.death_screen.visible, "Water kills at three seconds, even during a roll, with no extra cinematic delay")
    check(hero.sprite.scale == Vector2(0.9375, 0.9375) and hero.visible, "Water death preserves normal actor scale and visibility")
    var water_death_position: Vector2 = hero.sprite.position
    fight._process(0.5)
    check(hero.sprite.position.y > water_death_position.y and hero.sprite.modulate.a < 1.0, "Death from water exposure must also sink and fade the corpse")
    if failures == 0:
        print("PASS: idle/attack/cast sequence, alternating animated A/D sprites, held-key feedback, hypnosis zoom/restore, cooldown, pursuer, hitboxes, drowning, victory and restart")
    quit(0 if failures == 0 else 1)

func freeze_fight(fight: Node) -> void:
    fight.set_process(false)
    fight.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)

func break_charm(fight: Node) -> void:
    while fight.state == fight.State.SEDUCING:
        fight.register_resistance(-1 if fight.last_resistance_direction >= 0 else 1)
        if fight.state == fight.State.SEDUCING:
            fight._physics_process(fight.RESISTANCE_COOLDOWN)
