extends AnimatedSprite2D

# Visual state follows gameplay; animation never changes damage or movement.
@export_enum("player", "enemy", "boitata") var character: String = "player"
var hurt_timer: float = 0.0
var action_timer: float = 0.0
var previous_hp: int = -1
var previous_fireball_timer: float = 0.0

func _ready() -> void:
	sprite_frames = load("res://sprites/characters/%s.tres" % character)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play("idle")
	previous_hp = get_parent().hp
	if character == "boitata":
		previous_fireball_timer = get_parent().fireball_timer

func _process(delta: float) -> void:
	var actor = get_parent()
	hurt_timer = maxf(0.0, hurt_timer - delta)
	action_timer = maxf(0.0, action_timer - delta)
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
		elif actor.attack_cooldown_timer > actor.attack_cooldown - 0.4:
			next = "attack"
		elif actor.jump_height > 0.0:
			next = "jump"
		elif actor.velocity.length_squared() > 1.0:
			next = "walk"
	elif character == "enemy":
		flip_h = actor.direction < 0
		if actor.hp <= 0:
			next = "death"
		elif hurt_timer > 0.0:
			next = "hurt"
		elif actor.attack_pending or actor.recovery_timer > 0.15:
			next = "attack"
		elif actor.velocity.length_squared() > 1.0:
			next = "walk"
	else:
		flip_h = actor.direction < 0
		if actor.fireball_timer > previous_fireball_timer + 0.5:
			action_timer = 0.4
		previous_fireball_timer = actor.fireball_timer
		match actor.state:
			actor.State.WINDUP: next = "windup"
			actor.State.CHARGE: next = "dash"
			actor.State.MINOR_ATTACK: next = "tail" if actor.minor_kind == "tail" else "bite"
			actor.State.PURSUIT:
				next = "walk" if actor.velocity.length_squared() > 1.0 else "idle"
		if action_timer > 0.0:
			next = "fireball"
	if animation != next:
		play(next)
