extends Node2D

var clock := 0.0
var level: Node2D
var shore_edge := INF

func _ready() -> void:
    name = "RiverRainGround"
    level = get_parent()
    z_index = 0
    if level.stage_index == 3:
        shore_edge = level.WATER_EDGE

func _process(delta: float) -> void:
    clock += delta
    queue_redraw()

func _on_ground(point: Vector2) -> bool:
    if point.x >= shore_edge:
        return false
    for pit: Rect2 in level.pits:
        if pit.grow(12.0).has_point(point):
            return false
    return true

func _draw() -> void:
    var view := get_viewport_rect()
    var inverse := get_canvas_transform().affine_inverse()
    var left := (inverse * view.position).x - 70.0
    var right := (inverse * view.end).x + 70.0
    # Ground splashes stay at fixed world locations instead of following the camera.
    for index in range(180):
        var x := 45.0 + fposmod(index * 197.3, 4300.0)
        var y := 348.0 + fposmod(index * 53.7, 192.0)
        var point := Vector2(x, y)
        if x < left or x > right or not _on_ground(point):
            continue
        var phase := fposmod(clock * (0.85 + index % 4 * 0.12) + index * 0.618, 1.0)
        if phase > 0.65:
            continue
        var radius := 1.0 + phase * (6.5 + index % 5 * 0.7)
        var opacity := (1.0 - phase / 0.65) * (0.17 + index % 3 * 0.022)
        draw_set_transform(point, 0.0, Vector2(1.0, 0.32))
        draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, Color(0.56, 0.81, 0.84, opacity), 0.7, true)
        draw_set_transform(Vector2.ZERO)
        if phase < 0.18:
            draw_line(point + Vector2(-1.5, 0), point + Vector2(-3.5, -3.0 - phase * 5.0), Color(0.75, 0.91, 0.93, opacity * 0.7), 0.7, true)
            draw_line(point + Vector2(1.5, 0), point + Vector2(3.5, -2.0 - phase * 4.0), Color(0.75, 0.91, 0.93, opacity * 0.7), 0.7, true)
    # Thin, broken highlights suggest wet ground without covering the floor art.
    for index in range(46):
        var point := Vector2(80.0 + index * 93.7, 360.0 + fposmod(index * 43.3, 170.0))
        if point.x < left or point.x > right or not _on_ground(point):
            continue
        var shimmer := 0.035 + (0.5 + sin(clock * 0.85 + index * 1.71) * 0.5) * 0.035
        var half_width := 5.0 + fposmod(index * 7.13, 8.0)
        draw_line(point - Vector2(half_width, 0), point + Vector2(half_width + 3.0, 0), Color(0.4, 0.69, 0.76, shimmer), 1.0, true)
        draw_line(point + Vector2(-half_width * 0.4, 2), point + Vector2(half_width * 0.6, 2), Color(0.7, 0.88, 0.9, shimmer * 0.75), 0.8, true)
