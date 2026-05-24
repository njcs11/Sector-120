extends CharacterBody2D

signal enemy_died(score_value: int)
signal enemy_escaped

var max_health     := 50
var current_health := 100
var move_speed     := 80.0
var contact_damage := 15
var shoot_damage   := 40
var score_value    := 50
var shoot_interval := 1.0
var shoot_timer    := 0.0
var is_dead        := false
var player_ref     : Node = null
var wave_num       := 1

var _jump_timer    := 0.0
var _jump_interval := 2.0
var bullet_speed   := 399.0
var _aggro_range   := 600.0

const GRAVITY    := 980.0
const JUMP_FORCE := -440.0

@onready var sprite    : Sprite2D = $Sprite2D
@onready var gun_point : Marker2D = $GunPoint

var enemy_bullet_scene := preload("res://scenes/EnemyBullet.tscn")

func _ready() -> void:
	add_to_group("enemies")
	sprite.flip_h = true
	shoot_timer   = randf_range(0.3, shoot_interval)
	_jump_timer   = randf_range(0.3, _jump_interval)

func setup(stats: Dictionary) -> void:
	max_health     = stats.get("health",         100)
	current_health = max_health
	move_speed     = stats.get("speed",          80.0)
	contact_damage = stats.get("damage",         15)
	shoot_damage   = stats.get("shoot_damage",   40)
	score_value    = stats.get("score",          50)
	shoot_interval = stats.get("shoot_cooldown", 1.0)
	bullet_speed   = stats.get("bullet_speed",   500.0)
	wave_num       = stats.get("wave",           1)
	_aggro_range   = stats.get("aggro_range",    600.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var has_player : bool = is_instance_valid(player_ref)
	var dist : float = INF
	if has_player:
		dist = global_position.distance_to(player_ref.global_position)

	# ── Wave 1: patrol left ───────────────────────────────────────────────────
	if wave_num == 1:
		velocity.x = -move_speed
		_jump_timer -= delta
		if _jump_timer <= 0.0 and is_on_floor():
			velocity.y  = JUMP_FORCE * 0.75
			_jump_timer = randf_range(2.5, 4.0)

	# ── Wave 2: chase + jump ──────────────────────────────────────────────────
	elif wave_num == 2:
		if has_player and dist < _aggro_range:
			var chase_dir : float = sign(player_ref.global_position.x - global_position.x)
			velocity.x = chase_dir * move_speed * 1.1
		else:
			velocity.x = -move_speed
		_jump_timer -= delta
		if _jump_timer <= 0.0 and is_on_floor():
			velocity.y  = JUMP_FORCE
			_jump_timer = randf_range(1.2, _jump_interval)

	# ── Wave 3: aggressive chase, height-aware ────────────────────────────────
	elif wave_num >= 3:
		if has_player:
			var chase_dir : float = sign(player_ref.global_position.x - global_position.x)
			velocity.x = chase_dir * move_speed * 1.25
		else:
			velocity.x = -move_speed
		_jump_timer -= delta
		if _jump_timer <= 0.0 and is_on_floor():
			if has_player and player_ref.global_position.y < global_position.y - 35.0:
				velocity.y = JUMP_FORCE * 1.3
			else:
				velocity.y = JUMP_FORCE * 0.8
			_jump_timer = randf_range(0.7, 1.4)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		_try_shoot()
		shoot_timer = shoot_interval + randf_range(-0.15, 0.15)

	move_and_slide()

	# Contact damage
	for i in get_slide_collision_count():
		var col  := get_slide_collision(i)
		var body := col.get_collider()
		if body and body.is_in_group("player"):
			body.take_damage(contact_damage)

	# Escaped past left edge
	if global_position.x < -150.0:
		enemy_escaped.emit()
		queue_free()

func _try_shoot() -> void:
	if not is_instance_valid(player_ref):
		return
	_play_sfx("res://audio/enemy_shoot.wav")
	# Straight aim at player — no prediction, no gravity on bullet
	var aim_dir : Vector2 = (player_ref.global_position - gun_point.global_position).normalized()

	if wave_num >= 3:
		var base_angle : float = aim_dir.angle()
		for i in 3:
			var b := enemy_bullet_scene.instantiate()
			b.global_position = gun_point.global_position
			var angle_off : float = deg_to_rad((i - 1) * 18.0)
			var final_dir := Vector2(cos(base_angle + angle_off), sin(base_angle + angle_off))
			b.set_direction(final_dir)
			b.damage = shoot_damage
			b.speed  = bullet_speed
			get_tree().current_scene.add_child(b)
	else:
		var b := enemy_bullet_scene.instantiate()
		b.global_position = gun_point.global_position
		b.set_direction(aim_dir)
		b.damage = shoot_damage
		b.speed  = bullet_speed
		get_tree().current_scene.add_child(b)

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health -= amount
	current_health  = max(0, current_health)
	sprite.modulate = Color(2.5, 0.5, 0.5)
	await get_tree().create_timer(0.08).timeout
	if not is_dead:
		sprite.modulate = Color.WHITE
	if current_health <= 0:
		_die()

func _die() -> void:
	if is_dead: return
	is_dead = true
	enemy_died.emit(score_value)
	_play_sfx("res://audio/enemy_die.mp3")
	await get_tree().create_timer(0.3).timeout
	queue_free()
	
func _play_sfx(path: String) -> void:
	var sfx := get_node_or_null("SFXPlayer") as AudioStreamPlayer
	if not sfx: return
	var s := load(path) as AudioStream
	if s:
		sfx.stream = s
		sfx.play()
