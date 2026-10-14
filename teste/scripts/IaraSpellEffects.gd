extends Node2D

var fight: Node2D
var clock := 0.0
var death_elapsed := 0.0
var preparation_heart: AtlasTexture = preload("res://scripts/IaraFrames.gd").preparation_heart()

func _ready() -> void:
    z_index = 4
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
    clock += delta
    if fight.player.hp <= 0:
        death_elapsed += delta
    queue_redraw()

func _draw() -> void:
    if not fight.boss_area_entered:
        return
    var active: bool = fight._water_is_active()
    var river := Color(0.2, 0.85, 0.95, 0.5 if active else 0.15)
    draw_line(Vector2(fight.WATER_EDGE, 345), Vector2(fight.WATER_EDGE, 555), river, 2.0)
    for index in range(5):
        var radius := 25.0 + fposmod(clock * 35.0 + index * 28.0, 140.0)
        draw_set_transform(fight.WATER_POSITION, 0, Vector2(1.0, 0.3))
        draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(river, river.a * (1.0 - radius / 180.0)), 1.5)
    draw_set_transform(Vector2.ZERO)
    if fight.finished:
        return
    if fight.player.hp <= 0:
        if fight.state == fight.State.DROWNING and death_elapsed < fight.CORPSE_SINK_SECONDS:
            _draw_drowning(1.0, 1.0 - death_elapsed / fight.CORPSE_SINK_SECONDS)
        return
    if fight.water_exposure > 0.0 and fight.state != fight.State.DROWNING:
        _draw_water_warning(clampf(fight.water_exposure / fight.DROWNING_SECONDS, 0.0, 1.0))
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
        _draw_drowning(clampf(1.0 - fight.state_timer / fight.DROWNING_SECONDS, 0.0, 1.0))

func _draw_water_warning(progress: float) -> void:
    _draw_drowning(progress, 0.55)
    var center: Vector2 = fight.player.position
    draw_set_transform(center, 0.0, Vector2(1.0, 0.3))
    for index in range(3):
        var phase := fposmod(clock * 0.7 + index / 3.0, 1.0)
        draw_arc(Vector2.ZERO, 18.0 + phase * 42.0, 0.0, TAU, 48, Color(0.45, 0.85, 0.9, (1.0 - phase) * (0.15 + progress * 0.4)), 1.5)
    # A diminishing ring communicates the remaining chance to return to shore.
    draw_arc(Vector2.ZERO, 24.0, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, 1.0 - progress), 48, Color(0.95, 0.75, 0.4, 0.35 + progress * 0.5), 2.0)
    draw_set_transform(Vector2.ZERO)

func _draw_drowning(progress: float, opacity: float = 1.0) -> void:
    var center: Vector2 = fight.player.position
    var depth := smoothstep(0.0, 1.0, progress)
    var surface_y: float = fight.water_surface.y
    # Layered curved water avoids a rectangular overlay across the character.
    for layer in range(3):
        var surface := PackedVector2Array()
        var width := 48.0 + layer * 10.0
        for index in range(25):
            var phase := index / 24.0
            var x := lerpf(-width, width, phase)
            var wave := sin(x * 0.09 + clock * 3.0 + layer) * 2.0
            surface.append(Vector2(center.x + x, surface_y + layer * 5.0 + wave + pow(absf(x) / width, 3.0) * 18.0))
        var pool := surface.duplicate()
        pool.append(Vector2(center.x + width, center.y + 40.0))
        pool.append(Vector2(center.x - width, center.y + 40.0))
        draw_colored_polygon(pool, Color(0.035, 0.23, 0.3, opacity * (0.12 + depth * 0.12)))
        draw_polyline(surface, Color(0.45, 0.8, 0.85, opacity * (0.4 - layer * 0.1)), 1.2, true)
    draw_set_transform(Vector2(center.x, surface_y + 10.0), 0.0, Vector2(1.0, 0.24))
    for index in range(4):
        var phase := fposmod(clock * 0.8 + index * 0.25, 1.0)
        draw_arc(Vector2.ZERO, 20.0 + phase * 55.0, 0.0, TAU, 48, Color(0.55, 0.9, 0.92, opacity * (1.0 - phase) * 0.4), 1.3)
    draw_set_transform(Vector2.ZERO)
    for index in range(12):
        var phase := fposmod(clock * 0.55 + index * 0.0833, 1.0)
        var point := Vector2(center.x + sin(index * 2.4 + clock) * 27.0, surface_y + 28.0 - phase * 62.0)
        draw_arc(point, 1.5 + index % 3, 0.0, TAU, 12, Color(0.65, 0.9, 0.95, opacity * sin(phase * PI) * (0.25 + depth * 0.5)), 1.0)

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
    for index in range(6):
        var phase := fposmod(clock * 0.65 + index / 6.0, 1.0)
        var point := center + Vector2(sin(clock * 2.0 + index) * 28.0, -12.0 - phase * 65.0)
        var size := Vector2(26, 28) * (0.8 + charge * 0.4)
        draw_texture_rect(preparation_heart, Rect2(point - size * 0.5, size), false, Color(1, 1, 1, charge * sin(phase * PI)))

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
    var urgency: float = clampf(1.0 - fight.state_timer / fight.TRANSE_SECONDS, 0.0, 1.0)
    var pulse := 0.5 + sin(clock * (5.0 + urgency * 5.0)) * 0.5
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
    var warning := Color(0.65, 1.0, 0.9).lerp(Color(1.0, 0.35, 0.25), urgency)
    warning.a = 0.55 + pulse * 0.25
    draw_arc(Vector2.ZERO, 43.0, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, 1.0 - urgency), 64, warning, 2.5, true)
    draw_set_transform(Vector2.ZERO)

func _heart(center: Vector2, radius: float, color: Color) -> void:
    var outline := PackedVector2Array()
    for index in range(24):
        var angle := index * TAU / 24.0
        outline.append(center + Vector2(16 * pow(sin(angle), 3), -(13 * cos(angle) - 5 * cos(2 * angle) - 2 * cos(3 * angle) - cos(4 * angle))) * radius / 16.0)
    draw_colored_polygon(outline, color)
