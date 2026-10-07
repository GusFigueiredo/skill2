extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func run_checks() -> void:
	change_scene_to_file("res://prologue.tscn")
	await process_frame
	await process_frame
	var prologue = current_scene
	check(prologue.STORY_FRAMES.size() == 5, "Prologue must present all five cinematic beats")
	check(prologue.title_label.text == "RATANABÁ, A CIDADE PERDIDA", "Prologue must open in Ratanabá")
	check(prologue.get_node("CinematicWorld/RatanabaRuins").visible, "Opening frame must illustrate the lost city")
	check(prologue.player_figure.animation == "walk", "The historian must walk through the opening scene")
	prologue._advance()
	check(prologue.title_label.text == "VESTÍGIOS DO PASSADO", "Prologue must introduce the discovered artifacts")
	check(prologue.artifact_layer.visible, "Artifact discovery must have its own illustrated scene")
	prologue.frame_elapsed = 1.4
	prologue._update_beat_visuals()
	check(prologue.player_figure.animation == "walk", "The hero must approach the discovered artifact")
	check(prologue.player_figure.position.x > 600, "The hero must reach the artifact before it awakens")
	prologue._advance()
	prologue._advance()
	check(prologue.enemy_figure.visible, "The forest battle must show a common enemy")
	check(prologue.enemy_figure.sprite_frames.has_animation("death"), "The enemy sprite must support an animated defeat")
	prologue.frame_elapsed = 1.4
	prologue._update_battle_beat()
	check(prologue.player_figure.animation == "hurt", "The hero must react to an enemy attack")
	prologue.frame_elapsed = 3.0
	prologue._update_battle_beat()
	check(prologue.enemy_figure.animation == "hurt", "The enemy must react to the hero's counterattack")
	prologue.frame_elapsed = 3.5
	prologue._update_battle_beat()
	check(prologue.enemy_figure.animation == "death", "The combat beat must animate the enemy's defeat")
	prologue._advance()
	check(prologue.title_label.text == "A SOMBRA DO CORPO SECO", "Final story beat must reveal the Corpo Seco threat")
	check(prologue.boitata_figure.visible, "The final scene must foreshadow Boitatá")
	check(not prologue.corpo_seco.visible, "The Corpo Seco reveal must wait for the scene's climax")
	prologue.frame_elapsed = 3.4
	prologue._update_final_reveal()
	check(prologue.corpo_seco.visible, "Final frame must illustrate the Corpo Seco")
	prologue._advance()
	await wait_for_transition()
	check(current_scene.scene_file_path == "res://level_map.tscn", "Finishing the prologue must open the level map")

	var level_map = current_scene
	check(level_map.stage_buttons.size() == 7, "The map must show all seven campaign stages")
	check(not level_map.stage_buttons[0].disabled, "Ratanabá must be the only available stage")
	for index in range(1, 7):
		check(level_map.stage_buttons[index].disabled, "Future stages must remain locked in this increment")
	level_map._start_selected_stage()
	await wait_for_transition()
	check(current_scene.scene_file_path == "res://main.tscn", "Available stage must launch the current playable prototype")
	print("PASS: opening story, seven-stage map, locked future stages and phase-one launch")
	quit(0)

func wait_for_transition() -> void:
	var transition = root.get_node("SceneTransition")
	check(transition.busy and paused, "Scene transition must show its loading overlay and pause")
	while transition.busy:
		await process_frame
	check(not paused, "Scene transition must resume after the destination scene loads")
