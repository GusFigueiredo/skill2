extends Node2D

const WATER_GLOW := Color("6ddbd8")
const WATER_LIGHT := Color("c1f4eb")
const SONG_GOLD := Color("f4d998")

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
    _draw_river(active)
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
        # The restored hero and shared rescue leaf must stay above the river.
        if not fight.rescue_running or fight.player.sprite.material == fight.submersion_material:
            _draw_drowning(clampf(1.0 - fight.state_timer / fight.DROWNING_SECONDS, 0.0, 1.0))

func _draw_river(active: bool) -> void:
    var opacity := 0.48 if active else 0.22
    # Broken, breathing foam follows the shore instead of a vertical danger line.
    for layer in range(3):
        var shore := PackedVector2Array()
        for index in range(43):
            var y := 345.0 + index * 5.0
            var wave := sin(y * 0.065 + clock * 1.8) * 3.0 + sin(y * 0.12 - clock) * 1.5
            shore.append(Vector2(fight.WATER_EDGE + layer * 5.0 + wave, y))
        draw_polyline(shore, Color(WATER_GLOW, opacity * (0.42 - layer * 0.1)), 2.0, true)
    for index in range(14):
        var y := 351.0 + index * 14.4
        var x: float = fight.WATER_EDGE + 4.0 + sin(y * 0.065 + clock * 1.8) * 3.0
        var brightness := 0.5 + sin(clock * 1.6 + index * 1.7) * 0.5
        draw_line(Vector2(x, y), Vector2(x + 1.5, y + 3.0 + brightness * 4.0), Color(WATER_LIGHT, opacity * brightness), 1.2, true)
    draw_set_transform(fight.WATER_POSITION + Vector2(0, 8), 0.0, Vector2(1.0, 0.28))
    for index in range(6):
        var phase := fposmod(clock * 0.18 + index / 6.0, 1.0)
        var angle := index * 0.8 + sin(clock * 0.5) * 0.18
        draw_arc(Vector2.ZERO, 32.0 + phase * 155.0, angle, angle + PI * 1.3, 48, Color(WATER_GLOW, opacity * (1.0 - phase) * 0.5), 1.2, true)
    draw_set_transform(Vector2.ZERO)
    # Small surface glints remain subtle enough to read actors and attacks.
    for index in range(18):
        var phase := fposmod(clock * 0.32 + index * 0.618, 1.0)
        var point := Vector2(fight.WATER_EDGE + 25.0 + fposmod(index * 71.0, 395.0), 356.0 + fposmod(index * 37.0, 188.0))
        point.x += sin(clock * 0.8 + index) * 4.0
        var alpha := sin(phase * PI) * opacity * 0.42
        draw_line(point - Vector2(2.0, 0), point + Vector2(3.0 + phase * 5.0, 0), Color(WATER_LIGHT, alpha), 1.0, true)

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
        draw_colored_polygon(pool, Color(0.025, 0.15, 0.21, opacity * (0.12 + depth * 0.12)))
        draw_polyline(surface, Color(WATER_LIGHT, opacity * (0.4 - layer * 0.1)), 1.2, true)
    draw_set_transform(Vector2(center.x, surface_y + 10.0), 0.0, Vector2(1.0, 0.24))
    for index in range(4):
        var phase := fposmod(clock * 0.8 + index * 0.25, 1.0)
        draw_arc(Vector2.ZERO, 20.0 + phase * 55.0, 0.0, TAU, 48, Color(WATER_GLOW, opacity * (1.0 - phase) * 0.4), 1.3, true)
    draw_set_transform(Vector2.ZERO)
    for index in range(12):
        var phase := fposmod(clock * 0.55 + index * 0.0833, 1.0)
        var point := Vector2(center.x + sin(index * 2.4 + clock * 1.4) * 27.0 + sin(phase * TAU) * 4.0, surface_y + 28.0 - phase * 62.0)
        var radius := 1.5 + index % 3
        var alpha := opacity * sin(phase * PI) * (0.25 + depth * 0.5)
        draw_arc(point, radius, 0.0, TAU, 12, Color(WATER_GLOW, alpha), 1.0, true)
        draw_arc(point, radius, -PI * 0.85, -PI * 0.2, 8, Color(WATER_LIGHT, alpha * 0.9), 1.0, true)

func _draw_charge(charge: float) -> void:
    var center: Vector2 = fight.boss.position + Vector2(-40, -100)
    var pulse := 0.75 + sin(clock * 6.0) * 0.25
    for ring in range(4, 0, -1):
        draw_circle(center, ring * (7.0 + charge * 8.0), Color(WATER_GLOW, charge * 0.02 * pulse))
    for index in range(3):
        var swirl := PackedVector2Array()
        for segment in range(37):
            var phase := segment / 36.0
            var angle := phase * TAU * 0.8 + index * TAU / 3.0 - clock * (1.4 + charge)
            var radius := (10.0 + phase * (35.0 + index * 6.0)) * (0.6 + charge * 0.4)
            swirl.append(center + Vector2.from_angle(angle) * Vector2(radius, radius * 0.8))
        draw_polyline(swirl, Color(WATER_GLOW, charge * 0.12), 6.0, true)
        draw_polyline(swirl, Color(WATER_LIGHT, charge * 0.6), 1.4, true)
        var tip: Vector2 = swirl[swirl.size() - 1]
        draw_circle(tip, 2.0 + charge, Color(SONG_GOLD, charge * 0.85))
        var angle := clock * 1.2 + index * TAU / 3.0
        draw_arc(center, 15.0 + index * 11.0 + charge * 12.0, angle, angle + PI * 0.65, 24, Color(SONG_GOLD, charge * 0.5), 1.1, true)
    for index in range(20):
        var phase := index * 2.399 + clock * 2.0
        var distance := 12.0 + fposmod(index * 17.0 - clock * 35.0, 72.0) * charge
        var point := center + Vector2.from_angle(phase) * Vector2(distance, distance * 0.8)
        var tint := WATER_LIGHT if index % 4 != 0 else SONG_GOLD
        draw_circle(point, 0.9 + index % 3 * 0.4, Color(tint, charge * 0.75))
    draw_set_transform(fight.boss.position, 0, Vector2(1, 0.28))
    draw_arc(Vector2.ZERO, 60.0 + charge * 35.0, 0, TAU, 64, Color(WATER_GLOW, charge * 0.3), 2.0, true)
    draw_arc(Vector2.ZERO, 47.0 + charge * 25.0, clock, clock + PI * 1.3, 48, Color(SONG_GOLD, charge * 0.28), 1.2, true)
    draw_set_transform(Vector2.ZERO)
    for index in range(4):
        var phase := fposmod(clock * 0.55 + index / 4.0, 1.0)
        var point := center + Vector2(sin(clock * 1.5 + index) * 23.0, -10.0 - phase * 60.0)
        var size := Vector2(22, 24) * (0.65 + charge * 0.3)
        draw_texture_rect(preparation_heart, Rect2(point - size * 0.5, size), false, Color(WATER_LIGHT, charge * sin(phase * PI) * 0.85))

func _draw_launch(progress: float) -> void:
    var source: Vector2 = fight.boss.position + Vector2(-40, -100)
    var target: Vector2 = fight.player.position + Vector2(0, fight.player.combat_bounds.get_center().y)
    progress = clampf(progress, 0.0, 1.0)
    var point := _spell_point(source, target, progress)
    var ribbon := PackedVector2Array()
    for index in range(33):
        var phase := lerpf(maxf(0.0, progress - 0.45), progress, index / 32.0)
        var ripple := sin(phase * TAU * 3.0 - clock * 8.0) * sin(phase * PI) * 5.0
        ribbon.append(_spell_point(source, target, phase) + Vector2(0, ripple))
    draw_polyline(ribbon, Color(WATER_GLOW, 0.1), 13.0, true)
    draw_polyline(ribbon, Color(WATER_GLOW, 0.5), 3.5, true)
    draw_polyline(ribbon, Color(WATER_LIGHT, 0.75), 1.2, true)
    for index in range(12):
        var phase := maxf(0.0, progress - index * 0.035)
        var tail := _spell_point(source, target, phase)
        var angle := clock * 8.0 + index * 1.3
        tail += Vector2(cos(angle) * 6.0, sin(angle) * 9.0)
        var fade := 1.0 - index / 12.0
        draw_circle(tail, 1.2 + fade * 1.3, Color(SONG_GOLD if index % 3 == 0 else WATER_LIGHT, fade * 0.75))
    draw_circle(point, 21.0, Color(WATER_GLOW, 0.07))
    for index in range(3):
        var angle := clock * 5.0 + index * TAU / 3.0
        draw_arc(point, 12.0 + index * 5.0, angle, angle + PI * 0.9, 24, Color(WATER_LIGHT if index != 1 else SONG_GOLD, 0.7 - index * 0.16), 1.5, true)
    _heart(point, 9.0, Color(WATER_LIGHT, 0.95))
    _heart(point + Vector2(-2, -2), 4.0, Color(SONG_GOLD, 0.65))
    draw_arc(source, 26.0 + progress * 65.0, 0, TAU, 48, Color(WATER_GLOW, (1.0 - progress) * 0.35), 1.5, true)

func _spell_point(source: Vector2, target: Vector2, progress: float) -> Vector2:
    # The arc reaches the same target at the same cast timer as the original spell.
    var midpoint := source.lerp(target, 0.5) + Vector2(0, -42)
    return source.lerp(midpoint, progress).lerp(midpoint.lerp(target, progress), progress)

func _draw_trance() -> void:
    var hero = fight.player
    var center: Vector2 = hero.position + Vector2(0, hero.combat_bounds.get_center().y)
    var urgency: float = clampf(1.0 - fight.state_timer / fight.TRANSE_SECONDS, 0.0, 1.0)
    var pulse := 0.5 + sin(clock * (5.0 + urgency * 5.0)) * 0.5
    for ring in range(4, 0, -1):
        draw_circle(center, 15.0 + ring * 9.0, Color(WATER_GLOW, 0.014 + pulse * 0.006))
    for strand in range(2):
        var spiral := PackedVector2Array()
        for index in range(65):
            var progress := index / 64.0
            var angle := progress * TAU * 2.0 - clock * 2.5 + strand * PI
            spiral.append(center + Vector2(cos(angle) * (14.0 + progress * 17.0), -42.0 + progress * 85.0 + sin(angle) * 5.0))
        draw_polyline(spiral, Color(WATER_GLOW, 0.075 + pulse * 0.025), 4.0, true)
        draw_polyline(spiral, Color(WATER_LIGHT if strand == 0 else SONG_GOLD, 0.26 + pulse * 0.15), 1.1, true)
    for index in range(6):
        var phase := clock * 1.6 + index * TAU / 6.0
        var point := center + Vector2(cos(phase) * 31.0, sin(phase) * 10.0 - 35.0)
        _heart(point, 3.0, Color(WATER_LIGHT, 0.3 + 0.2 * sin(phase + clock)))
    for index in range(8):
        var phase := fposmod(clock * 0.55 + index / 8.0, 1.0)
        var point := center + Vector2(sin(index * 2.4 + clock) * 35.0, 24.0 - phase * 76.0)
        draw_circle(point, 1.1, Color(SONG_GOLD, sin(phase * PI) * 0.55))
    draw_set_transform(hero.position, 0, Vector2(1, 0.25))
    draw_arc(Vector2.ZERO, 30 + pulse * 7, clock, clock + TAU * 0.8, 48, Color(WATER_GLOW, 0.4), 1.5, true)
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
