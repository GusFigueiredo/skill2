extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var boss: CharacterBody2D = $Boss
@onready var enemies: Array[CharacterBody2D] = [$Enemy1, $Enemy2]
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var health_label: Label = $HUD/HealthLabel
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var reset_button: Button = $DeathScreen/CenterContainer/VBoxContainer/ResetButton

func _ready() -> void:
    add_to_group("game_manager")
    if is_instance_valid(boss):
        boss.visible = false
        boss.set_physics_process(false)
    if reset_button:
        reset_button.pressed.connect(_reset_scene)
    death_screen.visible = false
    _update_hud()

func _process(_delta: float) -> void:
    if not is_instance_valid(player) or not player.is_inside_tree():
        return

    _update_hud()

    var remaining_enemies := false
    for enemy in enemies:
        if is_instance_valid(enemy) and enemy.is_inside_tree():
            remaining_enemies = true
            break

    if not remaining_enemies and is_instance_valid(boss) and boss.is_inside_tree():
        boss.visible = true
        boss.set_physics_process(true)

    if is_instance_valid(boss) and boss.is_inside_tree() and boss.hp <= 0:
        boss.visible = false
        boss.set_physics_process(false)

func _update_hud() -> void:
    if not is_instance_valid(player):
        return

    if health_bar:
        health_bar.max_value = player.max_hp
        health_bar.value = clamp(player.hp, 0, player.max_hp)

    if health_label:
        health_label.text = "Vida: %d / %d" % [player.hp, player.max_hp]

func trigger_death() -> void:
    if death_screen:
        death_screen.visible = true

func _reset_scene() -> void:
    get_tree().reload_current_scene()
