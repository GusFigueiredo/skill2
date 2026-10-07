extends SceneTree
func _initialize():
 call_deferred("run_checks")
func frames(count: int):
 for index in count:
  await physics_frame
func run_checks():
 for direction in [-1,1]:
  for overlapping_finish in [false,true]:
   var scene=load("res://main.tscn").instantiate()
   root.add_child(scene)
   scene.set_process(false)
   var player=scene.player
   var enemy=scene.get_node("Enemy1")
   var half_width: float=(player.get_node("CollisionShape2D").shape.size.x+enemy.get_node("CollisionShape2D").shape.size.x)*0.5
   var distance: float=half_width+10.0 if not overlapping_finish else maxf(half_width+10.0,player.dodge_distance-half_width+10.0)
   player.position=Vector2(400,430)
   enemy.position=Vector2(400+direction*distance,430)
   enemy.speed=0
   enemy.telegraphed_attacks=false
   await frames(3)
   assert(player.hp==10)
   player._start_dodge(direction)
   await frames(24)
   assert(not player.is_dodging)
   assert(player.hp==10,"Crossing an idle enemy must not deal damage during or after the roll")
   assert(not enemy.attack_pending)
   player.position=Vector2(700,430)
   await frames(3)
   assert(not enemy.contact_requires_separation)
   var contact_distance: float=(player.get_node("CollisionShape2D").shape.size.x+enemy.get_node("CollisionShape2D").shape.size.x)*0.5+0.2
   player.position=enemy.position+Vector2(contact_distance,0)
   await frames(3)
   assert(player.hp==9,"A new contact after separation must cause damage normally")
   scene.free()
   await frames(2)
 print("PASS: idle enemy crossing in both directions, full exit, overlapping finish and damage on reentry")
 quit()
