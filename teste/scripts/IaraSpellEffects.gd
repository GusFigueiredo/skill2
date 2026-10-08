extends Node2D

var fight: Node2D
var clock := 0.0

func _ready() -> void:
    z_index = 4

func _process(delta: float) -> void:
    clock += delta
    queue_redraw()

func _draw() -> void:
    var active: bool = fight._water_is_active()
    var river := Color(0.2, 0.85, 0.95, 0.5 if active else 0.15)
    draw_line(Vector2(fight.WATER_EDGE, 345), Vector2(fight.WATER_EDGE, 555), river, 2.0)
    for index in range(5):
        var radius := 25.0 + fposmod(clock * 35.0 + index * 28.0, 140.0)
        draw_set_transform(fight.WATER_POSITION, 0, Vector2(1.0, 0.3))
        draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(river, river.a * (1.0 - radius / 180.0)), 1.5)
    draw_set_transform(Vector2.ZERO)
    if fight.finished or fight.player.hp <= 0:
        return
    if fight.state == fight.State.PREPARING:
        var progress: float = 1.0 - fight.state_timer / fight.preparation_duration
        # First show the attack pose, then build the visible spell around her hands.
        var charge := clampf((progress - 0.12) / 0.88, 0, 1)
        if charge > 0.0:
            _draw_charge(charge)
    elif fight.state == fight.State.CASTING:
        _draw_launch(1.0 - fight.state_timer / fight.CAST_SECONDS)
    elif fight.state == fight.State.SEDUCING:
        _draw_trance()
    elif fight.state == fight.State.DROWNING:
        var progress: float = 1.0 - fight.state_timer / fight.DROWNING_SECONDS
        var top: float = fight.player.position.y - progress * 105.0
        draw_rect(Rect2(fight.player.position.x - 50, top, 100, fight.player.position.y - top + 20), Color(0.025, 0.16, 0.25, 0.7))
        draw_line(Vector2(fight.player.position.x - 50, top), Vector2(fight.player.position.x + 50, top), Color("7fcbd6"), 2.0)

func _draw_charge(charge: float) -> void:
    var center: Vector2 = fight.boss.position + Vector2(-40, -100)
    for ring in range(4, 0, -1):
        draw_circle(center, ring * (8.0 + charge * 9.0), Color(0.15, 0.95, 0.85, charge * 0.025))
    for index in range(3):
        var radius := 14.0 + charge * 40.0 + index * 12.0
        var angle := clock * (1.0 if index % 2 == 0 else -1.0) + index
        draw_arc(center, radius, angle, angle + TAU * 0.74, 40, Color(0.5, 1.0, 0.85, charge * 0.6), 1.5)
    for index in range(20):
        var phase := index * 2.399 + clock * 2.0
        var distance := 15.0 + fposmod(index * 17.0 - clock * 35.0, 90.0) * charge
        var point := center + Vector2.from_angle(phase) * distance
        draw_circle(point, 1.2 + index % 3 * 0.4, Color(0.45, 1.0, 0.9, charge * 0.8))
    draw_set_transform(fight.boss.position, 0, Vector2(1, 0.28))
    draw_arc(Vector2.ZERO, 60.0 + charge * 35.0, 0, TAU, 64, Color(0.3, 1.0, 0.85, charge * 0.45), 2.0)
    draw_set_transform(Vector2.ZERO)
    _heart(center + Vector2(0, -18), 7.0 + charge * 4.0, Color(0.6, 1, 0.9, charge * 0.9))

func _draw_launch(progress: float) -> void:
    var source: Vector2 = fight.boss.position + Vector2(-40, -100)
    var target: Vector2 = fight.player.position + Vector2(0, fight.player.combat_bounds.get_center().y)
    var point := source.lerp(target, progress)
    for index in range(10):
        var trail := maxf(0, progress - index * 0.04)
        var tail := source.lerp(target, trail)
        draw_circle(tail, maxf(2, 15 - index), Color(0.2, 1.0, 0.8, (1.0 - index / 10.0) * 0.14))
    for index in range(3):
        draw_arc(point, 14 + index * 9, clock * 5.0 + index, clock * 5.0 + index + TAU * 0.8, 32, Color(0.45, 1, 0.85, 0.7 - index * 0.2), 2)
    _heart(point, 11, Color("b0ffe0"))
    draw_arc(source, 35.0 + progress * 100.0, 0, TAU, 48, Color(0.35, 1, 0.85, (1.0 - progress) * 0.5), 2.0)

func _draw_trance() -> void:
    var hero = fight.player
    var center: Vector2 = hero.position + Vector2(0, hero.combat_bounds.get_center().y)
    var pulse := 0.5 + sin(clock * 5.0) * 0.5
    for ring in range(4, 0, -1):
        draw_circle(center, 15.0 + ring * 9.0, Color(0.22, 0.75, 0.8, 0.018 + pulse * 0.008))
    var spiral := PackedVector2Array()
    for index in range(90):
        var progress := index / 89.0
        var angle := progress * TAU * 2.5 - clock * 3.0
        spiral.append(center + Vector2(cos(angle) * (8 + progress * 30), -45 + progress * 85 + sin(angle) * 5))
    draw_polyline(spiral, Color(0.55, 1, 0.9, 0.3 + pulse * 0.15), 1.4, true)
    for index in range(7):
        var phase := clock * 2.0 + index * TAU / 7.0
        var point := center + Vector2(cos(phase) * 34, sin(phase) * 12 - 35)
        _heart(point, 3.3, Color(0.65, 1, 0.9, 0.35 + 0.25 * sin(phase + clock)))
    draw_set_transform(hero.position, 0, Vector2(1, 0.25))
    draw_arc(Vector2.ZERO, 30 + pulse * 7, clock, clock + TAU * 0.8, 48, Color(0.4, 1, 0.9, 0.4), 1.5)
    draw_set_transform(Vector2.ZERO)

func _heart(center: Vector2, radius: float, color: Color) -> void:
    var outline := PackedVector2Array()
    for index in range(24):
        var angle := index * TAU / 24.0
        outline.append(center + Vector2(16 * pow(sin(angle), 3), -(13 * cos(angle) - 5 * cos(2 * angle) - 2 * cos(3 * angle) - cos(4 * angle))) * radius / 16.0)
    draw_colored_polygon(outline, color)
