extends Area2D

var _float_timer := 0.0
var _start_y     := 0.0

func _ready() -> void:
	body_entered.connect(_on_body)
	_start_y = position.y

func _process(delta: float) -> void:
	_float_timer += delta
	position.y    = _start_y + sin(_float_timer * 2.0) * 6.0
	$Sprite2D.rotation_degrees += 30.0 * delta

func _on_body(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("pickup_bazooka"):
		body.pickup_bazooka()
		var sfx := AudioStreamPlayer.new()
		sfx.stream = load("res://audio/pickup_bazooka.wav")
		get_tree().current_scene.add_child(sfx)
		sfx.play()
		sfx.queue_free()
		queue_free()
