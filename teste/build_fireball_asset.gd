extends SceneTree
func _initialize():
 var source = Image.load_from_file("res://sprites/sprites sheets personagens.png")
 var crop = source.get_region(Rect2i(829,979,77,69))
 crop.convert(Image.FORMAT_RGBA8)
 for y in crop.get_height():
  for x in crop.get_width():
   var c=crop.get_pixel(x,y)
   if maxf(c.r,maxf(c.g,c.b))<0.3:
    crop.set_pixel(x,y,Color(0,0,0,0))
 crop=crop.get_region(crop.get_used_rect())
 crop.save_png("res://sprites/characters/boitata/projectile.png")
 quit()
