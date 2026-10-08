extends "res://scripts/Enemy.gd"

var sheet_image: Image
var pose_bounds: Dictionary = {}

func _ready() -> void:
    is_boss = true
    spawn_started = true
    spawn_finished = true
    super._ready()
    sheet_image = preload("res://scripts/IaraFrames.gd").SHEET.get_image()
    $Sprite.animation_changed.connect(_update_hurtbox)
    $Sprite.frame_changed.connect(_update_hurtbox)
    _update_hurtbox()

func _update_hurtbox() -> void:
    if sheet_image == null:
        return
    var visual := $Sprite as AnimatedSprite2D
    var key := "%s:%d" % [visual.animation, visual.frame]
    var atlas := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame) as AtlasTexture
    if not pose_bounds.has(key):
        var used := Rect2(sheet_image.get_region(Rect2i(atlas.region)).get_used_rect())
        used.position += atlas.margin.position - Vector2(atlas.get_size()) * 0.5
        pose_bounds[key] = used
    var bounds: Rect2 = pose_bounds[key]
    if visual.flip_h:
        bounds.position.x = -bounds.end.x
    bounds.position = visual.position + bounds.position * visual.scale
    bounds.size *= visual.scale
    combat_bounds = bounds
    var shape := $HurtArea.get_child(0) as CollisionShape2D
    var padded := bounds.grow(5.0)
    (shape.shape as RectangleShape2D).size = padded.size
    shape.position = padded.get_center()

# The fight controller owns Iara's phases; she never pursues or deals contact damage.
func _physics_process(_delta: float) -> void:
    velocity = Vector2.ZERO

func take_damage(amount: int) -> void:
    var fight = get_parent()
    if hp <= 0 or amount <= 0 or fight.state != fight.State.VULNERABLE:
        return
    hp = maxi(0, hp - amount)
    preload("res://scripts/DamageImpact.gd").spawn(self, amount)
    if hp == 0:
        _show_defeat()
        fight.iara_defeated()
        queue_free()
