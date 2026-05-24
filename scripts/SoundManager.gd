extends Node

@onready var _player : AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(_player)

func _play(path: String) -> void:
	if not ResourceLoader.exists(path): return
	_player.stream = load(path)
	_player.play()

func play_enemy_shoot() -> void: _play("res://audio/enemy_shoot.wav")
func play_enemy_hit()   -> void: _play("res://audio/enemy_hit.wav")
func play_enemy_die()   -> void: _play("res://audio/enemy_die.wav")
func play_player_shoot()-> void: _play("res://audio/player_shoot.wav")
func play_player_jump() -> void: _play("res://audio/player_jump.wav")
func play_player_hurt() -> void: _play("res://audio/player_hurt.wav")
func play_player_die()  -> void: _play("res://audio/player_die.wav")
func play_boss_shoot()  -> void: _play("res://audio/boss_shoot.wav")
func play_boss_hit()    -> void: _play("res://audio/boss_hit.wav")
func play_boss_die()    -> void: _play("res://audio/boss_die.wav")
