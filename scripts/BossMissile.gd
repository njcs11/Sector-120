extends Area2D
var damage   := 30
var speed    := 180.0
var _timer   := 0.0
var dir      := Vector2.LEFT
var _player  : Node = null
var _homing  := true
func _ready() -> void:
	body_entered.connect(func(b):
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(damage)
			queue_free())
func init(player: Node) -> void:
	_player = player
func _physics_process(delta: float) -> void:
	_timer += delta
	if _homing and _timer < 2.0 and is_instance_valid(_player):
		var target : Vector2 = (_player.global_position - global_position).normalized()
		dir = dir.lerp(target, 3.5 * delta).normalized()
	else:
		_homing = false
	position += dir * speed * delta
	rotation  = dir.angle()
	if _timer >= 5.0:
		queue_free()
