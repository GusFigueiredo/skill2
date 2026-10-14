extends Node

var fight: Node2D
var sequence: Tween
var camera: Camera2D
var heroine: AnimatedSprite2D
var dialogue: Control
var waiting := false
var dialogue_opened := 0
var phase := "chant"

func start(level: Node2D) -> void:
    fight = level
    fight._clear_seduction()
    fight.boss_intro_running = true
    fight.get_node("HUD").hide()
    fight.player._end_dodge()
    fight.player.control_locked = true
    fight.player.set_physics_process(false)
    fight.player.velocity = Vector2.ZERO
    fight.player.sprite.set_process(false)
    fight.player.sprite.play("hurt")
    for enemy in fight.get_tree().get_nodes_in_group("enemy"):
        if enemy != fight.boss:
            enemy.set_physics_process(false)
    fight.boss.get_node("Sprite").set_process(false)
    fight.boss.get_node("Sprite").play("attack_loop")
    fight.music.volume_db = fight.original_music_volume - 10.0
    camera = Camera2D.new()
    add_child(camera)
    camera.global_position = fight.player.get_node("Camera2D").get_screen_center_position()
    camera.zoom = fight.player.get_node("Camera2D").zoom
    camera.make_current()
    var bars := preload("res://scripts/BossEntrance.gd").new()
    add_child(bars)
    var ui := CanvasLayer.new()
    ui.layer = 5
    add_child(ui)
    dialogue = preload("res://scripts/DialogueBox.gd").new()
    ui.add_child(dialogue)
    dialogue.completed.connect(func():
        waiting = false
        sequence.play()
    )
    heroine = AnimatedSprite2D.new()
    heroine.sprite_frames = fight.vitoria_leaf.sprite_frames
    heroine.offset = Vector2(0, -135)
    heroine.scale = Vector2.ONE
    heroine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    heroine.position = fight.vitoria_leaf.position
    heroine.z_index = 5
    heroine.modulate.a = 0.0
    fight.add_child(heroine)
    var destination: Vector2 = fight.player.position
    sequence = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _sink(0.9)
    sequence.tween_property(camera, "global_position", destination + Vector2(0, -45), 0.6)
    sequence.tween_callback(func(): _say("Ela pode dominar o canto das águas. Mas não toda a vida que existe nelas."))
    sequence.tween_callback(_raise_leaf)
    sequence.tween_property(fight.vitoria_leaf, "position", destination + Vector2(32, 8), 1.1)
    sequence.parallel().tween_property(fight.vitoria_leaf, "scale", Vector2.ONE, 1.1)
    sequence.parallel().tween_method(_sink, 0.9, 0.0, 1.1)
    sequence.tween_callback(_reveal)
    sequence.tween_interval(1.0)
    sequence.tween_callback(_stand)
    sequence.tween_interval(0.6)
    sequence.tween_callback(_attack)
    sequence.tween_interval(1.5)
    sequence.tween_callback(func(): _say("Vitória-Régia\nVocê está a salvo. A Cuca se esconde em uma caverna além deste rio. Siga pela margem até encontrar a entrada.\n\n[Enter / Espaço para continuar]"))
    sequence.tween_callback(_finish)

func _say(text: String) -> void:
    phase = "dialogue"
    if text.begins_with("Vitória-Régia"):
        dialogue.begin("vitoria", "Vitória-Régia", ["Você está a salvo.", "A Cuca se esconde em uma caverna além deste rio. Siga pela margem até encontrar a entrada."])
    else:
        dialogue.begin("vitoria", "", [text])
    waiting = true
    dialogue_opened = Time.get_ticks_msec()
    sequence.pause()

func _unhandled_input(event: InputEvent) -> void:
    if waiting and Time.get_ticks_msec() - dialogue_opened > 250 and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
        dialogue.advance()
        get_viewport().set_input_as_handled()

func _sink(depth: float) -> void:
    fight._set_submersion(depth)
    fight.veil.color.a = depth * 0.48
    fight.low_pass.cutoff_hz = lerpf(20000.0, 300.0, depth)

func _raise_leaf() -> void:
    phase = "rescue"
    fight.chant.stop()
    fight.player.z_index = 4
    fight.player.sprite.position = fight.player.sprite_base_position
    fight.player.sprite.modulate = Color.WHITE

func _reveal() -> void:
    fight._restore_water_visual()
    fight.player.sprite.play("idle")
    heroine.position = fight.vitoria_leaf.position
    heroine.scale = fight.vitoria_leaf.scale
    heroine.modulate.a = 1.0
    heroine.play("transform")
    fight.vitoria_leaf.hide()
    phase = "reveal"

func _stand() -> void:
    fight.state = fight.State.DEFEATED
    heroine.play("idle")
    fight.vitoria_leaf.show()
    heroine.position = _leaf_seat(1.0)
    fight.player.position = _leaf_seat(-1.0)

func _leaf_seat(side: float) -> Vector2:
    var height: float = heroine.sprite_frames.get_frame_texture("idle", 0).region.size.y
    return fight.vitoria_leaf.position + Vector2(side * height * 0.35, -height * 0.1)

func _attack() -> void:
    phase = "attack"
    heroine.flip_h = false
    heroine.play("dash")
    preload("res://scripts/CombatVFX.gd").spawn(fight.boss, "ring", fight.boss.position, Vector2.LEFT, Color("b7fff0"), 110)
    var strike := create_tween()
    strike.tween_property(heroine, "position", fight.boss.position + Vector2(45, 0), 0.5)
    strike.tween_callback(func():
        fight.boss.hp = 0
        fight.sound_effects.play_effect("hit")
        fight.boss._show_defeat()
        fight.boss.hide()
    )
    strike.tween_callback(func(): heroine.flip_h = true)
    strike.tween_property(heroine, "position", _leaf_seat(1.0), 0.5)
    strike.tween_callback(func():
        heroine.flip_h = false
        heroine.play("idle")
    )

func _finish() -> void:
    phase = "finished"
    fight.veil.color.a = 0.0
    fight.player.get_node("Camera2D").make_current()
    fight.boss_intro_running = false
    fight.iara_defeated()
    queue_free()
