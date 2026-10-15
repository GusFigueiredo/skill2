extends CanvasLayer

# Screen-space rain is independent of camera zoom and stays below the HUD.
var clock := 0.0
var mist: ColorRect
var screen: Control
var drift := Vector2.ZERO

func _ready() -> void:
    name = "RiverWeather"
    layer = 1
    mist = ColorRect.new()
    mist.name = "RainMist"
    mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var fog := ShaderMaterial.new()
    fog.shader = preload("res://shaders/river_weather.gdshader")
    mist.material = fog
    add_child(mist)
    mist.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen = Control.new()
    screen.name = "RainStreaks"
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.draw.connect(_draw_rain)

func _process(delta: float) -> void:
    clock += delta
    var canvas := get_viewport().get_canvas_transform()
    drift = canvas.origin * 0.08
    mist.material.set_shader_parameter("phase", clock)
    mist.material.set_shader_parameter("camera_drift", canvas.origin * 0.00006)
    screen.queue_redraw()

func _draw_rain() -> void:
    var view := screen.size
    if view.x <= 0.0 or view.y <= 0.0:
        return
    var wind := -0.22 + sin(clock * 0.31) * 0.035 + sin(clock * 0.73) * 0.012
    for depth in range(3):
        var count := 92 if depth == 0 else 60 if depth == 1 else 28
        var speed := 250.0 + depth * 170.0
        var length := 12.0 + depth * 9.0
        for index in range(count):
            var seed := float(index + depth * 97)
            var variation := 0.78 + fposmod(seed * 0.61803, 1.0) * 0.39
            var phase := clock * speed * variation + seed * 71.3
            var y := fposmod(phase + drift.y, view.y + 70.0) - 35.0
            var x := fposmod(seed * 139.7 + phase * wind + drift.x, view.x + 100.0) - 50.0
            var alpha := (0.095 + depth * 0.045) * (0.85 + 0.15 * sin(seed * 2.4))
            var drop_length := length * (0.72 + fposmod(seed * 0.38197, 1.0) * 0.54)
            var tail := Vector2(wind * drop_length, drop_length)
            screen.draw_line(Vector2(x, y), Vector2(x, y) + tail, Color(0.64, 0.84, 0.92, alpha), 0.8 + depth * 0.23, true)

