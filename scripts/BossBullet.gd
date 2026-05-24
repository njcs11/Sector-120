extends Area2D
# BossBullet.gd — spiral, laser, missile, spread — collides with platforms
enum Type { SPIRAL, LASER, MISSILE, SPREAD }
var bullet_type     : int    = Type.SPIRAL
var speed           : float  = 260.0
var direction       : Vector2 = Vector2.LEFT
var damage          : int    = 70
var _age            : float  = 0.0
# Spiral vars
var _spiral_angle  : float = 0.0
var _spiral_speed  : float = 5.0
var _spiral_radius : float = 180.0
# Missile vars
var _target        : Node  = null
var _turn_speed    : float = 3.2
# Gravity (for non-laser/spiral types — makes bullets arc realistically)
const BULLET_GRAVITY := 320.0
var _velocity       : Vector2 = Vector2.ZERO
func _ready() -> void:
	# Layer 1 = world/platforms, Layer 4 = player
	collision_layer = 0
	collision_mask  = 0b0001_0001  # hits layer 1 (platforms) and layer 5 (player)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
func setup(t: int, dir: Vector2, dmg: int, target: Node = null) -> void:
	bullet_type = t
	direction   = dir.normalized()
	damage      = dmg
	_target     = target
	rotation    = dir.angle()
	match bullet_type:
		Type.LASER:
			speed     = 480.0
			_velocity = direction * speed
		Type.MISSILE:
			speed     = 320.0
			_velocity = direction * speed
		Type.SPIRAL:
			speed     = 340.0
			_velocity = direction * speed
		Type.SPREAD:
			speed     = 400.0
			_velocity = direction * speed
func _physics_process(delta: float) -> void:
	_age += delta
	if _age > 10.0:
		queue_free()
		return
	match bullet_type:
		Type.SPIRAL:
			_spiral_angle += _spiral_speed * delta
			var perp   := Vector2(-direction.y, direction.x)
			var offset := perp * sin(_spiral_angle) * _spiral_radius * delta
			position   += direction * speed * delta + offset
		Type.LASER:
			# Laser: fast, straight, no gravity — hard to dodge
			position += direction * speed * 2.0 * delta
		Type.MISSILE:
			# Homing — turns toward player with limited turn rate
			if is_instance_valid(_target):
				var to_target : Vector2 = (_target.global_position - global_position).normalized()
				direction = direction.lerp(to_target, _turn_speed * delta).normalized()
				rotation  = direction.angle()
			_velocity  = direction * speed * 1.3
			position  += _velocity * delta
		Type.SPREAD:
			# Slight gravity arc makes spread bullets less trivially jumpable
			_velocity.y += BULLET_GRAVITY * delta
			position    += _velocity * delta
			rotation     = _velocity.angle()
func _on_body(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		# Hit a platform — destroy
		queue_free()
func _on_area(area: Node) -> void:
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
