extends SceneTree

const OUT := "res://sprites/Menu/extracted/"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var sheet := Image.load_from_file("res://sprites/Menu/menu sheets.png")
	var background := Image.load_from_file("res://sprites/Menu/Background.png")
	print("Menu sheet dimensions: ", sheet.get_size())
	background.get_region(Rect2i(8, 8, 704, 754)).save_png(OUT + "background.png")
	extract(sheet, Rect2i(727, 45, 706, 202), "logo")
	extract(sheet, Rect2i(725, 281, 185, 74), "button_normal")
	extract(sheet, Rect2i(915, 281, 185, 74), "button_hover")
	extract(sheet, Rect2i(1103, 281, 160, 74), "button_pressed")
	extract(sheet, Rect2i(1270, 281, 168, 74), "button_disabled")
	extract(sheet, Rect2i(1275, 770, 45, 60), "cursor", Vector2i(30, 40))
	print("Menu art extracted.")
	quit()

func extract(sheet: Image, region: Rect2i, asset: String, target := Vector2i.ZERO) -> void:
	var image := sheet.get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	# The panel background is dark green; the gold and wood remain opaque.
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r < 0.11 and c.g < 0.20 and c.b < 0.16 and c.g >= c.r:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var bounds := image.get_used_rect()
	image = image.get_region(bounds)
	if target != Vector2i.ZERO:
		image.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + asset + ".png")
