extends SceneTree

const Progress = preload("res://scripts/CampaignProgress.gd")
const Frames = preload("res://scripts/VitoriaFrames.gd")
const STEP_SECONDS := 0.01

var failures := 0
var speakers: Array[String] = []
var conversation := ""

func _initialize() -> void:
    if not OS.get_environment("APPDATA").to_lower().contains("vitoria-rework"):
        push_error("Run these save-writing checks with isolated APPDATA containing vitoria-rework")
        quit(1)
        return
    call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run_checks() -> void:
    create_timer(45.0, true).timeout.connect(func():
        push_error("Vitoria rescue checks timed out")
        quit(1)
    )
    root.size = Vector2i(1280, 720)
    _check_frames()
    for index in range(3):
        Progress.complete_stage(index)
    change_scene_to_file("res://rio_negro4.tscn")
    await process_frame
    await process_frame
    var fight = current_scene
    preload("res://iara_test_support.gd").prepare_fight(fight)
    fight.boss.hp = 3
    fight.on_iara_damaged()
    fight.boss.hp = 1
    fight.on_iara_damaged()
    fight._physics_process(fight.state_timer + 0.01)
    fight._physics_process(fight.CAST_SECONDS + 0.01)
    fight.player.position = fight.WATER_POSITION + Vector2(30, 0)
    fight._physics_process(0.01)
    fight._physics_process(fight.DROWNING_SECONDS * 0.91)
    check(fight.rescue_running, "Final drowning must begin Vitoria's rescue")
    var rescue = fight.get_node("VitoriaRescue")
    rescue.sequence.pause()
    var saved_hp: int = fight.player.hp
    check(saved_hp > 0 and fight.boss.hp == 1 and not fight.finished, "The drowning rescue preserves the living hero until the offscreen strike")
    rescue.sequence.custom_step(rescue.DROWNED_HOLD_SECONDS - 0.1)
    check(not rescue.waiting and not rescue.dialogue.visible, "The mysterious voice waits for the full blackout")
    rescue.sequence.custom_step(0.11)
    check(rescue.waiting and rescue.dialogue.visible and rescue.blackout.color.a >= 0.95, "The mysterious opening speech remains over the dark river")
    check(rescue.dialogue.speaker == "vitoria" and rescue.dialogue.portrait.modulate.r < 0.15, "The opening voice keeps Vitoria's identity concealed")
    var paused_camera: Vector2 = rescue.camera.global_position
    var paused_blackout: Color = rescue.blackout.color
    var paused_clock: float = rescue.effect_clock
    paused = true
    await create_timer(0.08, true).timeout
    check(rescue.camera.global_position == paused_camera and rescue.blackout.color == paused_blackout and rescue.effect_clock == paused_clock, "Pause freezes the rescue camera, blackout and ambient effects")
    paused = false
    _advance_dialogue(rescue, false)
    rescue.sequence.pause()
    rescue.sequence.custom_step(0.99)
    check(fight.boss.hp == 1 and not fight.sound_effects.players["hit"].playing and not rescue.punch.playing, "The offscreen punch and Iara hit wait one whole second after the opening speech")
    check(rescue.blackout.color.a >= 0.95 and not rescue.dialogue.visible, "The full one-second silence stays dark without a dialogue box")
    rescue.sequence.custom_step(0.02)
    check(fight.boss.hp == 0 and rescue.strike_played and rescue.blackout.color.a >= 0.95, "Iara is defeated offscreen before the visible rescue begins")
    check(fight.sound_effects.players["hit"].playing and rescue.punch.playing, "The hidden strike plays both the punch effect and Iara's hit voice")

    var transform_frames := {}
    var phases := {}
    var attack_seen := false
    var uncovered_upright_iara := false
    var hero_was_teleported := false
    var saved_health_preserved := true
    var completed_before_conversation := false
    var previous_hero: Vector2 = fight.player.position
    var previous_alpha: float = rescue.blackout.color.a
    for step_index in range(1600):
        rescue.sequence.custom_step(STEP_SECONDS)
        phases[str(rescue.phase)] = true
        var heroine: AnimatedSprite2D = rescue.heroine
        var visual := fight.boss.get_node("Sprite") as AnimatedSprite2D
        attack_seen = attack_seen or heroine.animation == "dash" or str(rescue.phase) in ["dash", "attack", "return"]
        if heroine.animation == "transform" and heroine.modulate.a > 0.01:
            transform_frames[heroine.frame] = true
        if rescue.blackout.color.a < 0.7:
            uncovered_upright_iara = uncovered_upright_iara or visual.animation not in ["fall", "death"] or not fight.boss.visible or visual.modulate.a < 0.95
        if previous_alpha < 0.7 and rescue.blackout.color.a < 0.7:
            hero_was_teleported = hero_was_teleported or fight.player.position.distance_to(previous_hero) > 18.0
        saved_health_preserved = saved_health_preserved and fight.player.hp == saved_hp
        completed_before_conversation = completed_before_conversation or fight.finished
        previous_hero = fight.player.position
        previous_alpha = rescue.blackout.color.a
        if rescue.waiting:
            break
    check(rescue.waiting and fight.boss.hp == 0, "The visible rescue reaches the conversation after defeating Iara in darkness")
    check(not completed_before_conversation, "The stage waits until the entire rescue conversation ends")
    check(not attack_seen, "Vitoria does not perform a visible dash, strike or return")
    check(transform_frames.size() == 5, "Vitoria's emergence shows all five transformation poses on one timeline")
    check(not uncovered_upright_iara, "Iara is already lying visibly on the floor whenever the blackout reveals the river")
    check(not hero_was_teleported, "The visible rescue moves the hero continuously onto the shared leaf")
    check(saved_health_preserved and fight.player.hp > 0, "The rescue preserves the saved hero's exact HP")
    check(fight.vitoria_leaf.visible and fight.vitoria_leaf.animation == "leaf" and fight.vitoria_leaf.modulate.a >= 0.95, "The conversation uses a visible clean shared leaf")
    check(rescue.heroine.animation == "idle" and rescue.heroine.rotation == 0.0, "Vitoria stands upright before speaking")
    check(fight.player.position.x > rescue.heroine.position.x, "The hero stands to Vitoria's right on the same leaf")
    var platform_half_width: float = rescue.leaf_width * fight.vitoria_leaf.scale.x * 0.5
    check(absf(fight.player.position.x - fight.vitoria_leaf.position.x) < platform_half_width and absf(rescue.heroine.position.x - fight.vitoria_leaf.position.x) < platform_half_width, "Both characters stay within the shared leaf's width")
    rescue.camera.force_update_scroll()
    var half_view: Vector2 = Vector2(root.size) / rescue.camera.zoom * 0.5
    var visible_world := Rect2(rescue.camera.get_screen_center_position() - half_view, half_view * 2.0)
    check(visible_world.has_point(fight.boss.position + Vector2(0, -30)), "Iara's collapsed body remains in the rescue conversation's frame")
    var body_on_screen := _opaque_screen_bounds(fight.boss.get_node("Sprite"))
    var platform_on_screen := _opaque_screen_bounds(fight.vitoria_leaf)
    check(body_on_screen.position.x >= -1.0 and body_on_screen.end.x <= root.size.x + 1.0, "The rescue frame contains Iara's complete collapsed artwork, including her head")
    check(platform_on_screen.end.y < rescue.dialogue.global_position.y + 30.0, "The shared leaf remains visible above the dialogue frame")
    var closing_camera: Camera2D = rescue.camera
    var closing_center: Vector2 = closing_camera.get_screen_center_position()
    var closing_position: Vector2 = closing_camera.global_position
    check(fight.get_viewport().get_camera_2d() == closing_camera, "The conversation uses the rescue camera")
    _advance_dialogue(rescue, true)
    check(speakers.size() >= 4 and speakers.slice(0, 4) == ["player", "vitoria", "player", "vitoria"], "The hero and Vitoria alternate their questions and answers")
    var story := conversation.to_lower()
    check(story.contains("o que aconteceu") and story.contains("quem") and story.contains("plano"), "The hero asks what happened, who rescued him and what the villains plan")
    check(story.contains("cuca") and story.contains("corpo-seco") and story.contains("ressuscit"), "Vitoria reveals Cuca's plot to resurrect Corpo-Seco")
    check(story.contains("céu") and story.contains("inferno") and (story.contains("maldade") or story.contains("cruel")), "The warning explains Corpo-Seco's rejection and cruelty")
    check(story.contains("floresta") and story.contains("caverna"), "The farewell points the hero toward phase five's forest and Cuca's cave")
    var transition = root.get_node("SceneTransition")
    for step_index in range(200):
        if transition.busy:
            break
        rescue.sequence.pause()
        rescue.sequence.custom_step(0.01)
    check(fight.finished and fight.state == fight.State.DEFEATED and transition.busy, "The completed conversation starts the shared stage completion flow")
    check(Progress.completed_stages() == 4 and Progress.is_available(4), "The completed rescue saves phase four and unlocks the forest")
    check(transition.phase == "celebrating" and transition.exit_camera == closing_camera, "The phase-complete title retains the rescue camera immediately")
    check(fight.get_viewport().get_camera_2d() == closing_camera and closing_camera.get_screen_center_position().distance_to(closing_center) < 1.0, "Phase completion does not snap back to the boss-fight camera")
    var victory = _victory_feedback(fight)
    check(victory != null and victory.title.text.contains("FASE CONCLU"), "The standard phase-complete title appears over the rescue scene")
    if victory != null:
        victory._process(victory.DURATION + 0.1)
    check(transition.phase == "jumping_out" and transition.exit_leaf_count >= 3, "The farewell uses several rightward lily-pad jumps")
    var jump_arcs := {}
    var landed := {}
    var exit_continuous := true
    var exit_health_preserved := true
    var exit_camera_preserved := true
    var previous_position: Vector2 = fight.player.global_position
    for step_index in range(2000):
        if transition.phase != "jumping_out":
            break
        if is_instance_valid(transition.exit_tween):
            transition.exit_tween.pause()
            transition.exit_tween.custom_step(0.02)
        if fight.player.jump_height > 8.0:
            jump_arcs[transition.exit_leaf_index] = true
        if fight.player.jump_height == 0.0 and transition.exit_leaf_index > 0:
            landed[transition.exit_leaf_index] = true
        exit_continuous = exit_continuous and fight.player.global_position.distance_to(previous_position) < 18.0 and fight.player.global_position.x >= previous_position.x - 0.01
        exit_health_preserved = exit_health_preserved and fight.player.hp == saved_hp
        exit_camera_preserved = exit_camera_preserved and transition.exit_camera == closing_camera and closing_camera.global_position.distance_to(closing_position) < 1.0
        previous_position = fight.player.global_position
    check(exit_continuous and jump_arcs.size() >= 3 and landed.size() >= 3, "The exit includes continuous visible arcs and distinct landings on several leaves")
    check(exit_health_preserved, "Lily-pad jumps preserve the hero's HP")
    check(exit_camera_preserved, "The farewell retains the rescue framing")
    check(transition.exit_leaf_index == transition.exit_leaf_count and transition.phase == "fading_out", "The black fade starts only after every lily-pad landing")
    check(fight.player.global_position.x >= transition.exit_target_x - 0.1 and fight.player.jump_height == 0.0, "The hero completes his final jump beyond the right edge before fading")
    check(not transition.screen.visible and transition.fade_screen.visible, "Loading artwork stays hidden until the farewell and black fade finish")
    for attempt in range(600):
        if not transition.busy:
            break
        await create_timer(0.01, true).timeout
    check(not transition.busy and not paused and current_scene.scene_file_path == "res://level_map.tscn", "The completed lily-pad exit returns to the unpaused campaign map")
    if failures == 0:
        print("PASS: mystery voice, one-second offscreen punch/hit, prior Iara collapse, continuous shared-leaf rescue, alternating Corpo-Seco dialogue, preserved victory camera, lily-pad arcs/landings, saved HP, pause and campaign map; phases=", phases.keys())
    quit(0 if failures == 0 else 1)

func _advance_dialogue(rescue: Node, record: bool) -> void:
    for attempt in range(256):
        if not rescue.waiting:
            return
        if record:
            var speaker: String = rescue.dialogue.speaker
            if speakers.is_empty() or speakers.back() != speaker:
                speakers.append(speaker)
            var page: String = rescue.dialogue.text_label.text
            if not conversation.ends_with(page + " "):
                conversation += page + " "
        rescue.dialogue.advance()
    check(not rescue.waiting, "The cinematic dialogue finishes after all its pages are advanced")

func _victory_feedback(fight: Node) -> Node:
    for child in fight.get_children():
        if child.get_script() == preload("res://scripts/VictoryFeedback.gd"):
            return child
    return null

func _opaque_screen_bounds(visual: AnimatedSprite2D) -> Rect2:
    var texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
    var bounds := Rect2(texture.get_image().get_used_rect())
    if visual.flip_h:
        bounds.position.x = texture.get_width() - bounds.end.x
    if visual.flip_v:
        bounds.position.y = texture.get_height() - bounds.end.y
    bounds.position += visual.offset
    if visual.centered:
        bounds.position -= texture.get_size() * 0.5
    return visual.get_global_transform_with_canvas() * bounds

func _check_frames() -> void:
    var frames: SpriteFrames = Frames.build()
    var frame_size: Vector2 = frames.get_frame_texture("plant", 0).get_size()
    for animation in ["plant", "leaf", "transform", "idle", "dash"]:
        check(frames.has_animation(animation), "Missing Vitoria animation: " + animation)
        if not frames.has_animation(animation):
            continue
        for index in frames.get_frame_count(animation):
            var texture: AtlasTexture = frames.get_frame_texture(animation, index)
            check(texture.region.size.x > 0.0 and texture.region.size.y > 0.0, "Every Vitoria pose contains visible artwork")
            check(texture.get_size() == frame_size, "All Vitoria poses share a common feet-aligned canvas")
            check(texture.margin.size.x >= 0.0 and texture.margin.size.y >= 0.0, "Vitoria's artwork fits inside its canvas without clipping")
            check(absf(texture.region.size.y + texture.margin.position.y - frame_size.y) <= 1.0, "The feet and leaf bases remain on the same canvas baseline")
    if frames.has_animation("leaf"):
        var flower: AtlasTexture = frames.get_frame_texture("plant", 0)
        var leaf: AtlasTexture = frames.get_frame_texture("leaf", 0)
        check(absf(flower.region.size.x - leaf.region.size.x) <= 2.0, "Removing the flower preserves the shared leaf's width")
        check(flower.atlas != leaf.atlas, "The shared platform uses its own flower-free artwork")
