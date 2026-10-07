extends SceneTree
func _initialize():
 var source = Image.load_from_file("res://sprites/Personagens/sprite sheet boitata.png")
 var crop = source.get_region(Rect2i(630,890,235,125))
 crop=crop.get_region(crop.get_used_rect())
 crop.save_png("res://sprites/characters/boitata/projectile.png")
 quit()
