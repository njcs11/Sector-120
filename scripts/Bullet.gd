extends Area2D

var speed     : float   = 720.0
var direction : Vector2 = Vector2.RIGHT
var damage    : int     = 25
var _timer    : float   = 0.0

func _ready() -> void:
	monitoring  = false
	monitorable = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	monitoring  = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask  = 0b1111_1111

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation  = dir.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_timer   += delta
	if _timer >= 2.5:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("player"):
		pass  # ignore player — bullet came from player
	else:
		if not body.is_in_group("player"):
			queue_free()
