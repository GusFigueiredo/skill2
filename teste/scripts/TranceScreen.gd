extends ColorRect

var fight: Node2D
var clock := 0.0
var depth := 0.0
var urgency := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var effect := ShaderMaterial.new()
    effect.shader = preload("res://shaders/trance_screen.gdshader")
    material = effect
    hide()

func _process(delta: float) -> void:
    clock += delta
    var alive: bool = fight.player.hp > 0 and not fight.finished and not fight.boss_intro_running
    var target_urgency := 0.0
    var target_depth := 0.0
    if alive and fight.state == fight.State.SEDUCING:
        target_urgency = 0.3 + 0.7 * clampf(1.0 - fight.state_timer / fight.TRANSE_SECONDS, 0.0, 1.0)
    if alive:
        target_depth = clampf(fight.water_exposure / fight.DROWNING_SECONDS, 0.0, 1.0)
        if fight.state == fight.State.DROWNING:
            target_depth = lerpf(fight.drowning_start_depth, 1.0, clampf(1.0 - fight.state_timer / fight.DROWNING_SECONDS, 0.0, 1.0))
    var blend := 1.0 - exp(-delta * 7.0)
    urgency = lerpf(urgency, target_urgency, blend)
    depth = lerpf(depth, target_depth, blend)
    visible = alive and (urgency > 0.005 or depth > 0.005)
    material.set_shader_parameter("phase", clock)
    material.set_shader_parameter("urgency", urgency)
    material.set_shader_parameter("depth", depth)
