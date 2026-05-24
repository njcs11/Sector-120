extends Area2D
var damage   := 8
var _timer   := 0.0
var lifetime := 3.5
var speed    := 600.0
var dir      := Vector2.LEFT

func _ready() -> void:
	body_entered.connect(func(b):
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(damage))

func set_direction(d: Vector2) -> void:
	dir      = d.normalized()
	rotation = d.angle()

func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	_timer   += delta
	# Pulsing scale for visual
	var s := 1.0 + sin(_timer * 20.0) * 0.3
	scale = Vector2(s, s)
	if _timer >= lifetime:
		queue_free()
