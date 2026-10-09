extends AnimatedSprite2D

const PREPARATION_FINISH_SECONDS := 0.15
const CASTING_IDLE_SECONDS := 0.1

var flash_timer := 0.0
var previous_state := -1
var casting_elapsed := 0.0

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
    var state: int = fight.state
    if state != previous_state:
        previous_state = state
        if state == fight.State.CASTING:
            casting_elapsed = 0.0

    # Her fallen tail spans the bank; keep the approaching hero visible above it.
    z_index = -1 if state in [fight.State.FALLING, fight.State.MINIONS, fight.State.VULNERABLE] else 0
    match state:
        fight.State.PREPARING:
            _play_if_changed("preparation_finish" if fight.state_timer <= PREPARATION_FINISH_SECONDS else "preparation")
        fight.State.CASTING:
            casting_elapsed += delta
            if casting_elapsed < CASTING_IDLE_SECONDS:
                _hold_idle_first_frame()
            else:
                _play_if_changed("attack")
        fight.State.SEDUCING:
            # Finish drawing the spell before alternating its final two poses.
            if animation != "attack" or not is_playing():
                _play_if_changed("attack_loop")
        fight.State.FALLING:
            _play_if_changed("fall")
        fight.State.MINIONS, fight.State.VULNERABLE:
            if animation != "fall" or frame != sprite_frames.get_frame_count("fall") - 1 or is_playing():
                play("fall")
                set_frame_and_progress(sprite_frames.get_frame_count("fall") - 1, 0.0)
                pause()
        fight.State.DEFEATED:
            _play_if_changed("death")
        _:
            _play_if_changed("idle")

func _play_if_changed(animation_name: StringName) -> void:
    if animation != animation_name or (sprite_frames.get_animation_loop(animation_name) and not is_playing()):
        play(animation_name)

func _hold_idle_first_frame() -> void:
    if animation != "idle" or frame != 0 or is_playing():
        play("idle")
        set_frame_and_progress(0, 0.0)
        pause()
