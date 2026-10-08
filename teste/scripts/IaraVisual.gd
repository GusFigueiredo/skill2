extends AnimatedSprite2D

var flash_timer := 0.0

func _ready() -> void:
    sprite_frames = preload("res://scripts/IaraFrames.gd").build()
    material = ShaderMaterial.new()
    material.shader = preload("res://shaders/damage_flash.gdshader")
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    play("idle")

func flash_damage() -> void:
    flash_timer = 0.18

func _process(delta: float) -> void:
    flash_timer = maxf(0.0, flash_timer - delta)
    material.set_shader_parameter("flash", flash_timer / 0.18)
    var fight = get_parent().get_parent()
    # Her fallen tail spans the bank; keep the approaching hero visible above it.
    z_index = -1 if fight.state in [fight.State.FALLING, fight.State.MINIONS, fight.State.VULNERABLE] else 0
    var next := "idle"
    match fight.state:
        fight.State.PREPARING, fight.State.CASTING, fight.State.SEDUCING: next = "seduction"
        fight.State.FALLING, fight.State.MINIONS, fight.State.VULNERABLE: next = "fall"
        fight.State.DEFEATED: next = "death"
    if animation != next:
        play(next)
    if fight.state in [fight.State.MINIONS, fight.State.VULNERABLE]:
        set_frame_and_progress(sprite_frames.get_frame_count("fall") - 1, 0.0)
        pause()
