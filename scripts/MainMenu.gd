extends Control

func _ready() -> void:
	get_tree().paused = false
	# Background music
	var bgm := AudioStreamPlayer.new()
	add_child(bgm)
	var music := load("res://audio/menu_bgm.wav") 
	if music:
		bgm.stream = music
		bgm.volume_db = -8.0  # volume (0 = full, -10 = quieter)
		bgm.play()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_controls_pressed() -> void:
	$ControlsPanel.visible = not $ControlsPanel.visible

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_close_pressed() -> void:
	$ControlsPanel.visible = false
