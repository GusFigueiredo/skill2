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
    check(fight.state == fight.State.PREPARING and fight.boss.get_node("Sprite").animation == "seduction", "Preparation must use the seduction attack sprite")
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
    for animation_name in ["idle", "sing", "wave", "fall", "death"]:
        check(fight.boss.get_node("Sprite").sprite_frames.has_animation(animation_name), "Missing Iara animation: " + animation_name)

    fight.boss.take_damage(1)
    check(fight.boss.hp == 6, "Iara must ignore damage outside her attack window")
    fight._physics_process(2.4)
    check(fight.state == fight.State.PREPARING, "Song must be telegraphed before the trance")
    fight._physics_process(0.11)
    check(fight.state == fight.State.CASTING, "Preparation must visibly launch the spell before hypnosis")
    check(not is_instance_valid(fight.player.seduction_source), "Hypnosis cannot begin before the spell arrives")
    fight._physics_process(0.3)
    check(fight.state == fight.State.CASTING, "Spell travel must be visible")
    fight._physics_process(0.26)
    check(fight.state == fight.State.SEDUCING, "Arriving spell must start seduction")
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
    hero.position.x = 400
    fight._update_water(1)
    check(fight.water_exposure == 0, "Retreat to the bank must reset exposure")
    fight._begin_seduction()
    paused = true
    var timer: float = fight.state_timer
    await create_timer(0.1, true).timeout
    check(fight.state_timer == timer, "Pause must freeze seduction")
    paused = false
    fight._physics_process(fight.TRANSE_SECONDS + 0.1)
    check(fight.state == fight.State.DROWNING and hero.hp > 0, "Failure must start slow drowning, not instant death")
    check(hero.control_locked and not hero.is_physics_processing(), "Fatal drowning disables hero actions")
    fight._physics_process(2.9)
    check(hero.hp > 0 and not fight.death_screen.visible, "Hero survives until the end of three-second drowning")
    fight._physics_process(0.11)
    check(hero.hp == 0 and fight.death_screen.visible and hero.sprite.animation == "death", "Drowning must show normal death at three seconds")
    fight._reset_scene()
    while transition.busy:
        await process_frame
    check(current_scene.scene_file_path == "res://rio_negro4.tscn", "Restart must reload the Iara fight")
    check(current_scene.boss.hp == 6 and not current_scene.player.control_locked, "Restart must reset boss and player control")
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
