extends CharacterBody2D

signal boss_died
signal boss_health_changed(current: int, maximum: int)

const MAX_HEALTH  := 15000
const GRAVITY     := 990.0
const MOVE_SPEED  := 90.0

var current_health := MAX_HEALTH
var is_dead        := false
var player_ref     : Node = null
var _boss_time     : float = 0.0

enum Phase { PHASE1, PHASE2, PHASE3 }
var phase : int = Phase.PHASE1

var _attack_timer      : float = 1.2
var _move_timer        : float = 0.0
var _move_dir          : float = -1.0
var _laser_active      : bool  = false
var _laser_timer       : float = 0.0
var _laser_duration    : float = 3.2
var _laser_tick_cd     : float = 0.0
var _enrage_active     : bool  = false
var _stomp_timer       : float = 5.0
var _phase2_sfx_played : bool = false
var _phase3_sfx_played : bool = false	
var _spawn_sfx : AudioStreamPlayer = null

@onready var sprite : Sprite2D = $Sprite2D

var boss_bullet_scene := preload("res://scenes/BossBullet.tscn")

# ── Audio ─────────────────────────────────────────────────────────────────────
# Add an AudioStreamPlayer node named SFXPlayer under the Boss scene
func _play_sfx(stream_path: String) -> void:
	var s := load(stream_path) as AudioStream
	if not s: return
	var sfx := AudioStreamPlayer.new()
	get_tree().current_scene.add_child(sfx)
	sfx.stream = s
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _ready() -> void:
	add_to_group("enemies")
	current_health = MAX_HEALTH
	boss_health_changed.emit(current_health, MAX_HEALTH)
	# Play spawn audio
	var s := load("res://audio/boss_spawn.wav") as AudioStream
	if s:
		_spawn_sfx = AudioStreamPlayer.new()
		get_tree().current_scene.call_deferred("add_child", _spawn_sfx)
		_spawn_sfx.stream = s
		await get_tree().process_frame
		_spawn_sfx.play()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_boss_time += delta

	# Phase based on BOTH time AND health (whichever triggers first)
	var hp_ratio := float(current_health) / float(MAX_HEALTH)
	var new_phase := Phase.PHASE1
	if _boss_time > 60.0 or hp_ratio < 0.30:
		new_phase = Phase.PHASE3
	elif _boss_time > 35.0 or hp_ratio < 0.60:
		new_phase = Phase.PHASE2

	if new_phase != phase:
		phase = new_phase
		if phase == Phase.PHASE2 and not _phase2_sfx_played:
			_phase2_sfx_played = true
			if is_instance_valid(_spawn_sfx):
				_spawn_sfx.stop()
				_spawn_sfx.queue_free()
			_play_sfx("res://audio/boss_phase2.wav")
		elif phase == Phase.PHASE3 and not _phase3_sfx_played:
			_phase3_sfx_played = true
			_enrage_active = true
			if is_instance_valid(_spawn_sfx):
				_spawn_sfx.stop()
				_spawn_sfx.queue_free()
			_play_sfx("res://audio/boss_enrage.wav")

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	# Movement speed per phase
	var spd_mult : float = 4.2
	if phase == Phase.PHASE2:
		spd_mult = 7.2
	elif phase == Phase.PHASE3:
		spd_mult = 11.0

	# Direction changes — faster in enrage
	var dir_interval := Vector2(1.2, 2.5) if not _enrage_active else Vector2(0.3, 0.9)
	_move_timer -= delta
	if _move_timer <= 0.0:
		_move_dir   = -1.0 if randf() > 0.5 else 1.0
		_move_timer = randf_range(dir_interval.x, dir_interval.y)

	# Phase 3: chase player 70% of the time
	if phase == Phase.PHASE3 and is_instance_valid(player_ref) and randf() < 0.7:
		_move_dir = sign(player_ref.global_position.x - global_position.x)

	velocity.x = _move_dir * MOVE_SPEED * spd_mult
	move_and_slide()
	var vw := get_viewport_rect().size.x
	global_position.x = clamp(global_position.x, 60.0, vw - 60.0)

	# Stomp jump in phase 2+
	if phase != Phase.PHASE1 and is_instance_valid(player_ref):
		_stomp_timer -= delta
		if _stomp_timer <= 0.0 and is_on_floor():
			velocity.y = -750.0
			_play_sfx("res://audio/boss_stomp.wav")
			_stomp_timer = randf_range(2.5, 5.0) if phase == Phase.PHASE2 else randf_range(1.5, 3.0)

	# Modulate by phase
	match phase:
		Phase.PHASE1: sprite.modulate = Color(1.0, 1.0, 1.0)
		Phase.PHASE2: sprite.modulate = Color(1.4, 0.6, 1.4)
		Phase.PHASE3:
			var flicker := 0.85 + sin(_boss_time * 20.0) * 0.15
			sprite.modulate = Color(2.0 * flicker, 0.15, 2.0 * flicker)

	# Laser tick
	if _laser_active:
		_laser_timer -= delta
		_fire_laser_tick(delta)
		if _laser_timer <= 0.0:
			_laser_active = false
		return

	# Attack cooldown
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_do_attack()
		var min_cd : float = 1.4
		var max_cd : float = 2.4
		if phase == Phase.PHASE2:
			min_cd = 0.7
			max_cd = 1.3
		elif phase == Phase.PHASE3:
			min_cd = 0.25
			max_cd = 0.6
		_attack_timer = randf_range(min_cd, max_cd)

func _do_attack() -> void:
	var attacks_p1 := ["spiral", "spread", "laser", "aimed_burst"]
	var attacks_p2 := ["spiral", "spread", "missile", "laser", "burst_spread", "aimed_burst", "ring_burst"]
	var attacks_p3 := ["spiral", "spread", "missile", "laser", "burst_spread", "aimed_burst", "ring_burst", "cross_fire"]

	var pool : Array
	match phase:
		Phase.PHASE1: pool = attacks_p1
		Phase.PHASE2: pool = attacks_p2
		Phase.PHASE3: pool = attacks_p3

	var chosen : String
	if _enrage_active and randf() < 0.5:
		chosen = pool[pool.size() - 1]  # bias toward most aggressive
	else:
		chosen = pool[randi() % pool.size()]

	match chosen:
		"spiral":       _attack_spiral()
		"spread":       _attack_spread()
		"missile":      _attack_missile()
		"laser":        _start_laser()
		"burst_spread": _attack_burst_spread()
		"aimed_burst":  _attack_aimed_burst()
		"ring_burst":   _attack_ring_burst()
		"cross_fire":   _attack_cross_fire()

# ── Attack patterns ───────────────────────────────────────────────────────────

func _attack_spiral() -> void:
	_play_sfx("res://audio/boss_shoot.wav")
	var bullet_count := 10 if phase == Phase.PHASE3 else 8
	var waves := 3 if _enrage_active else 2
	for w in waves:
		await get_tree().create_timer(0.38 * w).timeout
		if is_dead: return
		for i in bullet_count:
			var angle := (TAU / float(bullet_count)) * i + (TAU / float(bullet_count) * 0.5 * w)
			var dir   := Vector2(cos(angle), sin(angle))
			_spawn_boss_bullet(0, dir, 22)

func _attack_spread() -> void:
	if not is_instance_valid(player_ref): return
	_play_sfx("res://audio/boss_shoot.wav")
	var base_dir : Vector2 = (player_ref.global_position - global_position).normalized()
	var count    := 11 if phase == Phase.PHASE3 else 9
	var spread   := deg_to_rad(90.0)
	for i in count:
		var t     := float(i) / float(count - 1) - 0.5
		var angle := base_dir.angle() + t * spread
		_spawn_boss_bullet(3, Vector2(cos(angle), sin(angle)), 18)
	await get_tree().create_timer(0.32).timeout
	if is_dead: return
	for i in count:
		var t     := float(i) / float(count - 1) - 0.5
		var angle := base_dir.angle() + t * spread * 0.55
		_spawn_boss_bullet(3, Vector2(cos(angle), sin(angle)), 18)

func _attack_burst_spread() -> void:
	var wave_count := 5 if _enrage_active else 3
	for wave in wave_count:
		await get_tree().create_timer(0.14 * wave).timeout
		if is_dead: return
		_attack_spread()

func _attack_missile() -> void:
	if not is_instance_valid(player_ref): return
	_play_sfx("res://audio/boss_missile.wav")
	var count := 6 if phase == Phase.PHASE3 else 3
	for i in count:
		await get_tree().create_timer(0.1 * i).timeout
		if is_dead: return
		var angle := randf_range(-0.5, 0.5)
		var dir   := Vector2(cos(angle + PI), sin(angle))
		_spawn_boss_bullet(2, dir, 30, player_ref)

func _attack_aimed_burst() -> void:
	if not is_instance_valid(player_ref): return
	_play_sfx("res://audio/boss_shoot.wav")
	var shots := 5 if phase == Phase.PHASE3 else 3
	for i in shots:
		await get_tree().create_timer(0.07 * i).timeout
		if is_dead or not is_instance_valid(player_ref): return
		var dir : Vector2 = (player_ref.global_position - global_position).normalized()
		_spawn_boss_bullet(1, dir, 20)

func _attack_ring_burst() -> void:
	_play_sfx("res://audio/boss_shoot.wav")
	var count := 16
	for i in count:
		var angle := (TAU / float(count)) * i
		_spawn_boss_bullet(0, Vector2(cos(angle), sin(angle)), 25)
	await get_tree().create_timer(0.55).timeout
	if is_dead: return
	for i in count:
		var angle := (TAU / float(count)) * i + PI / count
		_spawn_boss_bullet(3, Vector2(cos(angle), sin(angle)), 25)

func _attack_cross_fire() -> void:
	_play_sfx("res://audio/boss_shoot.wav")
	for i in 8:
		var angle := (TAU / 8.0) * i
		_spawn_boss_bullet(0, Vector2(cos(angle), sin(angle)), 30)
	await get_tree().create_timer(0.5).timeout
	if is_dead: return
	if is_instance_valid(player_ref):
		var aimed : Vector2 = (player_ref.global_position - global_position).normalized()
		for i in 5:
			var t := float(i) / 4.0 - 0.5
			_spawn_boss_bullet(3, aimed.rotated(t * deg_to_rad(40.0)), 38)

func _start_laser() -> void:
	_play_sfx("res://audio/boss_laser.wav")
	_laser_active  = true
	_laser_timer   = _laser_duration
	_laser_tick_cd = 0.0

func _fire_laser_tick(delta: float) -> void:
	_laser_tick_cd -= delta
	if _laser_tick_cd > 0.0: return
	_laser_tick_cd = 0.022 if _enrage_active else 0.032
	if not is_instance_valid(player_ref): return
	var dir : Vector2 = (player_ref.global_position - global_position).normalized()
	_spawn_boss_bullet(1, dir, 16)

func _spawn_boss_bullet(type: int, dir: Vector2, dmg: int, target: Node = null) -> void:
	var b : Node = boss_bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, -30)
	b.setup(type, dir, dmg, target)
	if phase == Phase.PHASE2:
		b.speed *= 2.8
	elif phase == Phase.PHASE3:
		b.speed *= 1.9
	if _enrage_active:
		b.speed  *= 1.25
		b.damage  = int(b.damage * 1.4)
	get_tree().current_scene.add_child(b)

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health -= amount
	current_health  = max(0, current_health)
	boss_health_changed.emit(current_health, MAX_HEALTH)
	_play_sfx("res://audio/boss_hit.wav")
	sprite.modulate = Color(3.0, 0.3, 0.3)
	await get_tree().create_timer(0.06).timeout
	if not is_dead:
		sprite.modulate = Color(1, 1, 1)
	if current_health <= 0:
		_die()

func _die() -> void:
	if is_dead: return
	is_dead = true
	var sfx := AudioStreamPlayer.new()
	get_tree().current_scene.add_child(sfx)
	var s := load("res://audio/boss_die.wav") as AudioStream
	if s:
		sfx.stream = s
		sfx.play()
	await get_tree().create_timer(0.15).timeout
	boss_died.emit()
	queue_free()
