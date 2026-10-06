extends SceneTree
func _initialize():
 var theme=load("res://themes/pindorama.tres")
 var font=theme.default_font
 var accents="áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ"
 for i in accents.length():
  assert(font.has_char(accents.unicode_at(i)), "Missing accent: "+accents[i])
 print("PASS: all Portuguese accents and cedilla in uppercase and lowercase")
 quit()
