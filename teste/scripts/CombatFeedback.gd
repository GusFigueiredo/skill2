extends Node

var frozen_visuals: Array[Dictionary] = []
var shake_remaining := 0.0
var shake_strength := 0.0
var shake_clock := 0.0
var impact_cooldown := 0.0
var camera: Camera2D
var camera_base := Vector2.ZERO
var sound := preload("res://scripts/SoundEffects.gd").new()

func _ready() -> void:
    name = "CombatFeedback"
    add_child(sound)
    sound.setup({"hit": "res://soundeffect/Feedback/hit.wav", "evade": "res://soundeffect/Feedback/evade.wav"}, {"hit": -6.0, "evade": -12.0})

func hit(actor: Node2D) -> void:
    var level = get_parent()
    if level.finished or level.boss_intro_running or get_tree().paused:
        return
    var hero = level.get_node("Player")
    if not actor.is_in_group("player"):
        if impact_cooldown <= 0:
            sound.play_effect("hit")
            impact_cooldown = 0.04
        if not hero.is_dodging:
            _freeze(hero.get_node("Sprite"))
    _freeze(actor.get_node("Sprite"))
    if camera == null:
        camera = hero.get_node("Camera2D")
        camera_base = camera.offset
    shake_remaining = 0.12
    shake_strength = maxf(shake_strength, 2.2 if actor.is_in_group("player") else 1.3)

func evaded(hero: Node2D) -> void:
    var level = get_parent()
    if level.finished or level.boss_intro_running or get_tree().paused:
        return
    sound.play_effect("evade")
    preload("res://scripts/CombatVFX.gd").spawn(hero, "ring", hero.global_position, Vector2.RIGHT, Color("a1f1dc"), 36.0)

func _freeze(visual: AnimatedSprite2D) -> void:
    if not visual.is_processing():
        return
    for entry in frozen_visuals:
        if entry["visual"] == visual:
            entry["remaining"] = 0.055
            return
    frozen_visuals.append({"visual": visual, "remaining": 0.055, "speed": visual.speed_scale})
    visual.speed_scale = 0.0

func _process(delta: float) -> void:
    impact_cooldown = maxf(0, impact_cooldown - delta)
    var level = get_parent()
    var cinematic: bool = level.finished or level.boss_intro_running
    for index in range(frozen_visuals.size() - 1, -1, -1):
        var entry: Dictionary = frozen_visuals[index]
        entry["remaining"] -= delta
        if not is_instance_valid(entry["visual"]):
            frozen_visuals.remove_at(index)
        elif cinematic or entry["remaining"] <= 0:
            entry["visual"].speed_scale = entry["speed"]
            frozen_visuals.remove_at(index)
    if is_instance_valid(camera):
        shake_remaining = maxf(0, shake_remaining - delta)
        shake_clock += delta
        if cinematic or shake_remaining <= 0:
            camera.offset = camera_base
            shake_strength = 0
            camera = null
        else:
            camera.offset = camera_base + Vector2(sin(shake_clock * 125), cos(shake_clock * 93)) * shake_strength * shake_remaining / 0.12

func _exit_tree() -> void:
    for entry in frozen_visuals:
        if is_instance_valid(entry["visual"]):
            entry["visual"].speed_scale = entry["speed"]
    if is_instance_valid(camera):
        camera.offset = camera_base
