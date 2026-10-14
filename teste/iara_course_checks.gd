extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const RIVER_FRAMES = preload("res://sprites/characters/enemy_map2.tres")
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    create_timer(55.0, true).timeout.connect(func():
        push_error("Iara course checks timed out")
        quit(1)
    )
    for index in range(3):
        Progress.complete_stage(index)
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var level = current_scene
    freeze(level)
    check(level.waves.size() == 3 and level.waves[0].size() == 2 and level.waves[1].size() == 3 and level.waves[2] == [level.boss], "Iara phase must contain two enemies, three enemies, then the boss")
    check(level.pits.size() == 1 and level.pits[0].end.x < level.SECOND_STAGE_GATE, "There must be one hole, between the first and second sections")
    check(level.player.position == level.STAGE_START and not level.boss.visible and level.entrance == null, "Fresh phase must start on the road before the boss presentation")
    check(not level.get_node("HUD/BossHealth").visible, "Boss health must stay hidden during the approach")
    check(not level.chant.playing and is_zero_approx(level.chant.volume_linear) and level.chant.stream.loop, "Iara chant must remain stopped during the first section")
    check(is_equal_approx(level.music.volume_linear, level.approach_music_volume), "The first section must keep normal stage music volume")
    var source := load("res://soundeffect/Iara/Canto.mp3") as AudioStreamMP3
    check(level.chant.stream.data == source.data, "Approach must use the supplied Canto.mp3")
    for index in range(2):
        for enemy in level.waves[index]:
            check(enemy.get_node("Sprite").sprite_frames == RIVER_FRAMES, "All five road enemies must use the Rio Negro sprite")
            check(enemy.visible == (index == 0), "Only the current encounter may be visible")
    level._physics_process(20.0)
    check(level.fight_elapsed == 0.0 and level.state_timer == level.INTRO_IDLE_SECONDS, "Iara must not cast or advance her boss clock on the approach")

    level.player.position.x = level.BOSS_GATE
    level._update_chant()
    check(not level.chant.playing, "Reaching the third section cannot start the chant while road enemies survive")
    level._process(0.0)
    check(not level.boss_area_entered, "Surviving road enemies must gate the boss entrance")
    level.player.position = level.STAGE_START
    level._update_chant()
    level._update_approach_music()
    check(is_zero_approx(level.chant.volume_linear), "Retreating to the phase start must restore silence")
    for ratio in [0.0, 0.5, 1.0]:
        level.player.position.x = lerpf(level.SECOND_STAGE_GATE, level.APPROACH_MUSIC_FADE_END, ratio)
        level._update_approach_music()
        var expected: float = level.approach_music_volume * lerpf(1.0, 0.15, ratio)
        check(is_equal_approx(level.music.volume_linear, expected), "Stage music must fade from 100 through 57.5 to 15 percent before section two ends")
    check(level.APPROACH_MUSIC_FADE_END < level.SECOND_ARENA_END, "Stage music must reach 15 percent before the end of section two")
    level.player.position = level.STAGE_START
    level._update_approach_music()

    # The existing jump/fall rule must apply to this new hole.
    level.player.position = level.pits[0].get_center()
    level.player.jump_height = 20.0
    level.check_player_floor(level.player.position)
    check(not level.player.is_falling, "An airborne player may cross the hole")
    level.player.jump_height = 0.0
    level.check_player_floor(level.player.position)
    check(level.player.is_falling, "Walking into the hole must start a fall")
    level.player._physics_process(0.5)
    check(level.player.hp == 0 and level.death_screen.visible, "A fall must use the normal death and checkpoint flow")
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze(level)
    check(level.wave_index == 0 and level.player.position == level.STAGE_START and level.player.hp == level.player.max_hp, "A first-section death must restart the first checkpoint")
    check(is_zero_approx(level.chant.volume_linear), "A fresh retry must reset the chant volume")

    await defeat_wave(level, 0)
    level._process(0.0)
    check(level.road_open and level.arena_bounds.end.x == level.SECOND_ARENA_END, "Defeating both first enemies must open the route past the hole")
    level.player.position = Vector2(level.SECOND_STAGE_GATE, 460)
    level._process(0.0)
    freeze(level)
    check(level.wave_index == 1 and Progress.checkpoint()["id"] == "wave_2", "The second section must save its own checkpoint")
    level.player.take_damage(100)
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    freeze(level)
    check(level.wave_index == 1 and not level.has_node("Enemy1") and not level.has_node("Enemy2"), "Second-section retry must preserve the completed first wave")
    check(level.player.hp == level.player.max_hp and level.chant.playing, "Second-section retry must restore health and start the chant")
    check(is_equal_approx(level.music.volume_linear, level.approach_music_volume), "Second checkpoint must restore music at the start of the fade")
    level.player.position.x = lerpf(level.SECOND_STAGE_GATE, level.BOSS_GATE, 0.5)
    level._process(0.0)
    check(level.chant.playing and is_equal_approx(level.chant.volume_linear, 0.425), "Chant must grow during the second encounter even while its enemies are alive")
    for enemy in level.waves[1]:
        check(enemy.visible and enemy.hp == enemy.max_hp, "Second checkpoint must reset all three enemies")
    await defeat_wave(level, 1)
    level._process(0.0)
    check(level.road_open and level.arena_bounds.end.x > level.BOSS_GATE, "Defeating the second wave must open the continuous boss approach")
    level.player.position = Vector2(level.SECOND_ARENA_END - 1.0, 460)
    level._process(0.0)
    check(level.chant.playing and is_equal_approx(level.music.volume_linear, level.approach_music_volume * 0.15), "Before leaving section two, music must be at 15 percent while the chant continues")
    level.player.position = Vector2(level.BOSS_ARENA_START, 460)
    level._process(0.0)
    check(level.chant.playing and not level.boss_intro_running, "Entering the third section must keep the chant playing without starting the cutscene")
    level.player.position.x += 149.0
    level._process(0.0)
    check(not level.boss_intro_running, "The first 149 pixels in section three must remain playable before the cutscene")
    level.player.position.x = lerpf(level.SECOND_STAGE_GATE, level.BOSS_GATE, 0.5)
    level._process(0.0)
    check(is_equal_approx(level.chant.volume_linear, 0.425), "Chant must rise to half of its 85 percent cap midway through the approach")
    level.player.position.x = level.BOSS_GATE
    level._update_chant()
    check(is_equal_approx(level.chant.volume_linear, 0.85), "Chant must reach its 85 percent maximum at the cutscene gate")
    for x in range(int(level.SECOND_STAGE_GATE), int(level.BOSS_GATE), 40):
        level.player.position = Vector2(x, 460)
        level.check_player_floor(level.player.position)
        check(not level.player.is_falling, "The second-to-third path must contain no hole")
    level.player.position = Vector2(level.BOSS_GATE - 1.0, 460)
    level._process(0.0)
    check(not level.boss_intro_running and level.chant.volume_linear > 0.848 and level.chant.volume_linear <= 0.85, "Chant must approach its 85 percent cap at the edge of the arena")
    paused = true
    var volume: float = level.chant.volume_linear
    await create_timer(0.1, true).timeout
    check(is_equal_approx(level.chant.volume_linear, volume), "Pause must hold the approach sound state")
    paused = false
    level.player.position = Vector2(level.BOSS_GATE, 460)
    level._process(0.0)
    check(level.wave_index == 2 and level.boss_area_entered and level.boss_intro_running, "The third section must begin Iara's cutscene")
    check(not level.chant.playing and level.boss.visible and Progress.checkpoint()["id"] == "boss", "Boss entrance must save its checkpoint and stop the distant chant for the cutscene")
    check(is_equal_approx(level.player.position.x - level.BOSS_ARENA_START, 150.0), "The cutscene must begin after 150 pixels of walking in section three")
    check(not level.music.playing and is_equal_approx(level.music.volume_linear, level.approach_music_volume * 0.15), "Stage music must remain at 15 percent on the approach and stop for the cutscene")
    level.entrance.finish()
    check(level.music.stream.data == load("res://music/Iara.mp3").data and is_equal_approx(level.music.volume_linear, level.approach_music_volume), "The bossfight must use Iara.mp3 at normal volume")
    freeze(level)
    level.player.take_damage(100)
    level._reset_scene()
    await wait_for_transition()
    level = current_scene
    check(level.wave_index == 2 and level.boss_intro_running and level.player.hp == level.player.max_hp, "Boss retry must start directly at the cutscene with full health")
    check(not level.has_node("Enemy3") and not level.has_node("Enemy4") and not level.has_node("Enemy5"), "Boss checkpoint must skip all five road enemies")
    check(level.player.position.x < level.WATER_EDGE and not level.chant.playing, "Boss checkpoint must remain on the safe bank without restarting the approach chant")
    if failures == 0:
        print("PASS: Iara course/checkpoints, chant during section two capped at 85 percent, stage music at 15 percent and cutscene after 150 pixels")
    quit(0 if failures == 0 else 1)

func freeze(level: Node) -> void:
    level.set_process(false)
    level.set_physics_process(false)
    for actor in get_nodes_in_group("player") + get_nodes_in_group("enemy"):
        actor.set_physics_process(false)

func defeat_wave(level: Node, index: int) -> void:
    for enemy in level.waves[index]:
        enemy.take_damage(enemy.hp)
    await process_frame

func wait_for_transition() -> void:
    while root.get_node("SceneTransition").busy:
        await process_frame
    await process_frame
