extends Node

enum State { PLAYING, TRANSITION, BOSS_FIGHT, GAME_OVER }

var state        := State.PLAYING
var score        := 0
var current_wave := 0
var _trans_timer := 0.0
const TRANS_PAUSE:= 3.5

@onready var wave_manager : Node            = $WaveManager
@onready var hud          : CanvasLayer     = $HUD
@onready var player       : CharacterBody2D = $Player

func _ready() -> void:
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_done)
	wave_manager.boss_spawned.connect(_on_boss_spawned)
	wave_manager.enemy_count_changed.connect(func(_a: int, _t: int): pass)
	wave_manager.enemies_escaped.connect(_on_enemies_escaped)   # ← NEW
	player.health_changed.connect(func(c: int, m: int): hud.update_health(c, m))
	player.player_died.connect(_on_player_died)
	hud.time_expired.connect(_on_time_up)
	wave_manager.player_ref = player
	hud.start_timer()
	hud.update_score(0)
	_begin_next_wave()

func _begin_next_wave() -> void:
	current_wave += 1
	wave_manager.start_wave(current_wave)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and state == State.GAME_OVER:
		get_tree().reload_current_scene()
	if state == State.TRANSITION:
		_trans_timer -= delta
		if _trans_timer <= 0.0:
			state = State.PLAYING
			_begin_next_wave()

func add_score(pts: int) -> void:
	score += pts
	hud.update_score(score)

# ── Escaped enemy handler ─────────────────────────────────────────────────────
func _on_enemies_escaped(count: int) -> void:
	if state == State.GAME_OVER:
		return
	hud.update_escaped(count, 3)

# Called by WaveManager when escaped_count >= 3
func on_too_many_escaped() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	wave_manager.clear_enemies()
	hud.show_message("3 ALIENS GOT PAST YOU!", 1.5)
	await get_tree().create_timer(1.5).timeout
	hud.show_game_over(false, score)

# ── Wave events ───────────────────────────────────────────────────────────────
func _on_wave_started(w: int, t: int) -> void:
	hud.update_wave(w, t)
	var names : Array = ["WAVE 1 - EASY", "WAVE 2 - MEDIUM", "WAVE 3 - HARD!"]
	hud.show_message(names[w - 1], 2.0)

func _on_wave_completed(w: int) -> void:
	if state == State.GAME_OVER:
		return
	if w == 1:
		hud.show_message("Wave 1 Complete! Prepare...", 2.0)
		state        = State.TRANSITION
		_trans_timer = TRANS_PAUSE
		_spawn_gun_pickup()
	elif w == 2:
		hud.show_message("Wave 2 Complete! Get ready...", 2.0)
		state        = State.TRANSITION
		_trans_timer = TRANS_PAUSE
		_spawn_gun_pickup()
		_spawn_heart_pickup(Vector2(600, 480))
	elif w == 3:
		hud.show_message("ALL WAVES CLEARED!\nBOSS INCOMING!!!", 2.5)
		state = State.BOSS_FIGHT
		_spawn_heart_pickup(Vector2(300, 480))
		await get_tree().create_timer(2.0).timeout
		if state == State.GAME_OVER:
			return
		_spawn_bazooka_pickup()
		await get_tree().create_timer(1.5).timeout
		if state == State.GAME_OVER:
			return
		wave_manager.spawn_boss()
		player.boost_max_health(200)
		hud.show_message("⚠  BOSS: KRAKEN  ⚠", 2.0)

func _on_boss_spawned() -> void:
	hud.show_boss_bar(true)
	await get_tree().process_frame
	for b in get_tree().get_nodes_in_group("enemies"):
		if b.has_signal("boss_health_changed"):
			if not b.boss_health_changed.is_connected(hud.update_boss_health):
				b.boss_health_changed.connect(hud.update_boss_health)

func _on_all_done() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	hud.show_boss_bar(false)
	hud.show_game_over(true, score)

func _on_time_up() -> void:
	if state != State.GAME_OVER:
		state = State.GAME_OVER
		wave_manager.clear_enemies()
		hud.show_game_over(true, score)

func _on_player_died() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	wave_manager.clear_enemies()
	hud.show_game_over(false, score)

# ── Pickups ───────────────────────────────────────────────────────────────────
func _spawn_gun_pickup() -> void:
	var scene := load("res://scenes/GunPickup.tscn")
	if not scene: return
	var p : Node2D = scene.instantiate()
	var positions : Array = [Vector2(300, 480), Vector2(520, 480), Vector2(700, 480)]
	p.global_position = positions[randi() % positions.size()]
	add_child(p)

func _spawn_bazooka_pickup() -> void:
	var scene := load("res://scenes/BazookaPickup.tscn")
	if not scene: return
	var p : Node2D = scene.instantiate()
	p.global_position = Vector2(400, 480)
	add_child(p)

func _spawn_heart_pickup(pos: Vector2) -> void:
	var scene := load("res://scenes/HeartPickup.tscn")
	if not scene: return
	var p : Node2D = scene.instantiate()
	p.global_position = pos
	add_child(p)
