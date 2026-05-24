extends Area2D
# Rocket.gd — bazooka projectile, deals AoE splash

var speed     : float = 500.0
var direction : Vector2 = Vector2.RIGHT
var damage    : int = 350
var _timer    : float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body)
	collision_mask = 0b11111111

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation  = dir.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_timer   += delta
	if _timer > 4.0:
		queue_free()

func _on_body(body: Node) -> void:
	if body.has_method("take_damage") and (body.is_in_group("enemies") or body.is_in_group("player") == false):
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 150.0:
				e.take_damage(damage)
		queue_free()
