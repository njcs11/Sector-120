extends Area2D
var damage  := 12
var speed   := 220.0
var _angle  := 0.0
var _timer  := 0.0
var _base_dir := Vector2.LEFT

func _ready() -> void:
	body_entered.connect(func(b):
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(damage)
			queue_free())

func init(base_dir: Vector2, angle_offset: float) -> void:
	_base_dir = base_dir.normalized()
	_angle    = angle_offset

func _physics_process(delta: float) -> void:
	_timer += delta
	_angle += 3.0 * delta
	var spiral_dir := _base_dir.rotated(_angle * 0.8)
	position += spiral_dir * speed * delta
	rotation  = spiral_dir.angle()
	# Grow and fade
	var life_pct := _timer / 3.5
	scale   = Vector2(1.0 + life_pct, 1.0 + life_pct)
	modulate.a = 1.0 - life_pct
	if _timer >= 3.5:
		queue_free()
