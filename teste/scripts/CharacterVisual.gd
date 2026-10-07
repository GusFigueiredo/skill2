extends AnimatedSprite2D

# Visual state follows gameplay; animation never changes damage or movement.
@export_enum("player", "enemy", "boitata") var character: String = "player"
var hurt_timer: float = 0.0
var previous_hp: int = -1
var flash_timer: float = 0.0

func flash_damage() -> void:
	flash_timer = 0.18
	hurt_timer = 0.25
	material.set_shader_parameter("flash", 1.0)

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/damage_flash.gdshader")
	sprite_frames = load("res://sprites/characters/%s.tres" % character)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play("idle")
	previous_hp = get_parent().hp

func _process(delta: float) -> void:
	flash_timer = maxf(0.0, flash_timer - delta)
	material.set_shader_parameter("flash", flash_timer / 0.18)
	var actor = get_parent()
	hurt_timer = maxf(0.0, hurt_timer - delta)
	if actor.hp < previous_hp:
		hurt_timer = 0.25
	previous_hp = actor.hp
	var next: String = "idle"
	if character == "player":
		flip_h = actor.facing < 0
		if actor.hp <= 0:
			next = "death"
		elif actor.is_dodging:
			next = "dodge"
		elif hurt_timer > 0.0:
			next = "hurt"
		elif actor.attack_cooldown_timer > actor.attack_cooldown - (sprite_frames.get_frame_count("attack") - 1) / sprite_frames.get_animation_speed("attack"):
			next = "attack"
		elif actor.jump_height > 0.0:
			next = "jump"
		elif actor.velocity.length_squared() > 1.0:
			next = _walk_animation(actor.velocity)
	elif character == "enemy":
		flip_h = actor.direction < 0
		if actor.hp <= 0:
			next = "death"
		elif hurt_timer > 0.0:
			next = "hurt"
		elif actor.attack_pending or actor.recovery_timer > 0.15:
			next = "attack"
		elif actor.velocity.length_squared() > 1.0:
			next = _walk_animation(actor.velocity)
	else:
		flip_h = actor.direction < 0
		match actor.state:
			actor.State.WINDUP: next = "windup"
			actor.State.CHARGE: next = "dash"
			actor.State.MINOR_ATTACK: next = "bite" if actor.minor_kind == "bite" else "idle"
			actor.State.FIREBALL: next = "fireball"
	if animation != next:
		play(next)
	if character == "boitata" and actor.state == actor.State.FIREBALL:
		# Physics owns the attack clock and launch; rendering uses the same clock.
		set_frame_and_progress(mini(2, int(actor.fireball_elapsed * actor.fireball_fps)), 0.0)
		pause()
	elif character == "boitata" and not is_playing():
		play(next)
	if next in ["walk_up", "walk_down"]:
		flip_h = false

func _walk_animation(movement: Vector2) -> String:
	if absf(movement.y) > absf(movement.x):
		return "walk_up" if movement.y < 0.0 else "walk_down"
	return "walk"
