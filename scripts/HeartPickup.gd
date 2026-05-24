extends Area2D

var _float_timer := 0.0
var _start_y     := 0.0
var heal_amount  := 250

func _ready() -> void:
	body_entered.connect(_on_body)
	_start_y = position.y

func _process(delta: float) -> void:
	_float_timer += delta
	position.y    = _start_y + sin(_float_timer * 3.0) * 5.0
	$Sprite2D.modulate = Color(1.0 + sin(_float_timer * 4.0) * 0.3, 0.3, 0.3)

func _on_body(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		var sfx := AudioStreamPlayer.new()
		sfx.stream = load("res://audio/pickup_heal.wav")
		get_tree().current_scene.add_child(sfx)
		sfx.play()
		sfx.queue_free()
		queue_free()
