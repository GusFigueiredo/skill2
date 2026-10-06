extends Control

const COMPANY_LOGO := preload("res://sprites/logo empresa.png")
var leaving: bool = false
var reveal: Tween
var logo: TextureRect

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo = TextureRect.new()
	logo.name = "CompanyLogo"
	logo.texture = COMPANY_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	center.add_child(logo)
	resized.connect(_resize_logo)
	_resize_logo()
	logo.modulate.a = 0.0
	reveal = create_tween()
	reveal.tween_property(logo, "modulate:a", 1.0, 0.7)
	reveal.tween_interval(1.8)
	reveal.tween_callback(_finish)

func _resize_logo() -> void:
	logo.custom_minimum_size = Vector2(minf(size.x * 0.72, 640.0), minf(size.y * 0.78, 440.0))

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		_finish()
		get_viewport().set_input_as_handled()

func _finish() -> void:
	if leaving:
		return
	leaving = true
	if reveal and reveal.is_running():
		reveal.kill()
	var fade := create_tween()
	fade.tween_property(logo, "modulate:a", 0.0, 0.45)
	await fade.finished
	get_tree().change_scene_to_file("res://menu.tscn")
