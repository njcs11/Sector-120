extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal player_died

const SPEED_NORMAL  := 220.0
const SPEED_BOOSTED := 370.0   # bazooka speed boost
const JUMP_FORCE    := -490.0
const GRAVITY       := 990.0
var MAX_HEALTH      : int = 300

var current_health  := MAX_HEALTH
var gun_level       := 1
var base_damage     := 35
var shoot_cd        := 0.26
var shoot_timer     := 0.0
var is_dead         := false
var inv_timer       := 0.0
var _jump_cd        : float = 0.0
const JUMP_CD_TIME  : float = 0.1
const INV_TIME      := 0.55

var _jumps_left     := 2
var has_bazooka     := false
var bazooka_ammo    := 0
var _speed_boosted  := false  # true while bazooka active

@onready var sprite : AnimatedSprite2D = $Sprite2D
@onready var gun_point : Marker2D = $GunPoint

var bullet_scene := preload("res://scenes/Bullet.tscn")
var rocket_scene := preload("res://scenes/Rocket.tscn")

# ── Audio ─────────────────────────────────────────────────────────────────────
func _play_sfx(path: String) -> void:
	var sfx := get_node_or_null("SFXPlayer") as AudioStreamPlayer
	if not sfx: return
	var s := load(path) as AudioStream
	if s:
		sfx.stream = s
		sfx.play()

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		if _jumps_left < 2:
			_jumps_left = 2

	var dir := Input.get_axis("move_left", "move_right")
	var crouching := Input.is_key_pressed(KEY_CTRL)
	if crouching:
		sprite.play("crouch")
		velocity.x = dir * (SPEED_NORMAL * 0.4)
	else:
		pass
	var current_speed := SPEED_BOOSTED if _speed_boosted else SPEED_NORMAL
	if not crouching:
		velocity.x = dir * current_speed

	# Double jump
	_jump_cd -= delta
	if Input.is_action_just_pressed("jump") and _jumps_left > 0 and _jump_cd <= 0.0:
		velocity.y  = JUMP_FORCE
		_jumps_left -= 1
		_jump_cd     = JUMP_CD_TIME
		_play_sfx("res://audio/player_jump.wav")

	# Shoot — LEFT CLICK
	shoot_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shoot_timer <= 0.0:
		if has_bazooka and bazooka_ammo > 0:
			_spawn_rocket()
			bazooka_ammo -= 1
			_play_sfx("res://audio/rocket_fire.wav")
			if bazooka_ammo <= 0:
				_deactivate_bazooka()
			shoot_timer = 0.75
		else:
			_spawn_bullet()
			_play_sfx("res://audio/player_shoot.wav")
			shoot_timer = shoot_cd

	# Invincibility flicker
	if inv_timer > 0.0:
		inv_timer -= delta
		sprite.modulate.a = 0.4 if fmod(inv_timer, 0.12) > 0.06 else 1.0
	else:
		sprite.modulate.a = 1.0

	sprite.flip_h = get_global_mouse_position().x < global_position.x
	move_and_slide()
	
	# Animation
	if crouching:
		sprite.play("crouch")
	elif abs(velocity.x) > 10.0:
		sprite.play("walk")
	else:
		sprite.play("idle")

	var vw := get_viewport_rect().size.x
	global_position.x = clamp(global_position.x, 20.0, vw - 20.0)

func _spawn_bullet() -> void:
	var b := bullet_scene.instantiate()
	b.global_position = gun_point.global_position
	var d : Vector2 = (get_global_mouse_position() - gun_point.global_position).normalized()
	b.set_direction(d)
	b.damage = base_damage * gun_level
	get_tree().current_scene.add_child(b)

func _spawn_rocket() -> void:
	var b : Node = rocket_scene.instantiate()
	b.global_position = gun_point.global_position
	var d : Vector2 = (get_global_mouse_position() - gun_point.global_position).normalized()
	b.set_direction(d)
	get_tree().current_scene.add_child(b)

func _deactivate_bazooka() -> void:
	has_bazooka    = false
	_speed_boosted = false
	_play_sfx("res://audio/bazooka_empty.wav")

func take_damage(amount: int) -> void:
	if is_dead or inv_timer > 0.0:
		return
	current_health -= amount
	current_health  = max(0, current_health)
	inv_timer       = INV_TIME
	_play_sfx("res://audio/player_hurt.wav")
	health_changed.emit(current_health, MAX_HEALTH)
	if current_health == 0:
		_play_sfx("res://audio/player_die.mp3")
		is_dead = true
		player_died.emit()

func heal(amount: int) -> void:
	current_health = min(MAX_HEALTH, current_health + amount)
	_play_sfx("res://audio/pickup_heal.wav")
	health_changed.emit(current_health, MAX_HEALTH)

func upgrade_gun() -> void:
	gun_level   = min(gun_level + 1, 3)
	shoot_cd    = max(0.10, shoot_cd - 0.06)
	base_damage = int(base_damage * 1.50)
	_play_sfx("res://audio/pickup_upgrade.wav")

func pickup_bazooka() -> void:
	has_bazooka    = true
	bazooka_ammo   = 10        
	_speed_boosted = true       # instant speed boost when bazooka picked up
	_play_sfx("res://audio/pickup_bazooka.wav")
	
func boost_max_health(new_max: int) -> void:
	MAX_HEALTH     = new_max
	current_health = new_max
	health_changed.emit(current_health, MAX_HEALTH)
