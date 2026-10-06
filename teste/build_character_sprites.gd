extends SceneTree

const ROOT = "res://sprites/characters/"
var source: Image

func _initialize() -> void:
	source = Image.load_from_file("res://sprites/sprites sheets personagens.png")
	if source == null:
		quit(1)
		return
	var hero_walk = cells([390, 455, 525, 600, 680, 775, 838, 893, 950, 1008, 1072], 82, 173)
	var hero_attack = cells([390, 450, 535, 630, 714, 775], 215, 306)
	hero_attack[2].size.x -= 12
	var hero_jump = cells([1080, 1144, 1208, 1280, 1348, 1420], 79, 173)
	var hero_dodge = cells([781, 846, 909, 980, 1072], 224, 306)
	var hero_hurt = cells([1080, 1145, 1205, 1264], 214, 306)
	var hero_death = cells([1270, 1350, 1422], 249, 306)
	var enemy_walk = cells([294, 371, 451, 534, 637, 739, 820, 901, 1006], 407, 512)
	var enemy_attack = cells([1014, 1105, 1210, 1310, 1424], 405, 512)
	var enemy_hurt = cells([294, 385, 474, 560, 637], 550, 632)
	var enemy_death = cells([648, 775, 881, 1015, 1167, 1299, 1424], 550, 634)
	var boss_idle = cells([342, 455, 558, 648, 738], 724, 815)
	var boss_walk = cells([745, 835, 955, 1072, 1157], 723, 815)
	var boss_tail = cells([340, 487, 740], 847, 934)
	var boss_dash = cells([1034, 1223, 1424], 849, 934)
	var boss_bite = cells([1166, 1293, 1424], 721, 815)
	var boss_fireball = cells([342, 461, 553, 741], 966, 1068)
	build("player", {"idle": hero_walk.slice(0, 4), "walk": hero_walk.slice(5), "attack": hero_attack.slice(0, 4), "jump": hero_jump, "dodge": hero_dodge, "hurt": hero_hurt, "death": hero_death})
	build("enemy", {"idle": enemy_walk.slice(0, 4), "walk": enemy_walk.slice(4), "attack": enemy_attack, "hurt": enemy_hurt, "death": enemy_death})
	build("boitata", {"idle": boss_idle, "walk": boss_walk, "windup": boss_idle, "dash": boss_dash, "bite": boss_bite, "tail": boss_tail, "fireball": boss_fireball})
	print("Character PNG frames and SpriteFrames exported.")
	quit()

func cells(edges: Array, top: int, bottom: int) -> Array:
	var result: Array = []
	for i in edges.size() - 1:
		result.append(Rect2i(edges[i] + 4, top + 2, edges[i + 1] - edges[i] - 8, bottom - top - 4))
	return result

func build(character: String, animations: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + character)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in animations:
		frames.add_animation(animation_name)
		var fps := 20.0 if animation_name == "dodge" else 12.0 if animation_name in ["attack", "dash"] else 8.0
		frames.set_animation_speed(animation_name, fps)
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "windup", "dash"])
		var index := 0
		for region: Rect2i in animations[animation_name]:
			var crop := source.get_region(region)
			remove_panel_background(crop)
			var used := crop.get_used_rect()
			var canvas := Image.create(256, 128, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(crop, used, Vector2i((256 - used.size.x) / 2, 120 - used.size.y))
			var path: String = ROOT + character + "/%s_%02d.png" % [animation_name, index]
			canvas.save_png(path)
			# External textures make every separated pose editable in the inspector.
			var texture := ImageTexture.create_from_image(canvas)
			texture.take_over_path(path)
			frames.add_frame(animation_name, texture)
			index += 1
	ResourceSaver.save(frames, ROOT + character + ".tres")

# Segment the uniformly dark panels; recover the dark outlines adjacent to art.
func remove_panel_background(crop: Image) -> void:
	crop.convert(Image.FORMAT_RGBA8)
	var mask := PackedByteArray()
	var width := crop.get_width()
	var height := crop.get_height()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var c := crop.get_pixel(x, y)
			if maxf(c.r, maxf(c.g, c.b)) > 0.22:
				mask[y * width + x] = 1
	# Remove thin disconnected panel dividers, retaining small effect particles.
	var visited := PackedByteArray()
	visited.resize(mask.size())
	for y in height:
		for x in width:
			var start := y * width + x
			if mask[start] == 0 or visited[start] == 1:
				continue
			var component: Array[int] = [start]
			visited[start] = 1
			var cursor := 0
			var min_x := x
			var max_x := x
			var min_y := y
			var max_y := y
			while cursor < component.size():
				var index := component[cursor]
				cursor += 1
				var px := index % width
				var py := index / width
				min_x = mini(min_x, px)
				max_x = maxi(max_x, px)
				min_y = mini(min_y, py)
				max_y = maxi(max_y, py)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx := px + dx
						var ny := py + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							var neighbor := ny * width + nx
							if mask[neighbor] == 1 and visited[neighbor] == 0:
								visited[neighbor] = 1
								component.append(neighbor)
			if (max_x - min_x < 3 and max_y - min_y > 20) or (max_y - min_y < 2 and max_x - min_x > 25):
				for index in component:
					mask[index] = 0
	var expanded := mask.duplicate()
	for y in height:
		for x in width:
			if mask[y * width + x] == 1:
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							var c := crop.get_pixel(nx, ny)
							if maxf(c.r, maxf(c.g, c.b)) < 0.08:
								expanded[ny * width + nx] = 1
	var black_queue: Array[int] = []
	for index in expanded.size():
		if expanded[index] == 1:
			black_queue.append(index)
	var black_cursor := 0
	while black_cursor < black_queue.size():
		var index := black_queue[black_cursor]
		black_cursor += 1
		var px := index % width
		var py := index / width
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nx: int = px + step.x
			var ny: int = py + step.y
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var neighbor := ny * width + nx
				var c := crop.get_pixel(nx, ny)
				if expanded[neighbor] == 0 and maxf(c.r, maxf(c.g, c.b)) < 0.08:
					expanded[neighbor] = 1
					black_queue.append(neighbor)
	for y in height:
		for x in width:
			if expanded[y * width + x] == 0:
				crop.set_pixel(x, y, Color.TRANSPARENT)
