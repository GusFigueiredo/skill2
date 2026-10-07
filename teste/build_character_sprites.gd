extends SceneTree

const ROOT = "res://sprites/characters/"
var source: Image
var pose_scale: float

func _initialize() -> void:
	source = Image.load_from_file("res://sprites/Personagens/sprite sheet personagem.png")
	pose_scale = 0.6
	build("player", {
		"idle": cells([55, 185, 320, 455, 585], 0, 150),
		"walk": cells([165, 300, 420, 545, 650, 760, 880, 995, 1110, 1235], 150, 305),
		"walk_up": cells([240, 365, 490, 615, 750, 900, 1040], 305, 455),
		"walk_down": cells([275, 400, 530, 660, 790, 940, 1080], 455, 605),
		"jump": cells([185, 320, 460, 620, 810, 950, 1125], 605, 760),
		"attack": cells([25, 150, 315, 490], 760, 900),
		"dodge": cells([180, 295, 470, 670, 915, 1040], 900, 993),
		"hurt": cells([395, 530, 650, 765, 880], 993, 1086),
		"death": cells([765, 880], 993, 1086),
	})
	source = Image.load_from_file("res://sprites/Personagens/sprite sheet inimigo.png")
	pose_scale = 0.65
	build("enemy", {
		"idle": cells([420, 560, 710, 865, 1035], 0, 150),
		"walk": cells([100, 270, 410, 575, 725, 880, 1025, 1170, 1350], 150, 300),
		"walk_up": cells([250, 405, 555, 700, 860, 1020, 1160], 300, 445),
		"walk_down": cells([190, 370, 550, 725, 890, 1080, 1250], 445, 590),
		"attack": cells([85, 280, 525, 770, 990, 1180, 1365], 590, 730),
		"dodge": cells([85, 280, 535, 745, 970, 1180, 1365], 730, 850),
		"hurt": cells([390, 550, 735, 890, 1050], 850, 975),
		"death": cells([85, 275, 475, 675, 875, 1125, 1410], 975, 1086),
	})
	source = Image.load_from_file("res://sprites/Personagens/sprite sheet boitata.png")
	pose_scale = 0.43
	var idle := cells([20, 310, 610, 915, 1210], 0, 240)
	var fire := cells([25, 310, 585], 860, 1086)
	build("boitata", {
		"idle": idle, "windup": idle,
		"bite": cells([25, 380, 710, 1035, 1325], 310, 510),
		"dash": cells([20, 420], 550, 715),
		"fireball": [fire[0], fire[1], fire[0]],
	})
	var projectile := source.get_region(Rect2i(630, 890, 235, 125))
	projectile = projectile.get_region(projectile.get_used_rect())
	projectile.save_png(ROOT + "boitata/projectile.png")
	print("PASS: new transparent character sheets exported, directional movement and Boitata 1-2-1 sequence")
	quit()

func cells(edges: Array, top: int, bottom: int) -> Array:
	var result: Array = []
	for i in edges.size() - 1:
		result.append(Rect2i(edges[i], top, edges[i + 1] - edges[i], bottom - top))
	return result

func build(character: String, animations: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + character)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in animations:
		frames.add_animation(animation_name)
		var fps := 22.0 if animation_name == "dodge" else 20.0 if animation_name == "attack" and character == "player" else 6.0 if animation_name == "fireball" else 8.0
		frames.set_animation_speed(animation_name, fps)
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "walk_up", "walk_down", "windup", "dash"])
		var index := 0
		for region: Rect2i in animations[animation_name]:
			var expanded := Rect2i(region.position - Vector2i(20, 4), region.size + Vector2i(40, 8)).intersection(Rect2i(Vector2i.ZERO, source.get_size()))
			var crop := source.get_region(expanded)
			remove_neighbor_fragments(crop)
			crop = crop.get_region(crop.get_used_rect())
			crop.resize(maxi(1, roundi(crop.get_width() * pose_scale)), maxi(1, roundi(crop.get_height() * pose_scale)), Image.INTERPOLATE_NEAREST)
			var canvas := Image.create(256, 128, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i((256 - crop.get_width()) / 2, 120 - crop.get_height()))
			var path: String = ROOT + character + "/%s_%02d.png" % [animation_name, index]
			canvas.save_png(path)
			var texture := ImageTexture.create_from_image(canvas)
			texture.take_over_path(path)
			frames.add_frame(animation_name, texture)
			index += 1
	ResourceSaver.save(frames, ROOT + character + ".tres")

# Irregular spacing can leave fragments from adjacent poses at cell borders.
# Keep the body and nearby detached effects, preserving the original alpha.
func remove_neighbor_fragments(crop: Image) -> void:
	crop.convert(Image.FORMAT_RGBA8)
	var width := crop.get_width()
	var height := crop.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var components: Array = []
	var largest := 0
	for y in height:
		for x in width:
			var start := y * width + x
			if crop.get_pixel(x, y).a <= 0.01:
				crop.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			if visited[start]:
				continue
			var pixels: Array[int] = [start]
			visited[start] = 1
			var bounds := Rect2i(x, y, 1, 1)
			var cursor := 0
			while cursor < pixels.size():
				var index := pixels[cursor]
				cursor += 1
				var point := Vector2i(index % width, index / width)
				bounds = bounds.merge(Rect2i(point, Vector2i.ONE))
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var next := point + Vector2i(dx, dy)
						if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
							continue
						var neighbor := next.y * width + next.x
						if not visited[neighbor] and crop.get_pixelv(next).a > 0.01:
							visited[neighbor] = 1
							pixels.append(neighbor)
			components.append({"pixels": pixels, "bounds": bounds})
			if pixels.size() > components[largest].pixels.size():
				largest = components.size() - 1
	if components.is_empty():
		return
	var body: Rect2i = components[largest].bounds
	for i in components.size():
		if i == largest:
			continue
		var fragment: Rect2i = components[i].bounds
		var keep: bool = body.grow(8).intersects(fragment) and components[i].pixels.size() >= 6
		if fragment.position.x == 0 or fragment.position.y == 0 or fragment.end.x == width or fragment.end.y == height:
			keep = false
		if fragment.end.y <= body.position.y and components[i].pixels.size() < 100:
			keep = false
		if not keep:
			for index: int in components[i].pixels:
				crop.set_pixel(index % width, index / width, Color(0, 0, 0, 0))
