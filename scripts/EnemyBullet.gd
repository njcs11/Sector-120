extends Area2D

var speed     : float   = 500.0
var damage    : int     = 20
var direction : Vector2 = Vector2.LEFT
var _age      : float   = 0.0

func _ready() -> void:
	monitoring  = false
	monitorable = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	monitoring  = true
	monitorable = true
	collision_layer = 0
	collision_mask  = 0b1111_1111
	body_entered.connect(_on_body)

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation  = direction.angle()

func _physics_process(delta: float) -> void:
	_age += delta
	if _age > 5.0:
		queue_free()
		return
	position += direction * speed * delta

func _on_body(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("enemies"):
		pass  # ignore — don't destroy on hitting other enemies
	else:
		if not body.is_in_group("enemies"):
			queue_free()
