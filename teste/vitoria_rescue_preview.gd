extends SceneTree

var screenshots := {}
var capture_failed := false

func _initialize() -> void:
    if not OS.get_environment("APPDATA").to_lower().contains("vitoria-rework"):
        push_error("Run this preview with isolated APPDATA containing vitoria-rework")
        quit(1)
        return
    call_deferred("preview")

func preview() -> void:
    create_timer(45.0, true).timeout.connect(func(): quit(1))
    root.size = Vector2i(1280, 720)
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
    var rescue = fight.get_node("VitoriaRescue")
    rescue.sequence.pause()
    rescue.sequence.custom_step(rescue.DROWNED_HOLD_SECONDS + 0.01)
    rescue.dialogue.advance()
    await capture("mystery", rescue)
    while rescue.waiting:
        rescue.dialogue.advance()
    rescue.sequence.pause()
    rescue.sequence.custom_step(0.99)
    await capture("silent-wait", rescue)
    rescue.sequence.custom_step(0.02)
    await capture("offscreen-hit", rescue)
    for step_index in range(1800):
        rescue.sequence.custom_step(0.01)
        var label := ""
        if str(rescue.phase) == "rescue" and rescue.blackout.color.a < 0.65 and rescue.blackout.color.a > 0.3:
            label = "rescue"
        elif rescue.heroine.animation == "transform" and rescue.heroine.frame == 2:
            label = "emergence"
        elif str(rescue.phase) == "stand" and rescue.heroine.modulate.a >= 0.95:
            label = "shared-leaf"
        if not label.is_empty() and not screenshots.has(label):
            await capture(label, rescue)
        if rescue.waiting:
            break
    for attempt in range(256):
        if not rescue.waiting:
            break
        var text: String = rescue.dialogue.text_label.text
        var label := ""
        if rescue.line_index == 0:
            label = "question"
        elif text.to_lower().contains("corpo-seco"):
            label = "revelation"
        elif rescue.line_index == rescue.LINES.size() - 1:
            label = "farewell"
        if not label.is_empty() and not screenshots.has(label):
            rescue.dialogue.advance()
            await capture(label, rescue)
        rescue.dialogue.advance()
    var transition = root.get_node("SceneTransition")
    for step_index in range(200):
        if transition.busy:
            break
        rescue.sequence.custom_step(0.01)
    var victory = _victory_feedback(fight)
    if victory != null:
        victory._process(0.5)
        await capture("phase-complete", rescue)
        victory._process(victory.DURATION + 0.1)
    for step_index in range(1600):
        if transition.phase != "jumping_out":
            break
        if is_instance_valid(transition.exit_tween):
            transition.exit_tween.pause()
            transition.exit_tween.custom_step(0.02)
        var label := ""
        if fight.player.jump_height > 35.0:
            label = "jump-%d" % (transition.exit_leaf_index + 1)
        elif fight.player.jump_height == 0.0 and transition.exit_leaf_index == 1:
            label = "first-landing"
        if not label.is_empty() and not screenshots.has(label):
            await capture(label, rescue)
    print("PASS: Vitoria rework captures=", screenshots.keys())
    quit(1 if capture_failed else 0)

func _victory_feedback(fight: Node) -> Node:
    for child in fight.get_children():
        if child.get_script() == preload("res://scripts/VictoryFeedback.gd"):
            return child
    return null

func capture(label: String, rescue: Node) -> void:
    if is_instance_valid(rescue.sequence):
        rescue.sequence.pause()
    var transition = root.get_node("SceneTransition")
    if is_instance_valid(transition.exit_tween):
        transition.exit_tween.pause()
    # Pause only the manually stepped timelines so the UI and renderer settle.
    if rescue.dialogue.visible:
        await create_timer(0.34, true).timeout
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var path := "res://.validation/vitoria-rework-%s.png" % label
    var result := root.get_texture().get_image().save_png(path)
    if result != OK:
        capture_failed = true
        push_error("Could not save Vitoria preview: " + path)
    else:
        screenshots[label] = true
