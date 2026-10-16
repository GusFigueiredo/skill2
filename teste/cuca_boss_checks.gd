extends SceneTree

const Progress := preload("res://scripts/CampaignProgress.gd")
const STAGE_PATH := "res://caverna6.tscn"
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    if not OS.get_environment("APPDATA").contains("cuca-boss"):
        push_error("Use a fresh isolated APPDATA containing cuca-boss for boss checks")
        quit(1)
        return
    create_timer(80.0, true).timeout.connect(func():
        push_error("Cuca boss checks timed out")
        quit(1)
    )
    check(Progress.completed_stages() == 0, "Use a fresh isolated campaign")
    for index in range(5):
        Progress.complete_stage(index)
    change_scene_to_file(STAGE_PATH)
    await settle()
    var level = current_scene
    freeze_exploration(level)
    level.player.position = Vector2(4250, 450)
    level._process(0)
    check(not level.boss_started and level.cuca_fight == null, "The laboratory must stay closed while the last exploration enemies survive")
    for wave in level.waves:
        for enemy in wave:
            if is_instance_valid(enemy):
                enemy.take_damage(enemy.hp)
    await process_frame
    level.wave_index = 2
    level.player.jump_height = 30
    level._process(0)
    check(not level.boss_started, "A midair hero must land before the laboratory cutscene takes control")
    level.player.jump_height = 0
    level.player.position = Vector2(4199, 450)
    level._process(0)
    check(not level.boss_started, "The third encounter must still require reaching the laboratory threshold")
    level.player.position.x = 4200
    level._process(0)
    await process_frame
    check(level.boss_started and is_instance_valid(level.cuca_fight), "Entering the cleared laboratory must install Cuca in phase six")
    check(level.checkpoint_id == "boss" and Progress.checkpoint().get("id", "") == "boss", "Laboratory entry must save a dedicated boss checkpoint")
    var fight = level.cuca_fight
    await finish_intro(level)
    freeze_combat(level)
    check(not level.boss_intro_running and not level.player.control_locked, "The entrance sequence must restore normal player control")
    check(fight.actor.hp == 18 and fight.actor.max_hp == 18, "The Cuca encounter must begin with its complete health pool")
    check(level.arena_bounds.position.x >= 4100 and level.arena_bounds.end.x <= level.STAGE_LENGTH, "The laboratory must confine movement to a real arena inside the map")
    check(level.cuca_health.is_visible_in_tree() and level.cuca_name.text.begins_with("CUCA") and level.cuca_health.max_value == 18, "The boss HUD must show Cuca and her full health during the encounter")
    check(Progress.completed_stages() == 5 and not Progress.is_available(6), "Starting the boss must not prematurely unlock Corpo-Seco")

    await check_attacks(level)
    await check_floor_hazards(level)
    await check_phase_patterns(level)
    await check_pause(level)

    # A true death and the normal retry action must skip all three cleared
    # groups and restore a fresh boss, rather than replaying the cave route.
    level.player.hp = level.player.max_hp
    level.player.damage_cooldown = 0
    level.player.take_damage(100)
    check(level.player.hp == 0 and level.death_screen.visible, "Dying in the laboratory must use the existing death screen")
    level.cuca_fight._physics_process(0.01)
    check(not level.cuca_fight.active and level.cuca_fight.projectiles.is_empty() and level.cuca_fight.hazards.is_empty() and level.cuca_fight.boss_stalactites.is_empty(), "A dead player must stop the boss and cancel every outstanding hazard before retry")
    level._reset_scene()
    while root.get_node("SceneTransition").busy:
        await process_frame
    await settle()
    level = current_scene
    check(level.scene_file_path == STAGE_PATH and level.checkpoint_id == "boss", "Retry must remain in phase six at the boss checkpoint")
    for wave in level.waves:
        check(alive_count(wave) == 0, "Boss retry must preserve all three completed exploration encounters")
    await finish_intro(level)
    freeze_combat(level)
    check(level.player.hp == level.player.max_hp and level.cuca_fight.actor.hp == 18, "Boss retry must fully reset both combatants")
    await check_defeat(level)
    if failures == 0:
        print("PASS: laboratory gating/checkpoint/retry, accepted attack reflection, readable channel shield, ordinary melee damage, rebound overload, floor hazards/jump/dodge, targeted ceiling rocks, three phase patterns, pause, defeat cleanup and pending ritual progression")
    quit(0 if failures == 0 else 1)

func check_attacks(level: Node) -> void:
    var fight = level.cuca_fight
    var hero = level.player
    fight._set_state(fight.State.CHANNELING)
    hero.position = fight.actor.position - Vector2(60, 0)
    hero.facing = 1
    hero.attack_vertical = 0
    hero.attack_cooldown_timer = 0
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.actor.hp == 18, "The visible channeling shield must reject an actual melee attack")

    fight._set_state(fight.State.RECOVERY)
    hero.attack_cooldown_timer = 0
    hero._attack()
    check(fight.actor.hp == 17, "An ordinary player strike must damage Cuca outside channeling without requiring a parry first")
    var hp: int = fight.actor.hp
    hero.attack_cooldown_timer = 0
    hero.position.y += 90
    hero._attack()
    check(fight.actor.hp == hp, "Melee attacks from a different ground lane must miss Cuca")
    hero.position = Vector2(4430, 450)
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0

    var spell = fight._spawn_skull()
    spell.set_physics_process(false)
    spell.position = hero.position + Vector2(65, 0)
    spell.direction = Vector2.LEFT
    check(spell.can_reflect(hero, Vector2.RIGHT) and not spell.can_reflect(hero, Vector2.LEFT), "A skull must be counterable only when a close punch faces the approaching projectile")
    spell.position.x += 100
    check(not spell.can_reflect(hero, Vector2.RIGHT), "An out-of-range punch must not reflect a distant skull")
    spell.position.x -= 100
    hero.facing = 1
    hero.attack_vertical = 0
    hero.attack_cooldown_timer = 0
    hero._attack()
    check(spell.reflected and fight.reflected_count == 1, "The actual accepted K attack must reflect the nearby skull through Player.attack_performed")

    var blocked = fight._spawn_skull()
    blocked.set_physics_process(false)
    blocked.position = hero.position + Vector2(65, 0)
    blocked.direction = Vector2.LEFT
    hero._attack()
    check(not blocked.reflected, "Attacks rejected by the ordinary cooldown must not reflect skulls")
    var echo := InputEventKey.new()
    echo.keycode = KEY_K
    echo.physical_keycode = KEY_K
    echo.pressed = true
    echo.echo = true
    Input.parse_input_event(echo)
    Input.flush_buffered_events()
    echo = echo.duplicate()
    echo.pressed = false
    echo.echo = false
    Input.parse_input_event(echo)
    Input.flush_buffered_events()
    check(not blocked.reflected, "A raw keyboard repeat must never bypass the accepted attack signal")
    blocked.queue_free()
    for _step in range(80):
        if not is_instance_valid(spell) or spell.is_queued_for_deletion():
            break
        spell._physics_process(0.025)
    check(fight.state == fight.State.STAGGERED and fight.overload_count == 1, "A reflected skull must actually travel into the cauldron and open the long stagger window")
    check(fight.actor.hp == hp and fight.projectiles.is_empty() and fight.hazards.is_empty(), "Overloading must clear attacks and open melee access without inflicting hidden boss damage")
    hero.position = fight.actor.position - Vector2(60, 0)
    hero.attack_cooldown_timer = 0
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.actor.hp == hp - 1, "A normal strike must hit during the cauldron's stagger window")
    fight.actor.hp = fight.actor.max_hp
    fight._set_state(fight.State.RECOVERY)
    await process_frame
    # The same approaching projectile that can be countered must also have
    # its ordinary hit and airborne avoidance; it is never a mandatory QTE.
    for airborne in [false, true]:
        hero.position = Vector2(4430, 450)
        hero.hp = hero.max_hp
        hero.damage_cooldown = 0
        hero.jump_height = 70 if airborne else 0
        var incoming = fight._spawn_skull()
        incoming.set_physics_process(false)
        incoming.position = hero.position + Vector2(65, 0)
        incoming.direction = Vector2.LEFT
        incoming._physics_process(0.50)
        check(hero.hp == (10 if airborne else 8), "An uncountered skull must hit a grounded hero for two HP while an adequate jump clears it")
        fight._clear_attacks()
        await process_frame
    hero.jump_height = 0
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0

func check_floor_hazards(level: Node) -> void:
    var fight = level.cuca_fight
    var hero = level.player
    hero.position = Vector2(4490, 480)
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    fight._set_state(fight.State.RECOVERY)
    var poison = fight._add_hazard("poison", hero.position)
    poison.set_physics_process(false)
    poison._physics_process(poison.warning - 0.02)
    check(not poison.activated and hero.hp == 10, "A poison marker must give a complete harmless warning before becoming a pool")
    poison._physics_process(0.03)
    check(poison.activated and hero.hp == 9, "Standing inside an active poison pool must deal one damage")
    hero.damage_cooldown = 0
    poison._physics_process(0.1)
    check(hero.hp == 9, "A poison pool must not deal damage every frame")
    hero.position.x += 100
    poison._physics_process(1.2)
    check(hero.hp == 9, "Leaving the marked poison area must stop its damage")
    poison._physics_process(poison.duration + 1.0)
    check(poison.is_queued_for_deletion(), "Poison must expire and free the arena after its visible lifetime")
    fight._clear_attacks()
    await process_frame

    hero.position = Vector2(4500, 450)
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    hero.can_dodge = true
    hero._start_dodge(1)
    var dodged = fight._add_hazard("poison", hero.position)
    dodged.set_physics_process(false)
    dodged._physics_process(dodged.warning + 0.01)
    check(hero.is_dodging and hero.hp == 10, "The normal dodge must retain invulnerability against poison")
    hero._end_dodge()
    fight._clear_attacks()
    await process_frame

    for airborne in [false, true]:
        hero.position = Vector2(4550, 450)
        hero.hp = hero.max_hp
        hero.damage_cooldown = 0
        hero.jump_height = 45 if airborne else 0
        var wave = fight._add_hazard("wave", hero.position - Vector2(100, 0))
        wave.set_physics_process(false)
        wave._physics_process(wave.warning + 0.01)
        check(wave.activated, "The expanding cauldron wave must follow its visible warning")
        check(hero.hp == (10 if airborne else 8), "A normal jump must clear the same wave that hits a grounded hero for two HP")
        hero.damage_cooldown = 0
        wave._physics_process(0.5)
        check(hero.hp == (10 if airborne else 8), "A wave must pass by without striking the same hero repeatedly")
        fight._clear_attacks()
        await process_frame
    hero.jump_height = 0
    hero.position = Vector2(4520, 520)
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    fight.phase = 1
    fight._spawn_stones()
    check(fight.boss_stalactites.size() == 1, "The middle phase must start with one targeted ceiling rock")
    var stone = fight.boss_stalactites[0]
    stone.set_physics_process(false)
    check(stone.state == stone.State.WARNING and stone.position.y < 180 and stone.landing_y == 520 and stone.position.x == hero.position.x, "The spell must warn at the crossed lane while its rock remains attached to the ceiling")
    hero.position.y = 450
    stone._begin_fall()
    stone._physics_process(1.0)
    check(hero.hp == 10 and not stone.damage_dealt, "Changing lane during the falling-rock warning must avoid the impact")
    fight._clear_attacks()
    await process_frame
    hero.position = Vector2(4520, 520)
    fight._spawn_stones()
    stone = fight.boss_stalactites[0]
    stone.set_physics_process(false)
    stone._begin_fall()
    stone._physics_process(1.0)
    check(hero.hp == 5 and stone.damage_dealt, "A direct boss stalactite impact must retain the established 50% maximum-health damage")
    fight._clear_attacks()
    await process_frame
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0

func check_phase_patterns(level: Node) -> void:
    var fight = level.cuca_fight
    var hero = level.player
    hero.position = fight.actor.position - Vector2(60, 0)
    fight.phase = 0
    fight._set_state(fight.State.RECOVERY)
    fight.actor.hp = 13
    fight.actor.take_damage(1)
    check(fight.phase == 1, "Actual boss damage at two-thirds health must introduce the second phase")
    fight.actor.hp = 7
    fight.actor.take_damage(1)
    check(fight.phase == 2, "Actual boss damage at one-third health must introduce the final phase")
    for phase in range(3):
        fight.phase = phase
        fight.action_index = 0
        var attacks: Array[String] = []
        for _action in range(6):
            fight._begin_action()
            attacks.append(fight.current_attack)
            fight._physics_process(1.4)
            check(fight.state == fight.State.CASTING, "Every scheduled spell must first have its channeling telegraph")
            fight._physics_process(0.50)
            check(fight.cast_released, "A casting animation must visibly precede the spell release")
            fight._physics_process(0.40)
            check(fight.state == fight.State.RECOVERY, "Every spell must leave Cuca open to approach and melee")
            for effect in fight.projectiles + fight.hazards + fight.boss_stalactites:
                effect.set_physics_process(false)
            fight._clear_attacks()
            fight._physics_process(2.8)
            await process_frame
        check("skull" in attacks and "poison" in attacks and "wave" in attacks, "Every phase must preserve the learned projectile, poison and jump responses")
        if phase > 0:
            check("stones" in attacks and "poison_wave" in attacks, "Later phases must combine the learned hazards and target the ceiling")
    fight._set_state(fight.State.RECOVERY)
    fight.actor.hp = 18
    fight.phase = 0

func check_pause(level: Node) -> void:
    var fight = level.cuca_fight
    level.player.position = Vector2(4450, 450)
    var spell = fight._spawn_skull()
    var pool = fight._add_hazard("poison", level.player.position)
    fight.set_physics_process(true)
    var clock: float = fight.state_timer
    var spell_age: float = spell.age
    var spell_position: Vector2 = spell.position
    var pool_age: float = pool.age
    paused = true
    await create_timer(0.14, true).timeout
    check(fight.state_timer == clock and spell.age == spell_age and spell.position == spell_position and pool.age == pool_age, "Pausing must freeze the boss state, travelling skull and poison warning clocks")
    paused = false
    fight.set_physics_process(false)
    fight._clear_attacks()
    await process_frame

func check_defeat(level: Node) -> void:
    var fight = level.cuca_fight
    var hero = level.player
    fight._set_state(fight.State.RECOVERY)
    hero.position = fight.actor.position - Vector2(60, 0)
    hero.facing = 1
    hero.attack_vertical = 0
    hero.hp = hero.max_hp
    hero.damage_cooldown = 0
    hero.attack_cooldown_timer = 0
    fight.actor.hp = 1
    fight._spawn_skull()
    fight._spawn_poison()
    fight._spawn_stones()
    await physics_frame
    await physics_frame
    hero._attack()
    check(fight.actor.hp == 0 and fight.state == fight.State.DEFEATED, "The final real melee attack must defeat Cuca and start her death animation")
    check(fight.projectiles.is_empty() and fight.hazards.is_empty() and fight.boss_stalactites.is_empty(), "Defeat must immediately cancel skulls, pools and falling ceiling rocks")
    check(not fight.damage_player(10) and hero.hp == hero.max_hp, "No delayed spell may hurt the player after Cuca's defeat")
    check(not fight.actor.take_damage(1), "A defeated Cuca must ignore further attacks")
    check(fight.actor.visual.animation == "death", "Defeat must use the supplied fallen sprite sequence")
    await process_frame
    fight._physics_process(1.2)
    await process_frame
    check(level.boss_defeated and is_instance_valid(level.result_panel) and level.result_panel.visible, "The fallen boss must reach the temporary result screen after her death pose")
    check(current_scene.scene_file_path == STAGE_PATH and Progress.completed_stages() == 5 and not Progress.is_available(6), "The pending final cutscene must preserve the cave scene and keep Corpo-Seco locked")
    check(Progress.checkpoint().get("id", "") == "boss", "The temporary ending must leave the encounter available for replay")

func finish_intro(level: Node) -> void:
    for _step in range(400):
        await create_timer(0.02, true).timeout
        if level.cuca_fight != null and not level.boss_intro_running:
            return
    check(false, "Cuca's introduction must finish and return control without requiring hidden inputs")

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

func freeze_combat(level: Node) -> void:
    freeze_exploration(level)
    level.cuca_fight.set_physics_process(false)

func alive_count(wave: Array) -> int:
    var count := 0
    for enemy in wave:
        if is_instance_valid(enemy) and enemy.hp > 0:
            count += 1
    return count

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
