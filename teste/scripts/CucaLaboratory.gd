extends Node2D

var level: Node2D
var elapsed := 0.0

func setup(cave: Node2D) -> void:
    level = cave

func _ready() -> void:
    name = "CucaLaboratory"
    z_index = -8
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    # Recessed wood and mineral vessels sit on the cave's rear wall. Their
    # stepped silhouettes retain the pixel scale of the supplied paintings.
    _shelf(Vector2(4390, 302), 168.0)
    _shelf(Vector2(4940, 294), 158.0)
    _shelf(Vector2(4940, 337), 158.0)
    for row in range(3):
        var center := Vector2(4390, 302) if row == 0 else Vector2(4940, 294 + (row - 1) * 43)
        for index in range(6):
            _bottle(center + Vector2(-62 + index * 25, -5), index + row * 7)
    # A stone worktable and open recipe book, away from the combat lane.
    draw_rect(Rect2(4318, 336, 145, 13), Color("37382e"))
    draw_rect(Rect2(4322, 336, 137, 4), Color("62614a"))
    draw_rect(Rect2(4330, 349, 10, 24), Color("292c25"))
    draw_rect(Rect2(4440, 349, 10, 24), Color("292c25"))
    draw_polygon(PackedVector2Array([Vector2(4370, 333), Vector2(4377, 318), Vector2(4395, 321), Vector2(4413, 318), Vector2(4420, 333), Vector2(4395, 336)]), PackedColorArray([Color("aa9c69")]))
    draw_line(Vector2(4395, 322), Vector2(4395, 333), Color("4b4732"), 1)
    for index in range(3):
        draw_line(Vector2(4380, 323 + index * 3), Vector2(4390, 325 + index * 3), Color("665e3e"), 1)
        draw_line(Vector2(4400, 325 + index * 3), Vector2(4410, 323 + index * 3), Color("665e3e"), 1)
    var strength := 0.20 + sin(elapsed * 1.7) * 0.035
    if is_instance_valid(level) and level.get("boss_defeated") == true:
        strength *= 0.25
    draw_set_transform(Vector2(4770, 407), 0.0, Vector2(1, 0.35))
    for index in range(5, 0, -1):
        draw_circle(Vector2.ZERO, 40.0 + index * 14.0, Color(0.27, 0.59, 0.19, strength * 0.035))
    draw_arc(Vector2.ZERO, 83, 0, TAU, 64, Color(0.66, 0.82, 0.37, strength), 1.5, true)
    draw_arc(Vector2.ZERO, 70, 0, TAU, 64, Color(0.51, 0.75, 0.31, strength * 0.65), 1.0, true)
    for index in range(8):
        var angle := index * TAU / 8.0
        var radial := Vector2.from_angle(angle)
        var tangent := radial.orthogonal()
        var point := radial * 77
        draw_line(point - tangent * 4, point + tangent * 4, Color(0.71, 0.83, 0.43, strength), 1.4)
        draw_line(point, point + radial * 7, Color(0.71, 0.83, 0.43, strength), 1.4)
    draw_set_transform(Vector2.ZERO)
    for index in range(20):
        var progress := fposmod(elapsed * 0.14 + index * 0.618, 1.0)
        var point := Vector2(4770 + sin(index * 2.4 + progress * 2) * 62, 396 - progress * 100)
        draw_rect(Rect2(point.floor(), Vector2.ONE), Color(0.66, 0.94, 0.34, sin(progress * PI) * strength * 1.4))

func _shelf(center: Vector2, width: float) -> void:
    draw_rect(Rect2(center - Vector2(width * 0.5, 3), Vector2(width, 8)), Color("251e19"))
    draw_rect(Rect2(center - Vector2(width * 0.5, 3), Vector2(width, 2)), Color("796343"))
    draw_rect(Rect2(center + Vector2(-width * 0.37, 5), Vector2(5, 12)), Color("34291f"))
    draw_rect(Rect2(center + Vector2(width * 0.34, 5), Vector2(5, 12)), Color("34291f"))

func _bottle(base: Vector2, seed_index: int) -> void:
    var palette := [Color("587f44"), Color("616a95"), Color("9a8251"), Color("548c80")]
    var color: Color = palette[seed_index % palette.size()]
    var height := 16 + seed_index % 3 * 4
    var width := 10 + seed_index % 2 * 3
    var top := base - Vector2(0, height)
    draw_rect(Rect2(top + Vector2(-2, -4), Vector2(4, 4)), Color("ae9461"))
    draw_rect(Rect2(top + Vector2(-2, 0), Vector2(4, 5)), color.darkened(0.20))
    draw_rect(Rect2(top + Vector2(-width * 0.5 + 2, 5), Vector2(width - 4, 3)), color.darkened(0.25))
    draw_rect(Rect2(top + Vector2(-width * 0.5, 8), Vector2(width, height - 8)), color.darkened(0.36))
    draw_rect(Rect2(base - Vector2(width * 0.5 - 1, 7), Vector2(width - 2, 5)), color)
    draw_rect(Rect2(top + Vector2(-width * 0.5 + 2, 9), Vector2(2, 5)), color.lightened(0.30))
