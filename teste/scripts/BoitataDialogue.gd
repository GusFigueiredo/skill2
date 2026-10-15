extends Node

const DIALOGUE_DELAY_SECONDS := 2.0

const LINES := [
    ["boitata", "Além de devastarem minha floresta, vocês ainda tentam me derrotar? Pois saibam: mesmo que tenham vencido esta batalha, a força da floresta não vai deixar vocês avançarem!"],
    ["player", "Como assim, “vocês”? Eu não estou entendendo. O que está acontecendo?"],
    ["boitata", "Ué... você não é um dos monstros enviados pela Cuca?"],
    ["player", "Não. Eu vi que a cidade estava sendo atacada, então vim tentar ajudar. Mas ainda não sei quem está por trás disso."],
    ["boitata", "É a Cuca, ela é uma bruxa que vive tramando planos para aterrorizar todos. Mas, desta vez... parece que é algo muito mais sério."],
    ["boitata", "Sei que a caverna dela fica depois do Rio Negro. Mas tome cuidado: há um monstro perigoso por lá."],
    ["player", "Entendi. Próxima vez pergunte antes de atacar."],
]

var fight: Node2D
var dialogue: Control
var line_index := 0
var camera: Camera2D
var opening_tween: Tween
var boss_visual: AnimatedSprite2D
var rest_elapsed := 0.0
var visual_base_position := Vector2.ZERO
var visual_base_scale := Vector2.ONE
var tired_color := Color.WHITE
var lean_direction := 1.0
var resting_base_color := Color.WHITE

func start(level: Node2D, boss: CharacterBody2D) -> void:
    name = "BoitataDialogue"
    fight = level
    fight.boss_intro_running = true
    var feedback := fight.get_node_or_null("CombatFeedback")
    if feedback != null:
        feedback._process(0.0)
    fight.get_node("HUD").hide()
    fight.player._end_dodge()
    fight.player.control_locked = true
    fight.player.velocity = Vector2.ZERO
    fight.player.set_physics_process(false)
    fight.player.sprite.set_process(false)
    fight.player.sprite.position = fight.player.sprite_base_position
    fight.player.sprite.play("idle")
    boss.velocity = Vector2.ZERO
    boss.state = boss.State.PURSUIT
    boss.set_physics_process(false)
    boss.collision_layer = 0
    boss.collision_mask = 0
    boss.get_node("HurtArea").collision_layer = 0
    var visual := boss.get_node("Sprite") as AnimatedSprite2D
    boss_visual = visual
    visual_base_position = visual.position
    visual_base_scale = visual.scale
    lean_direction = -1.0 if visual.flip_h else 1.0
    tired_color = boss.body_color * Color(0.72, 0.67, 0.62, 1.0)
    resting_base_color = boss.body_color
    visual.set_process(false)
    visual.modulate = resting_base_color
    visual.speed_scale = 0.55
    if visual.material is ShaderMaterial:
        visual.material.set_shader_parameter("flash", 0.0)
    visual.play("idle")
    boss.queue_redraw()
    for child in fight.get_children():
        if child.get_script() in [preload("res://scripts/Fireball.gd"), preload("res://scripts/FlameTrail.gd")]:
            child.queue_free()
    var gameplay_camera := fight.player.get_node("Camera2D") as Camera2D
    gameplay_camera.force_update_scroll()
    var gameplay_center := gameplay_camera.get_screen_center_position()
    camera = Camera2D.new()
    camera.zoom = gameplay_camera.zoom
    camera.limit_left = gameplay_camera.limit_left
    camera.limit_top = gameplay_camera.limit_top
    camera.limit_right = gameplay_camera.limit_right
    camera.limit_bottom = gameplay_camera.limit_bottom
    add_child(camera)
    camera.global_position = gameplay_center
    camera.make_current()
    camera.force_update_scroll()
    var ui := CanvasLayer.new()
    ui.layer = 5
    add_child(ui)
    dialogue = preload("res://scripts/DialogueBox.gd").new()
    ui.add_child(dialogue)
    dialogue.completed.connect(_next_line)
    opening_tween = create_tween()
    opening_tween.tween_interval(DIALOGUE_DELAY_SECONDS)
    opening_tween.tween_callback(_show_line)

func _process(delta: float) -> void:
    if not is_instance_valid(boss_visual):
        return
    rest_elapsed += delta
    var breath := sin(rest_elapsed * 2.2)
    var settle := smoothstep(0.0, 0.7, rest_elapsed)
    boss_visual.position = visual_base_position + Vector2(0, 4.0 + breath * 1.4) * settle
    boss_visual.rotation = lean_direction * (0.025 + breath * 0.006) * settle
    boss_visual.modulate = resting_base_color.lerp(tired_color.lightened((breath + 1.0) * 0.015), settle)

func _show_line() -> void:
    dialogue.begin(LINES[line_index][0], "", [LINES[line_index][1]])

func _next_line() -> void:
    line_index += 1
    if line_index < LINES.size():
        _show_line()
        return
    fight.player.get_node("Camera2D").make_current()
    fight.boss_intro_running = false
    fight.finished = true
    preload("res://scripts/CampaignProgress.gd").complete_stage(fight.stage_index)
    fight.get_node("/root/SceneTransition").complete_level(fight, fight.next_stage_path)
    queue_free()
