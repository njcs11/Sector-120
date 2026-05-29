extends Node

signal wave_started(wave_num: int, total: int)
signal wave_completed(wave_num: int)
signal all_waves_completed
signal enemy_count_changed(alive: int, total: int)
signal boss_spawned
signal enemies_escaped(count: int)   # NEW: notify main scene of escape count

const TOTAL_WAVES    := 3
const SPAWN_X        := 1380.0
const SPAWN_Y        := 490.0
const MAX_ESCAPED    := 3            # game over threshold

var current_wave     := 0
var enemies_alive    := 0
var enemies_to_spawn := 0
var enemies_total    := 0
var spawn_timer      := 0.0
var spawn_interval   := 2.0
var is_active        := false
var player_ref       : Node = null

var escaped_count    := 0            # tracks enemies that passed the player

var enemy_scene := preload("res://scenes/Enemy.tscn")
var boss_scene  := preload("res://scenes/Boss.tscn")

# ── Wave configs — significantly harder ───────────────────────────────────────
var wave_configs : Array = [
	{
		"wave": 1, "count": 14, "spawn_interval": 1.8,
		"health": 40, "speed": 95.0, "damage": 12,
		"shoot_damage": 10, "shoot_cooldown": 2.2,
		"bullet_speed": 330.0, "score": 100,
		"aggro_range": 500.0
	},
	{
		"wave": 2, "count": 20, "spawn_interval": 1.2,
		"health": 150, "speed": 135.0, "damage": 20,
		"shoot_damage": 25, "shoot_cooldown": 1.4,
		"bullet_speed": 480.0, "score": 200,
		"aggro_range": 650.0
	},
	{
		"wave": 3, "count": 22, "spawn_interval": 0.33,
		"health": 160, "speed": 175.0, "damage": 30,
		"shoot_damage": 50, "shoot_cooldown": 0.85,
		"bullet_speed": 750.0, "score": 350,
		"aggro_range": 800.0
	},
]

# ── Audio ─────────────────────────────────────────────────────────────────────
func _play_sfx(path: String) -> void:
	var sfx := get_node_or_null("SFXPlayer") as AudioStreamPlayer
	if not sfx: return
	var s := load(path) as AudioStream
	if s:
		sfx.stream = s
		sfx.play()

func start_wave(wave_num: int) -> void:
	current_wave     = wave_num
	is_active        = true
	escaped_count    = 0
	var cfg : Dictionary = wave_configs[wave_num - 1]
	enemies_to_spawn = cfg["count"]
	enemies_alive    = enemies_to_spawn
	enemies_total    = enemies_to_spawn
	spawn_interval   = cfg["spawn_interval"]
	spawn_timer      = 0.4
	wave_started.emit(wave_num, TOTAL_WAVES)
	enemy_count_changed.emit(enemies_alive, enemies_total)
	_play_sfx("res://audio/wave_start1.mp3")

func _process(delta: float) -> void:
	if not is_active or enemies_to_spawn <= 0:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = spawn_interval

func _spawn_enemy() -> void:
	var cfg : Dictionary = wave_configs[current_wave - 1]
	var enemy : Node = enemy_scene.instantiate()
	var y_opts : Array = [SPAWN_Y, SPAWN_Y - 140.0, SPAWN_Y - 265.0]
	enemy.global_position = Vector2(SPAWN_X, y_opts[randi() % y_opts.size()])
	enemy.setup(cfg)
	enemy.player_ref = player_ref
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_escaped.connect(_on_enemy_escaped)   # NEW
	get_tree().current_scene.add_child(enemy)
	enemies_to_spawn -= 1

func spawn_boss() -> void:
	var b : Node = boss_scene.instantiate()
	b.global_position  = Vector2(1000.0, 420.0)
	b.player_ref       = player_ref
	b.boss_died.connect(_on_boss_died)
	b.boss_health_changed.connect(func(c: int, m: int): enemy_count_changed.emit(c, m))
	get_tree().current_scene.add_child(b)
	boss_spawned.emit()

func _on_enemy_died(points: int) -> void:
	enemies_alive -= 1
	enemy_count_changed.emit(max(0, enemies_alive), enemies_total)
	var main := get_parent()
	if main.has_method("add_score"):
		main.add_score(points)
	if enemies_alive <= 0 and enemies_to_spawn <= 0:
		is_active = false
		_play_sfx("res://audio/wave_complete.wav")
		wave_completed.emit(current_wave)

func _on_enemy_escaped() -> void:
	# Count escaped enemies — still decrement alive count
	enemies_alive = max(0, enemies_alive - 1)
	escaped_count += 1
	enemies_escaped.emit(escaped_count)
	enemy_count_changed.emit(enemies_alive, enemies_total)
	# If too many escaped, signal game over via main
	if escaped_count >= MAX_ESCAPED:
		var main := get_parent()
		if main.has_method("on_too_many_escaped"):
			main.on_too_many_escaped()
	elif enemies_alive <= 0 and enemies_to_spawn <= 0:
		is_active = false
		_play_sfx("res://audio/wave_complete.wav")
		wave_completed.emit(current_wave)

func _on_boss_died() -> void:
	var main := get_parent()
	if main.has_method("add_score"):
		main.add_score(3000)
	all_waves_completed.emit()

func clear_enemies() -> void:
	is_active     = false
	escaped_count = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
